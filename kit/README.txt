EMERGENCY KIT - READ ME FIRST
==============================
This USB works without internet. It has two jobs:
  A) Boot a computer into another operating system (Ventoy menu).
  B) Run offline AI chat, an offline medical encyclopedia and an encrypted vault
     of personal notes on any Windows, Linux or Mac computer.

In a real emergency, call for help first: 112 (India / EU), 911 (US/Canada).
The AI can be wrong. For medical questions, cross-check with the encyclopedia (option 4).


DRIVES YOU WILL SEE
-------------------
  Ventoy   bootable operating systems (.iso files) - do not rename them
  LLM      this kit: launchers, AI models, encyclopedia, encrypted vault
  Linux    spare space (10 GB) - use for backups if you like
  VTOYEFI  Ventoy's boot files - never touch


A) BOOT ANOTHER OPERATING SYSTEM
--------------------------------
1. Plug in the USB, switch the computer on and press the boot-menu key repeatedly:
     Dell/Lenovo F12 | HP F9 | MSI F11 | Asus F8 or Esc | Acer F12 | Intel Mac: hold Option
   (Apple Silicon Macs (M1-M5) cannot boot these - use part B in macOS instead.)
2. Pick the USB (often "SanDisk" or "UEFI: SanDisk"). The Ventoy menu appears.
3. Choose:
     ubuntu-24.04 ........ normal Linux desktop. Pick "Try Ubuntu" - nothing gets installed.
     tails-amd64 ......... private/anonymous OS, forgets everything at shutdown.
                           Opens the vault: Applications > Utilities > Unlock VeraCrypt Volumes.
     systemrescue ........ repair disks, recover files, fix a computer that won't boot.
     Win10 ............... install or repair Windows 10.
   "Secure Boot" error? Easiest: switch Secure Boot off in the BIOS/UEFI settings and retry.


B) THE EMERGENCY KIT (AI, ENCYCLOPEDIA, VAULT)
----------------------------------------------
Open the "LLM" drive, then:
  Windows .... double-click START-Windows.bat
  Linux ...... right-click in the drive > Open in Terminal > type:  bash start.sh
               (works inside Ubuntu/Tails booted from this USB too)
  Mac ........ double-click start-mac.command
               (if blocked: open Terminal and type  bash /Volumes/LLM/start.sh )
               Note: Macs can read this drive but not write to it - that's fine.

Menu:
  1 Chat - Qwen3 4B ....... best answers. Needs ~6 GB free RAM. Shows its "thinking" first.
  2 Chat - Qwen2.5 1.5B ... for old/slow computers (4 GB RAM). Weaker but quick.
  3 Ask a question ........ the AI looks up the encyclopedias (and your vault, if open)
                            for each question and answers, listing the sources it used.
                            For medical answers, check the listed article in option 4.
  4 Encyclopedias ......... Wikipedia's medical articles (and any other .zim) with pictures.
  5 Open/close the vault .. your encrypted personal files.
Chat opens in your web browser (address 127.0.0.1:8080). It is all local - nothing goes online.
On computers without a graphics card, expect a few words per second. That's normal.


THE ENCRYPTED VAULT
-------------------
vault\vault.hc is a 4 GB VeraCrypt container (AES, SHA-512). Without the password it's random noise.

First time only (on Windows): double-click MAKE-VAULT-Windows.bat and choose the password.
  - Use a long passphrase you can remember (e.g. 5-6 random words). Do NOT write it on this drive.
  - If you forget it, nobody can recover the data. That is the point.

What to put in it:  plain text files (.txt or .md), anywhere in the vault. Option 3 searches them;
                    PDFs/Word files must be saved as text first.
  Ideas: emergency contacts, blood group/allergies/medicines, doctor details, insurance and
  policy numbers, ID/passport numbers, bank and account RECOVERY info (where things are, who to
  call), family meeting points, vehicle details. Scans of documents (PDF/JPG) can go elsewhere in
  the vault - the AI won't read them but you'll have them.
  Avoid storing raw passwords here; store hints/locations instead.

Opening it:
  Windows .... menu option 5 (asks for admin rights, then the password). It appears as drive V:.
  Linux ...... menu option 5 (asks your Linux password for sudo, then the vault password).
  Tails ...... Applications > Utilities > Unlock VeraCrypt Volumes > choose LLM\vault\vault.hc
  Mac ........ install vault\veracrypt\fuse-t-macos-installer-*.pkg, then the VeraCrypt_FUSE-T
               disk image, then mount vault.hc with VeraCrypt. Menu 3 finds it automatically.
ALWAYS close the vault (option 5 again, or eject) before unplugging the USB.


KEEP IT WORKING
---------------
  - Every few months: plug it in, update your notes, try menu options 1, 3, 4 and 5.
  - Keep a second copy of this USB somewhere else (another home, a trusted person).
  - USB drives die. If it acts strange, copy everything to a new one.


WHAT'S WHERE (LLM drive)
------------------------
  START-Windows.bat, start.sh, start-mac.command   launchers
  MAKE-VAULT-Windows.bat                           creates the vault (once)
  models\        Qwen3-4B-Q4_K_M.gguf, qwen2.5-1.5b-instruct-q4_k_m.gguf
  library\       wikipedia_en_medicine_maxi_2026-04.zim (Kiwix format; any extra .zim from
                 library.kiwix.org dropped here is used by options 3 and 4 automatically)
  bin\llama\     llama.cpp b11392 (Windows CPU+GPU, Linux CPU+GPU, Mac Intel+Apple)
  bin\kiwix\     kiwix-serve 3.8.1 for each system
  vault\         vault.hc + VeraCrypt 1.26.29 (Windows portable, Linux, Mac) + FUSE-T for Mac
