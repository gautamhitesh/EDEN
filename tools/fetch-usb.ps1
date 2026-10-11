# Downloads everything for the USB. Resumable; verifies sha256 where known.
# Usage: powershell -File fetch-usb.ps1 -Ventoy <Ventoy partition, e.g. E:> -Kit <LLM partition, e.g. F:>
param([Parameter(Mandatory)][string]$Ventoy, [Parameter(Mandatory)][string]$Kit)
$Ventoy = $Ventoy.TrimEnd('\', ':') + ':'; $Kit = $Kit.TrimEnd('\', ':') + ':'
$ErrorActionPreference = 'Continue'
$llama = 'https://github.com/ggml-org/llama.cpp/releases/download/b11392'
$kiwix = 'https://download.kiwix.org/release/kiwix-tools'
$vc = 'https://github.com/veracrypt/VeraCrypt/releases/download/VeraCrypt_1.26.29'
$items = @(
  @("$Ventoy\tails-amd64-7.14.iso", 'https://download.tails.net/tails/stable/tails-amd64-7.14/tails-amd64-7.14.iso', 'a49ab6a82d03449f3f77b0c5cfe9a8b19d9eaf10b2177f35ffaca4a13bfdec54'),
  @("$Ventoy\systemrescue-13.02-amd64.iso", 'https://fastly-cdn.system-rescue.org/releases/13.02/systemrescue-13.02-amd64.iso', 'ad4d670b72859d887c7960142a9a9d36a3e50446694a035e254442f65d6e7572'),
  @("$Kit\models\Qwen3-4B-Q4_K_M.gguf", 'https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf', '7485fe6f11af29433bc51cab58009521f205840f5b4ae3a32fa7f92e8534fdf5'),
  @("$Kit\models\qwen2.5-1.5b-instruct-q4_k_m.gguf", 'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf', '6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e'),
  @("$Kit\library\wikipedia_en_medicine_maxi_2026-04.zim", 'https://download.kiwix.org/zim/wikipedia/wikipedia_en_medicine_maxi_2026-04.zim', '6f67340a7cd7665bb57c27d2bbff97e26f2037477c9ea597345a118286820331'),
  @("$Kit\bin\_zip\llama-win-cpu.zip", "$llama/llama-b11392-bin-win-cpu-x64.zip", ''),
  @("$Kit\bin\_zip\llama-win-vulkan.zip", "$llama/llama-b11392-bin-win-vulkan-x64.zip", ''),
  @("$Kit\bin\llama\linux-x64.tar.gz", "$llama/llama-b11392-bin-ubuntu-x64.tar.gz", ''),
  @("$Kit\bin\llama\linux-vulkan.tar.gz", "$llama/llama-b11392-bin-ubuntu-vulkan-x64.tar.gz", ''),
  @("$Kit\bin\llama\mac-arm64.tar.gz", "$llama/llama-b11392-bin-macos-arm64.tar.gz", ''),
  @("$Kit\bin\llama\mac-x64.tar.gz", "$llama/llama-b11392-bin-macos-x64.tar.gz", ''),
  @("$Kit\bin\_zip\kiwix-win.zip", "$kiwix/kiwix-tools_win-x86_64-3.8.1.zip", ''),
  @("$Kit\bin\kiwix\linux-x64.tar.gz", "$kiwix/kiwix-tools_linux-x86_64-3.8.1.tar.gz", ''),
  @("$Kit\bin\kiwix\mac-arm64.tar.gz", "$kiwix/kiwix-tools_macos-arm64-3.8.1.tar.gz", ''),
  @("$Kit\bin\kiwix\mac-x64.tar.gz", "$kiwix/kiwix-tools_macos-x86_64-3.8.1.tar.gz", ''),
  @("$Kit\vault\veracrypt\VeraCrypt.Portable.1.26.29.exe", "$vc/VeraCrypt.Portable.1.26.29.exe", ''),
  @("$Kit\vault\veracrypt\veracrypt-console-1.26.29-Ubuntu-24.04-amd64.deb", "$vc/veracrypt-console-1.26.29-Ubuntu-24.04-amd64.deb", ''),
  @("$Kit\vault\veracrypt\VeraCrypt_FUSE-T_1.26.29.dmg", "$vc/VeraCrypt_FUSE-T_1.26.29.dmg", '')
)
foreach ($i in $items) {
  New-Item -ItemType Directory -Force (Split-Path $i[0]) | Out-Null
  "$(Get-Date -f s) get $($i[0])"
  curl.exe -sS -L --fail --retry 5 -C - -o $i[0] $i[1]
  if ($LASTEXITCODE -ne 0) { "$(Get-Date -f s) FAIL curl=$LASTEXITCODE $($i[0])"; continue }
  if ($i[2]) {
    $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $i[0]).Hash.ToLower()
    if ($h -eq $i[2]) { "  sha256 ok" } else { "  SHA256 MISMATCH $h"; Remove-Item -LiteralPath $i[0] }
  }
}
# Windows binaries unpacked in place; Linux/mac stay as tarballs (launchers extract them to a private per-user folder to keep exec bits + symlinks)
foreach ($z in @(@('llama-win-cpu','llama\win-cpu'), @('llama-win-vulkan','llama\win-vulkan'), @('kiwix-win','kiwix\win'))) {
  $dst = "$Kit\bin\$($z[1])"; New-Item -ItemType Directory -Force $dst | Out-Null
  tar.exe -xf "$Kit\bin\_zip\$($z[0]).zip" -C $dst
  "$(Get-Date -f s) unpacked $dst exit=$LASTEXITCODE"
}
Remove-Item -Recurse -Force "$Kit\bin\_zip"
"$(Get-Date -f s) ALL DONE"
