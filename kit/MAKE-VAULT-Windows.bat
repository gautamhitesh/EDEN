@echo off
rem Creates the encrypted vault (run once, on Windows). You choose the password; it is never stored.
setlocal
set "USB=%~d0\"
set "VC=%USB%vault\veracrypt\windows"
set "IMG=%USB%vault\vault.hc"
title Make the encrypted vault
rem START-Windows.bat option 5 calls this when there is no vault yet; it has shown the insignia already
if not defined SHOWN powershell -NoProfile -ExecutionPolicy Bypass -File "%USB%bin\banner.ps1"

if exist "%IMG%" (
  echo A vault already exists: %IMG%
  echo Nothing to do. To start over, delete that file yourself first - its contents are lost forever.
  pause
  exit /b
)

if not exist "%VC%\VeraCrypt Format-x64.exe" (
  echo STEP 1 of 3 - unpack VeraCrypt ^(one time^)
  echo   In the window that opens: accept the licence, choose "Extract", and use this folder:
  echo       %VC%
  echo.
  pause
  start /wait "" "%USB%vault\veracrypt\VeraCrypt.Portable.1.26.29.exe"
)
if not exist "%VC%\VeraCrypt Format-x64.exe" (
  echo VeraCrypt was not unpacked to %VC% - run this file again.
  pause
  exit /b
)

echo.
echo STEP 2 of 3 - create the vault. In the VeraCrypt wizard choose:
echo   Create an encrypted file container  ^>  Standard VeraCrypt volume
echo   Select File:  %IMG%
echo   Encryption: AES     Hash: SHA-512
echo   Size: 4 GB
echo   Password: a long passphrase you will REMEMBER ^(5-6 random words^). It cannot be recovered.
echo   Filesystem: exFAT   ^(so Windows, Linux and Mac can all read it^)
echo   Move the mouse until the bar is full, click Format, then Exit.
echo.
pause
start /wait "" "%VC%\VeraCrypt Format-x64.exe"
if not exist "%IMG%" (
  echo No vault was created at %IMG% - run this file again.
  pause
  exit /b
)

echo.
echo STEP 3 of 3 - open it once to add the notes folder. Enter the password you just chose.
"%VC%\VeraCrypt-x64.exe" /volume "%IMG%" /letter V /quit
if not exist V:\ (
  echo Could not open the vault. You can add a "notes" folder later via START-Windows.bat option 5.
  pause
  exit /b
)
mkdir V:\notes 2>nul
(
  echo # Emergency notes - edit me. The kit's AI reads every .md/.txt file in this folder.
  echo.
  echo ## People to call
  echo - Name, relation, phone:
  echo.
  echo ## Health
  echo - Blood group:
  echo - Allergies:
  echo - Regular medicines and doses:
  echo - Doctor / hospital:
  echo.
  echo ## Documents ^(numbers, where the originals are^)
  echo - Aadhaar / PAN / passport:
  echo - Insurance policies:
  echo.
  echo ## Money and accounts ^(recovery info and hints - not raw passwords^)
  echo - Banks, branches, who to contact:
  echo.
  echo ## Plans
  echo - Family meeting point:
) > V:\notes\my-emergency-notes.md
label V: EDEN-VAULT >nul 2>&1
copy /y "%USB%vault\EDEN-ID.txt" V:\ >nul
start "" V:\notes
echo.
echo Done. Edit V:\notes\my-emergency-notes.md now, then close the vault with
echo START-Windows.bat option 5 ^(or VeraCrypt "Dismount"^) before unplugging the USB.
pause
