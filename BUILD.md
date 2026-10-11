# Build your own EDEN

These steps turn a blank USB stick into an EDEN drive. Expect about an hour, most of it downloading
(~15–25 GB).

## What you need

| | Minimum | Recommended |
|---|---|---|
| USB stick | **16 GB**: kit + Tails + SystemRescue (no Ubuntu/Windows ISOs) | **32 GB** for everything below. **64 GB** leaves room for more encyclopedias |
| USB speed | USB 2.0 works | **USB 3.x**. Models load 5–10× faster |
| Computer to build on | **Windows 10 or 11** (the download script, the vault creator and VeraCrypt Portable are Windows tools) | – |
| Internet | ~25 GB of downloads (~12 GB for the 16 GB version) | – |

Space actually used:

| Part | Size | Partition |
|---|---|---|
| Kit: launchers, llama.cpp, kiwix, VeraCrypt | 0.3 GB | LLM |
| Two AI models | 3.4 GB | LLM |
| WikiMed encyclopedia | 2.1 GB | LLM |
| Encrypted vault | 4 GB (you choose the size) | LLM |
| Tails + SystemRescue ISOs | 3.0 GB | Ventoy |
| Ubuntu 24.04 desktop ISO (optional) | 5.9 GB | Ventoy |
| Windows installer ISO (optional) | 5.7 GB | Ventoy |

To run the kit afterwards, a computer needs 4 GB of RAM for the small model and 8 GB for the main one.
A graphics card is optional.

> ⚠️ Step 1 **erases the whole USB stick.** Copy anything you want to keep off it first.

---

## Step 1: Install Ventoy (the boot menu)

1. Download Ventoy for Windows from **https://www.ventoy.net/en/download.html** and unzip it.
2. Plug in the USB stick and run `Ventoy2Disk.exe`.
3. Under **Device**, select your USB stick. Check the size so you don't pick the wrong disk.
4. **Option → Secure Boot Support**: turn it **on**, so it boots on modern PCs.
5. **Option → Partition Configuration → "Preserve some space at the end of the disk"**: enter the
   space for the kit partition:

   | Stick | Preserve at the end |
   |---|---|
   | 16 GB | 11 GB |
   | 32 GB | 13 GB |
   | 64 GB | 40 GB |

6. Click **Install** and confirm both warnings. You now have a partition called **Ventoy** (for ISOs)
   and unallocated space at the end.

## Step 2: Create the kit partition

1. Press `Win + X` → **Disk Management**.
2. Find the USB disk. Right-click the **Unallocated** space → **New Simple Volume**.
3. Use the full size, any free drive letter, **File system: NTFS**, **Volume label: `LLM`**, and
   tick *Quick format*.
4. Note the two drive letters (for example **Ventoy = E:**, **LLM = F:**). You need them in step 4.

NTFS is required: the model files are bigger than FAT32's 4 GB limit, and Windows, Linux and macOS
can all read NTFS.

## Step 3: Copy the kit files

1. Get this repository: **{{REPO_URL}}** → *Code → Download ZIP*, then unzip it.
2. Copy **everything inside the `kit` folder** to the root of the **LLM** drive. Afterwards the LLM
   drive should look like this:

   ```
   F:\
   ├── START-Windows.bat
   ├── start.sh
   ├── start-mac.command
   ├── MAKE-VAULT-Windows.bat
   ├── README.txt
   └── bin\ask.ps1, bin\ask-context.pl
   ```

## Step 4: Download the models, encyclopedia and tools

Open PowerShell in the repository folder and run, using **your** drive letters from step 2:

```powershell
powershell -ExecutionPolicy Bypass -File tools\fetch-usb.ps1 -Ventoy E: -Kit F:
```

It downloads everything in the table below from the official sources, checks the SHA-256 of the
models, encyclopedia and ISOs, and unpacks the Windows programs. It can be stopped and
re-run; interrupted downloads resume. Lines saying `SHA256 MISMATCH` mean a corrupt download: run it again.

**What it downloads** (or download by hand to the same paths, for example to build on Linux):

| What | Get it from | Save as (on the LLM drive) |
|---|---|---|
| **Qwen3-4B** main model, Q4_K_M, 2.3 GB | [model page](https://huggingface.co/Qwen/Qwen3-4B-GGUF) · [direct download](https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf) | `models\Qwen3-4B-Q4_K_M.gguf` |
| **Qwen2.5-1.5B-Instruct** small model, Q4_K_M, 1.0 GB | [model page](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF) · [direct download](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf) | `models\qwen2.5-1.5b-instruct-q4_k_m.gguf` |
| **WikiMed**, Wikipedia medical articles, 2.1 GB | [download.kiwix.org/zim/wikipedia](https://download.kiwix.org/zim/wikipedia/) (`wikipedia_en_medicine_maxi_*.zim`) | `library\` (any `.zim` name) |
| **llama.cpp b11392**, runs the models | [release page](https://github.com/ggml-org/llama.cpp/releases/tag/b11392) | Windows zips unpacked to `bin\llama\win-cpu\`, `bin\llama\win-vulkan\`. Linux/macOS archives kept as `bin\llama\linux-x64.tar.gz`, `linux-vulkan.tar.gz`, `mac-arm64.tar.gz`, `mac-x64.tar.gz` |
| **kiwix-tools 3.8.1**, serves the encyclopedia | [download.kiwix.org/release/kiwix-tools](https://download.kiwix.org/release/kiwix-tools/) | Windows zip unpacked to `bin\kiwix\win\`. Others kept as `bin\kiwix\linux-x64.tar.gz`, `mac-arm64.tar.gz`, `mac-x64.tar.gz` |
| **VeraCrypt 1.26.29**, the vault | [veracrypt.io downloads](https://veracrypt.io/en/Downloads.html) | `vault\veracrypt\`: Portable `.exe`, Ubuntu console `.deb`, `VeraCrypt_FUSE-T_*.dmg` |
| Tails, private OS | [tails.net](https://tails.net/install/download/index.en.html) | Ventoy drive root |
| SystemRescue, repair OS | [system-rescue.org](https://www.system-rescue.org/Download/) | Ventoy drive root |

The model file names must stay exactly as shown, because the launchers look for them. Newer WikiMed
editions replace the one pinned in the script. If its download fails with a 404, get the newest
`wikipedia_en_medicine_maxi_*.zim` by hand.

**Two downloads to do by hand:**

1. **FUSE-T** (opens the vault on macOS): get `fuse-t-macos-installer-*.pkg` from
   [github.com/macos-fuse-t/fuse-t/releases](https://github.com/macos-fuse-t/fuse-t/releases) and save it in
   `vault\veracrypt\` on the LLM drive.
2. **Optional ISOs** for the Ventoy drive, if there's room:
   [Ubuntu 24.04 desktop](https://releases.ubuntu.com/24.04/) and the
   [Windows installer](https://www.microsoft.com/software-download/windows11).
   Copy the `.iso` files to the Ventoy drive's root. Don't unzip or rename them.

**Optional extra encyclopedias:** any `.zim` from [library.kiwix.org](https://library.kiwix.org)
(WikiHow, iFixit repair guides, Wikivoyage, a Wikipedia edition) dropped into `library\` is used by
menu options 3 and 4 automatically.

## Step 5: Create your encrypted vault

1. On the LLM drive, double-click **`MAKE-VAULT-Windows.bat`** and follow its three prompts:
   - **Unpack VeraCrypt:** accept the licence, choose *Extract*, and use the folder it shows
     (`<LLM drive>\vault\veracrypt\windows`).
   - **Create the vault:** in the wizard, choose *Create an encrypted file container → Standard VeraCrypt
     volume*, save it as `<LLM drive>\vault\vault.hc`, use AES / SHA-512 and **exFAT**, pick a size
     (4 GB is plenty for text and scans) and set the password.
   - **Fill it in:** the script opens the vault as drive `V:` and creates
     `notes\my-emergency-notes.md` with headings to fill in (contacts, health, documents).
2. **Password:** use a long passphrase you will remember (5–6 random words). Don't write it on the
   stick. If you forget it, nobody can recover the data.
3. Close the vault with `START-Windows.bat` → **5** before unplugging.

The AI reads `.txt` and `.md` files anywhere in the vault. Save PDFs and Word files as text if you
want it to use them.

## Step 6: Test it

Run `START-Windows.bat` on the LLM drive and go through the menu:

- [ ] **1** Chat (Qwen3 4B) opens in the browser at `127.0.0.1:8080` and answers.
- [ ] **2** Chat (Qwen2.5 1.5B) answers.
- [ ] **5** opens the vault (password prompt, then drive `V:`).
- [ ] **3** with the vault open: ask *"how do I treat a burn?"*, then a question only your notes can
      answer. Both should list sources.
- [ ] **4** shows WikiMed in the browser.
- [ ] **5** again closes the vault.
- [ ] Linux or macOS: run `bash start.sh` from the LLM drive and repeat 1, 3 and 4.
- [ ] Boot test: restart with the stick in, open the boot menu (F12 / F9 / F11 / Esc) and check that
      the Ventoy menu lists your ISOs. With Secure Boot on, the first boot asks you to enroll Ventoy's key
      (*Enroll key from disk → VTOYEFI → ENROLL_THIS_KEY_IN_MOKMANAGER.cer*). This only happens once per
      computer.

## Keep it working

- Every few months: plug it in, update your notes, and run the test list above.
- To move to newer models or tools, update the URLs and SHA-256 values in `tools/fetch-usb.ps1` and
  run step 4 again. The versions are pinned on purpose, so a re-run never changes what you tested.
- USB sticks fail. Keep a second copy somewhere else, and copy everything to a new stick if this
  one starts acting up.
