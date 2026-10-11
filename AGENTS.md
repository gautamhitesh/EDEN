# AGENTS.md: building an EDEN drive with a coding agent

You are a coding agent (Claude Code, Codex, Cursor, Aider…) asked to build an EDEN USB drive.
[`BUILD.md`](BUILD.md) is the human guide and the source of truth. This file is the same procedure as
commands, plus the rules you must follow. Do the steps in order and verify each one before moving on.

## Hard rules

1. **Erasing a disk needs a human yes.** Before step 2, show the human the candidate disk's number,
   model and size, and wait for them to confirm that exact disk number. Never pick a disk yourself,
   never use one that isn't USB, and never use a disk that holds the running OS.
2. **The vault password is human-only.** Step 6 is done by the human. Don't ask for the password,
   type it, store it, log it, or script VeraCrypt's `/create` or `/password` options.
3. **Don't change pinned versions, URLs or SHA-256 values** in `tools/fetch-usb.ps1` without asking.
   A `SHA256 MISMATCH` means re-download, never "update the hash".
4. **Don't rename model files** (`Qwen3-4B-Q4_K_M.gguf`, `qwen2.5-1.5b-instruct-q4_k_m.gguf`). The
   launchers use these exact names.
5. **Never pipe input into `START-Windows.bat`.** Its menu loops forever at end of input. Test with
   the headless commands in step 7 instead.
6. **Keep the drive labels** `EDEN-1-BOOT`, `EDEN-2-KIT` (and `EDEN-3-SPARE` if made) and never touch
   `VTOYEFI`. Each EDEN drive carries an `EDEN-ID.txt`; read it before writing anything to a drive.
7. Ventoy and partitioning need an **elevated (Administrator / root) shell**. If yours isn't, stop and
   ask the human to start one. Don't try to bypass UAC or sudo.

## Inputs to get from the human

| Input | Example | Used in |
|---|---|---|
| Target disk number (after rule 1) | `2` | steps 2–3 |
| Stick size | 16 / 32 / 64 GB | reserve size, which ISOs fit |
| Optional ISOs wanted | Ubuntu, Windows | step 5 |

Reserve sizes for the kit partition (`/R:` / `-r`, in MB): **16 GB → 11264**, **32 GB → 13312**,
**64 GB → 40960**. The kit partition needs at least 10.5 GB, and the Ventoy partition needs room
for the ISOs: 3 GB for Tails + SystemRescue, 15 GB with Ubuntu and Windows too.

## Build machine: Windows 10/11 (supported path)

### Step 1: Identify the disk (read-only)
```powershell
Get-Disk | Where-Object BusType -eq 'USB' | Format-Table Number, FriendlyName, @{n='GB';e={[math]::Round($_.Size/1GB,1)}}, PartitionStyle
```
Show this table to the human and get the disk number confirmed (rule 1).

### Step 2: Install Ventoy (DESTRUCTIVE, erases the disk)
Download the latest `ventoy-*-windows.zip` from https://github.com/ventoy/Ventoy/releases, check it
against the `sha256.txt` published with the release, and unzip it. Then, from the unzipped folder:
```powershell
.\Ventoy2Disk.exe VTOYCLI /I /PhyDrive:<N> /R:<reserve MB>
```
Secure Boot support is on by default (don't pass `/NOSB`). Default MBR partitioning keeps old BIOS PCs
working. The command returns before it finishes. Wait until `cli_done.txt` exists in the Ventoy
folder: `0` means success, `1` means failure (details in `cli_log.txt`).

Verify: `Get-Partition -DiskNumber <N>` shows the large **Ventoy** partition and the small **VTOYEFI** one.
Then label the boot partition and mark it:
```powershell
Set-Volume -FileSystemLabel Ventoy -NewFileSystemLabel EDEN-1-BOOT
$V = (Get-Volume -FileSystemLabel EDEN-1-BOOT).DriveLetter + ':'
Copy-Item boot\EDEN-ID.txt "$V\"
```

### Step 3: Create the kit partition
```powershell
New-Partition -DiskNumber <N> -UseMaximumSize -AssignDriveLetter |
  Format-Volume -FileSystem NTFS -NewFileSystemLabel EDEN-2-KIT -Confirm:$false
```
NTFS is required (model files are over 4 GB). Record the two drive letters:
```powershell
Get-Volume | Where-Object FileSystemLabel -in 'EDEN-1-BOOT','EDEN-2-KIT' | Format-Table DriveLetter, FileSystemLabel, FileSystem, @{n='GB';e={[math]::Round($_.Size/1GB,1)}}
```
The rest of this file calls them `$V` (EDEN-1-BOOT) and `$K` (EDEN-2-KIT), for example `$V='E:'; $K='F:'`.

### Step 4: Copy the kit
From the repository root:
```powershell
Copy-Item -Path kit\* -Destination "$K\" -Recurse -Force
```
Verify: `$K\START-Windows.bat`, `$K\start.sh`, `$K\bin\ask.ps1` and `$K\EDEN-ID.txt` exist.

### Step 5: Download everything
```powershell
powershell -ExecutionPolicy Bypass -File tools\fetch-usb.ps1 -Ventoy $V -Kit $K
```
This is about 10 GB and takes a while; run it in the background and watch its output. Success:
every large file prints `sha256 ok`, there's no `FAIL` line, and it ends with `ALL DONE`. On `FAIL`
or `SHA256 MISMATCH`, re-run the same command; it resumes. If the WikiMed URL gives a 404, a newer
edition has replaced it: tell the human and download the newest `wikipedia_en_medicine_maxi_*.zim`
from https://download.kiwix.org/zim/wikipedia/ into `$K\library\` (rule 3: don't edit the script's hash).

Not in the script, so do these too:
- **FUSE-T** for Macs: the latest `fuse-t-macos-installer-*.pkg` from
  https://github.com/macos-fuse-t/fuse-t/releases → `$K\vault\veracrypt\`.
- **Optional ISOs** the human asked for, copied unchanged to `$V\`: Ubuntu 24.04 desktop from
  https://releases.ubuntu.com/24.04/ (check it against `SHA256SUMS` in the same folder), and Windows from
  https://www.microsoft.com/software-download/windows11 (that page needs a browser, so ask the human).

### Step 6: Vault (HUMAN ONLY, rule 2)
Tell the human: *"Run `START-Windows.bat` on the EDEN-2-KIT drive, choose 5, answer y, and follow the 3 prompts.
Choose a long passphrase you'll remember and don't write it on the stick."* Wait until they say it's
done, then check (without opening it) that `$K\vault\vault.hc` exists and
`$K\vault\veracrypt\windows\VeraCrypt-x64.exe` exists.

### Step 7: Verify (headless)
```powershell
# layout
'models\Qwen3-4B-Q4_K_M.gguf','models\qwen2.5-1.5b-instruct-q4_k_m.gguf','bin\llama\win-cpu\llama-cli.exe',
'bin\llama\win-vulkan\llama-cli.exe','bin\kiwix\win\kiwix-serve.exe','bin\llama\linux-x64.tar.gz',
'bin\llama\mac-arm64.tar.gz','bin\kiwix\linux-x64.tar.gz','vault\veracrypt\VeraCrypt.Portable.1.26.29.exe' |
  ForEach-Object { '{0,-5} {1}' -f (Test-Path "$K\$_"), $_ }
Get-ChildItem "$K\library\*.zim" | Select-Object Name, @{n='GB';e={[math]::Round($_.Length/1GB,2)}}

# end-to-end: encyclopedia search + model answer with sources (CPU build: about 1 minute)
$zims = (Get-ChildItem "$K\library\*.zim").FullName
$kw = Start-Process "$K\bin\kiwix\win\kiwix-serve.exe" -ArgumentList (@('--address','127.0.0.1','--port','8081') + $zims) -PassThru -WindowStyle Hidden
powershell -ExecutionPolicy Bypass -File "$K\bin\ask.ps1" -Llama "$K\bin\llama\win-cpu" -Model "$K\models\Qwen3-4B-Q4_K_M.gguf" -Question "how do I treat a burn"
Stop-Process -Id $kw.Id
```
Pass: every layout line says `True`. The answer gives practical burn steps, and `Sources looked up:`
lists at least one encyclopedia article (for example `Burn`).

Then hand the human the manual checklist in [`BUILD.md` → Step 6](BUILD.md#step-6-test-it)
(browser chat, opening the vault, the boot test). Those need a person at the machine.

## Build machine: Linux (alternative)

The same steps work with these commands. The vault (step 6) still needs a Windows PC, or the human
can create it with VeraCrypt's Linux GUI.

```bash
lsblk -d -o NAME,MODEL,SIZE,TRAN | awk 'NR==1 || /usb/'          # step 1: confirm /dev/sdX with the human
sudo sh Ventoy2Disk.sh -i -s -L EDEN-1-BOOT -r <reserve MB> /dev/sdX   # step 2: -s = Secure Boot (OFF by default on Linux)
sudo parted /dev/sdX unit MiB print free                          # step 3: find where the free space starts
sudo parted -s /dev/sdX mkpart primary ntfs <start>MiB 100%
sudo mkfs.ntfs -f -L EDEN-2-KIT /dev/sdX3
# then copy boot/EDEN-ID.txt to the EDEN-1-BOOT partition
```
For step 5 there's no PowerShell, so download by hand using the table in
[`BUILD.md` → Step 4](BUILD.md#step-4-download-the-models-encyclopedia-and-tools). Check each file with
`sha256sum` against the hashes in `tools/fetch-usb.ps1`, and unpack the Windows zips to the folders listed
there. Verify with `bash start.sh ask` from the EDEN-2-KIT drive, typing one question and then an empty line.

## Done means

- [ ] EDEN-1-BOOT and EDEN-2-KIT partitions exist on the confirmed disk, each with its EDEN-ID.txt, and no other disk was touched
- [ ] `fetch-usb.ps1` finished with `ALL DONE`, and every SHA-256 check said `sha256 ok`
- [ ] FUSE-T pkg is in `vault\veracrypt\`
- [ ] The human created the vault (`vault\vault.hc` exists)
- [ ] The step 7 layout check is all `True`, and the burn question was answered with sources
- [ ] The human has the manual checklist from BUILD.md step 6
