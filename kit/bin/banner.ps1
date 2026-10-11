# EDEN insignia for START-Windows.bat. Animated once at startup; -Static redraws it above the menu.
param([switch]$Static)
$vt = $Host.UI.SupportsVirtualTerminal  # old consoles: plain text instead of escape-code garbage
$e = [char]27
function C($code) { if ($vt) { "$e[${code}m" } else { '' } }
function Wait($ms) { if (-not $Static) { Start-Sleep -Milliseconds $ms } }
$amber = C '38;5;214'; $white = C '97'; $dim = C '38;5;244'; $ok = C '38;5;46'; $reset = C '0'
$green = 22, 28, 34, 40, 46, 82 | ForEach-Object { C "38;5;$_" }
# { } mark the USB stem inside the power ring
$icon = '  ▄▀ {▐▌} ▀▄  ', ' █   {▐▌}   █ ', '█    {▀▀}    █', '█          █', ' ▀▄      ▄▀ ', '   ▀▀▀▀▀▀   '
$text = '███████╗██████╗ ███████╗███╗   ██╗',
        '██╔════╝██╔══██╗██╔════╝████╗  ██║',
        '█████╗  ██║  ██║█████╗  ██╔██╗ ██║',
        '██╔══╝  ██║  ██║██╔══╝  ██║╚██╗██║',
        '███████╗██████╔╝███████╗██║ ╚████║',
        '╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═══╝'

Write-Host ''
for ($i = 0; $i -lt 6; $i++) {
  $ic = $amber + $icon[$i].Replace('{', $white).Replace('}', $amber)
  Write-Host "  $ic  $($green[$i])$($text[$i])$reset"
  Wait 70
}
$tag = 'E.D.E.N.  Emergency Drive for Everything Needed'
Write-Host -NoNewline "  $dim"
if ($Static) { Write-Host -NoNewline $tag } else { foreach ($ch in $tag.ToCharArray()) { Write-Host -NoNewline $ch; Start-Sleep -Milliseconds 12 } }
Write-Host $reset
Write-Host -NoNewline '  '
foreach ($s in 'offline', 'encrypted', 'ready') { Wait 160; Write-Host -NoNewline "$dim[$ok $s $dim]$reset " }
Write-Host ''
Wait 250
