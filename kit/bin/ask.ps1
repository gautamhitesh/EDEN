# Option 3: answer questions from the vault's text files and every encyclopedia (.zim) in library\, naming sources.
# Test without the menu:  powershell -File ask.ps1 -Vault V:\ -Llama <llama dir> -Model <gguf> -Question "how to treat a burn"
param([string]$Vault, [string]$Llama, [string]$Model, [string]$Ngl, [string]$Question, [string]$Kiwix = 'http://127.0.0.1:8081')
$Vault = $Vault.Trim('"').TrimEnd('.')  # cmd passes "V:\" as V:\" (backslash escapes the quote)
$stop = 'the and for with what how who why when where which does did can should would could are was were has had have this that these those from into about there their them they will not but all any some you your our'.Split(' ')
$budgetVault = 12000; $budgetArticle = 5000  # chars; ~8k tokens total keeps a 16k context and a CPU usable

function Get-Url([string]$u) {  # UTF-8 body (PowerShell 5 guesses Latin-1 for kiwix pages)
  [Text.Encoding]::UTF8.GetString((Invoke-WebRequest $u -UseBasicParsing -TimeoutSec 20).RawContentStream.ToArray())
}
function Get-Text([string]$html) {  # article HTML -> plain text, references dropped
  $h = $html -replace '(?s)<(script|style)[^>]*>.*?</\1>', ' ' -replace '(?i)<br\s*/?>|</(p|li|h\d|tr|div|table)>', "`n" -replace '<[^>]+>', ''
  $t = [Net.WebUtility]::HtmlDecode($h) -replace '[ \t]+', ' ' -replace '\[\d+\]', ''
  ($t -split '(?m)^\s*References\s*$')[0]
}
function Split-Chunks([string]$text) {  # paragraphs merged into ~700-char pieces
  $out = @(); $cur = ''
  foreach ($p in ($text -split '\r?\n')) {
    $p = $p.Trim(); if (-not $p) { continue }
    if ($cur -and $cur.Length + $p.Length -gt 700) { $out += $cur; $cur = '' }
    $cur = "$cur`n$p".Trim()
  }
  if ($cur) { $out += $cur }
  , $out
}
function Select-Chunks($chunks, $words, [int]$budget, [switch]$KeepFirst) {  # best keyword matches, in original order
  $scored = for ($i = 0; $i -lt $chunks.Count; $i++) {
    $c = $chunks[$i].ToLower()
    [pscustomobject]@{ i = $i; s = @($words | Where-Object { $c.Contains($_) }).Count + $(if ($KeepFirst -and $i -eq 0) { 99 } else { 0 }) }
  }
  $take = @(); $n = 0
  foreach ($x in ($scored | Where-Object s -gt 0 | Sort-Object s -Descending)) {
    if ($n + $chunks[$x.i].Length -gt $budget) { continue }
    $take += $x.i; $n += $chunks[$x.i].Length
  }
  ($take | Sort-Object | ForEach-Object { $chunks[$_] }) -join "`n...`n"
}

$vaultOpen = $Vault -and (Test-Path $Vault)
$ctxFile = if ($vaultOpen) { Join-Path $Vault '.llm-context.txt' } else { Join-Path $env:TEMP 'ek-context.txt' }  # notes never leave the vault
$kiwixUp = $false
for ($i = 0; $i -lt 30 -and -not $kiwixUp; $i++) { try { Get-Url $Kiwix | Out-Null; $kiwixUp = $true } catch { Start-Sleep 1 } }

function Ask([string]$q) {
  $words = @($q.ToLower() -split '[^a-z0-9]+' | Where-Object { $_.Length -ge 3 -and $stop -notcontains $_ } | Select-Object -Unique)
  $parts = @(); $src = @()
  if ($vaultOpen) {
    $docs = @(Get-ChildItem $Vault -Recurse -File -Include *.txt, *.md -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -ne '.llm-context.txt' -and $_.FullName -notmatch 'System Volume Information|\$RECYCLE\.BIN' })
    $chunks = @(foreach ($d in $docs) { foreach ($c in (Split-Chunks (Get-Content -Raw -LiteralPath $d.FullName))) { "[$($d.Name)] $c" } })
    $all = $chunks -join "`n"
    $picked = if ($all.Length -le $budgetVault) { $all } else { Select-Chunks $chunks $words $budgetVault }
    if ($picked) { $parts += "=== YOUR NOTES (from the vault) ===`n$picked"; $src += ($docs | Where-Object { $picked.Contains("[$($_.Name)]") } | ForEach-Object { "Vault: $($_.Name)" }) }
  }
  if ($kiwixUp -and $words) {
    try {
      $xml = [xml](Get-Url "$Kiwix/search?pattern=$([uri]::EscapeDataString($words -join ' '))&format=xml&pageLength=2")
      foreach ($it in @($xml.rss.channel.item)) {
        if (-not $it) { continue }
        $text = Select-Chunks (Split-Chunks (Get-Text (Get-Url "$Kiwix$($it.link)"))) $words $budgetArticle -KeepFirst
        $parts += "=== ENCYCLOPEDIA ARTICLE: $($it.title) ===`n$text"
        $src += "$($it.book.title): $($it.title)"
      }
    } catch { Write-Host "(encyclopedia search failed: $($_.Exception.Message))" }
  }
  $sys = @"
You are a calm, practical assistant, possibly helping in an emergency. Answer using the SOURCES below.
After each point, name its source in brackets: the exact article title or file name shown below. If the sources do not cover
the question, say so plainly, then give general knowledge marked "(not from your sources)".
For medical questions: give clear practical steps and say when to get professional help. Be concise.
=== SOURCES ===
$(if ($parts) { $parts -join "`n`n" } else { '(none found)' })
"@
  [IO.File]::WriteAllText($ctxFile, $sys)
  & (Join-Path $Llama 'llama-cli.exe') -m $Model -c 16384 @($Ngl -split ' ' | Where-Object { $_ }) -sysf $ctxFile -p $q `
    -st --reasoning off --no-display-prompt --simple-io --no-warmup -lv 0 2>$null |
    ForEach-Object -Begin { $on = $false } -Process { if ($on -and $_ -ne 'Exiting...') { $_ } elseif ($_ -like '> *') { $on = $true } }  # hide banner
  Write-Host "`nSources looked up:"; if ($src) { $src | ForEach-Object { Write-Host "  - $_" } } else { Write-Host "  - none (general knowledge only)" }
  if ($kiwixUp) { Write-Host "  Check the article in option 4 before acting on medical advice." }
}

try {
  if ($Question) { Ask $Question; return }
  Write-Host "`nAsk a question. Uses: $(if ($vaultOpen) { 'your vault notes' } else { 'no vault (open it with 5 to include your notes)' })$(if ($kiwixUp) { ' + encyclopedias' })."
  Write-Host 'Press Enter on an empty line to go back to the menu.'
  while ($true) { $q = Read-Host "`nQuestion"; if (-not $q.Trim()) { break }; Ask $q }
} finally { Remove-Item $ctxFile -ErrorAction SilentlyContinue }
