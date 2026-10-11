#!/usr/bin/env bash
# Emergency kit launcher for Linux and macOS.   Run:  bash /path/to/USB/start.sh
# Binaries are unpacked to a private folder in your home on first use (the USB filesystem can't keep exec bits/symlinks).
# Not /tmp: a fixed /tmp path can be pre-created by another user with a fake llama-cli in it.
USB="$(cd "$(dirname "$0")" && pwd)"
RUN="${XDG_CACHE_HOME:-$HOME/.cache}/emergency-kit"
mkdir -p "$RUN" && chmod 700 "$RUN"
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) PLAT=mac-arm64 ;;
  Darwin-x86_64) PLAT=mac-x64 ;;
  Linux-x86_64) PLAT=linux-x64 ;;
  *) echo "Unsupported system: $(uname -sm)"; exit 1 ;;
esac
OPEN=xdg-open; [ "${PLAT%%-*}" = mac ] && OPEN=open
VAULT_IMG="$USB/vault/vault.hc"
# Where the decrypted vault is mounted (Linux: by option 5; macOS: by the VeraCrypt app)
if [ -z "$VAULT_DIR" ]; then
  VAULT_DIR="$RUN/vault"
  if [ "${PLAT%%-*}" = mac ]; then n=$(ls -d /Volumes/*/notes 2>/dev/null | head -1); [ -n "$n" ] && VAULT_DIR=$(dirname "$n"); fi
fi

bindir() {  # $1=llama|kiwix $2=archive name $3=binary -> dir holding the binary
  local d="$RUN/$1-$2" f
  f=$(find "$d" -type f -name "$3" 2>/dev/null | head -1)
  if [ -z "$f" ]; then  # first run, or the unpack was interrupted or cleaned up - unpack again
    rm -rf "$d"; mkdir -p "$d" && tar -xzf "$USB/bin/$1/$2.tar.gz" -C "$d" || { rm -rf "$d"; return 1; }
    f=$(find "$d" -type f -name "$3" | head -1)
  fi
  dirname "$f"
}

llama() {  # Linux: Vulkan build pinned to a discrete GPU if present (iGPUs/splits were slower than CPU)
  LLAMA=$(bindir llama "$PLAT" llama-server); NGL=""
  case "$PLAT" in
    mac-*) NGL="-ngl 99" ;;  # Metal on Apple Silicon; harmless on Intel Macs
    linux-x64)
      local v dev; v=$(bindir llama linux-vulkan llama-server 2>/dev/null)
      [ -n "$v" ] && dev=$("$v/llama-server" --list-devices 2>/dev/null | grep -E 'Vulkan[0-9]+:.*(NVIDIA|Radeon RX|Arc)' | head -1 | grep -oE 'Vulkan[0-9]+')
      if [ -n "$dev" ]; then LLAMA=$v; NGL="-ngl 99 -dev $dev"; echo "Using the graphics card ($dev)."; fi ;;
  esac
}

wait_http() {  # $1=url  - wait up to 3 min for a local server
  for _ in $(seq 180); do curl -s -o /dev/null "$1" && return 0; sleep 1; done; return 1
}

chat() {  # $1=model file
  llama
  echo "Starting the model (first load can take a minute)... Close with Ctrl+C."
  "$LLAMA/llama-server" -m "$USB/models/$1" -c 8192 $NGL --host 127.0.0.1 --port 8080 &
  local pid=$!
  if wait_http http://127.0.0.1:8080/health; then $OPEN http://127.0.0.1:8080 >/dev/null 2>&1 || echo "Open http://127.0.0.1:8080 in a browser."; fi
  wait $pid
}

ask() {  # option 3: per question, search the vault's text files + every .zim, then answer once with sources
  local k kpid="" vault="" ctx="$RUN/context.txt" q src
  if ls "$USB"/library/*.zim >/dev/null 2>&1 && k=$(bindir kiwix "$PLAT" kiwix-serve); then
    "$k/kiwix-serve" --address 127.0.0.1 --port 8081 "$USB"/library/*.zim >/dev/null 2>&1 &
    kpid=$!; wait_http http://127.0.0.1:8081 || { kill "$kpid"; kpid=""; }
  fi
  if [ -n "$(ls -A "$VAULT_DIR" 2>/dev/null)" ]; then vault=$VAULT_DIR; ctx="$VAULT_DIR/.llm-context.txt"; fi  # notes never leave the vault
  llama
  echo "Ask a question. Uses: ${vault:+your vault notes + }${kpid:+encyclopedias}"
  [ -z "$vault" ] && echo "(Vault not open - choose 5 first to include your notes.)"
  echo "Press Enter on an empty line to go back to the menu."
  while read -rp $'\nQuestion: ' q && [ -n "$q" ]; do
    src=$(perl "$USB/bin/ask-context.pl" "$vault" "${kpid:+http://127.0.0.1:8081}" "$ctx" "$q")
    "$LLAMA/llama-cli" -m "$USB/models/Qwen3-4B-Q4_K_M.gguf" -c 16384 $NGL -sysf "$ctx" -p "$q" \
      -st --reasoning off --no-display-prompt --simple-io --no-warmup -lv 0 2>/dev/null \
      | sed -n '/^> /,$p' | sed '1d;/^Exiting\.\.\.$/d'  # hide the banner
    echo; echo "Sources looked up:"; echo "${src:-  - none (general knowledge only)}"
    [ -n "$kpid" ] && echo "  Check the article in option 4 before acting on medical advice."
  done
  rm -f "$ctx"; [ -n "$kpid" ] && kill "$kpid"
}

wiki() {
  local k; k=$(bindir kiwix "$PLAT" kiwix-serve) || { echo "kiwix missing"; return; }
  echo "Encyclopedias at http://127.0.0.1:8081 - close with Ctrl+C."
  "$k/kiwix-serve" --address 127.0.0.1 --port 8081 "$USB"/library/*.zim &
  local pid=$!
  wait_http http://127.0.0.1:8081 && $OPEN http://127.0.0.1:8081 >/dev/null 2>&1
  wait $pid
}

vault() {
  [ -f "$VAULT_IMG" ] || { echo "No vault yet. Create it on Windows with MAKE-VAULT-Windows.bat (see README)."; return; }
  if [ "${PLAT%%-*}" = mac ]; then
    echo "macOS: install VeraCrypt + FUSE-T from the disk image that opens now, then mount $VAULT_IMG."
    $OPEN "$USB"/vault/veracrypt/VeraCrypt_FUSE-T_*.dmg; return
  fi
  if mountpoint -q "$VAULT_DIR" 2>/dev/null; then
    sudo umount "$VAULT_DIR" && sudo cryptsetup close ekvault && echo "Vault closed."; return
  fi
  # cryptsetup opens VeraCrypt containers natively (present on Ubuntu live, Tails, SystemRescue)
  sudo cryptsetup open --type tcrypt --veracrypt "$VAULT_IMG" ekvault || return
  mkdir -p "$VAULT_DIR" && sudo mount -o uid="$(id -u)",gid="$(id -g)" /dev/mapper/ekvault "$VAULT_DIR" \
    && echo "Vault open at $VAULT_DIR  (choose 5 again to close it)." && $OPEN "$VAULT_DIR" >/dev/null 2>&1
}

[ -n "$1" ] && { "$@"; exit; }  # e.g.  bash start.sh chat qwen2.5-1.5b-instruct-q4_k_m.gguf
while :; do
  cat <<'MENU'

  ===== EMERGENCY KIT =====
  1) Chat - Qwen3 4B        (best answers, needs ~6 GB free RAM)
  2) Chat - Qwen2.5 1.5B    (fast, for old or weak computers)
  3) Ask a question         (uses the encyclopedias + your notes if the vault is open)
  4) Encyclopedias          (offline WikiMed and any .zim in library, with images)
  5) Open / close the encrypted vault
  q) Quit
MENU
  read -rp "  Choose: " c
  case "$c" in
    1) chat Qwen3-4B-Q4_K_M.gguf ;;
    2) chat qwen2.5-1.5b-instruct-q4_k_m.gguf ;;
    3) ask ;;
    4) wiki ;;
    5) vault ;;
    q|Q) exit 0 ;;
  esac
done
