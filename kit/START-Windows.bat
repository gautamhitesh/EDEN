@echo off
rem Emergency kit launcher for Windows. Double-click this file.
setlocal
set "USB=%~d0\"
set "BIN=%USB%bin"
set "VC=%USB%vault\veracrypt\windows"
set "VAULT=V:\"
title Emergency Kit

:menu
cls
echo.
echo   ===== EMERGENCY KIT =====
echo   1) Chat - Qwen3 4B        (best answers, needs ~6 GB free RAM)
echo   2) Chat - Qwen2.5 1.5B    (fast, for old or weak computers)
echo   3) Ask a question         (uses the encyclopedias + your notes if the vault is open)
echo   4) Encyclopedias          (offline WikiMed and any .zim in library, with images)
echo   5) Open / close the encrypted vault
echo   q) Quit
echo.
set "c="
set /p "c=  Choose: "
if "%c%"=="1" call :chat Qwen3-4B-Q4_K_M.gguf
if "%c%"=="2" call :chat qwen2.5-1.5b-instruct-q4_k_m.gguf
if "%c%"=="3" call :ask
if "%c%"=="4" call :wiki
if "%c%"=="5" call :vault
if /i "%c%"=="q" exit /b
goto menu

:pickllama
rem Vulkan build pinned to a discrete GPU if there is one; integrated GPUs are slower than the CPU
rem build here (and splitting across iGPU+dGPU was 5x slower in testing), so they get the CPU build.
set "LLAMA=%BIN%\llama\win-cpu"
set "NGL="
for /f "tokens=1 delims=: " %%d in ('%BIN%\llama\win-vulkan\llama-server.exe --list-devices 2^>nul ^| findstr /r /c:"Vulkan[0-9]*:.*NVIDIA" /c:"Vulkan[0-9]*:.*Radeon RX" /c:"Vulkan[0-9]*:.*Arc"') do (
  if not defined NGL set "NGL=-ngl 99 -dev %%d"
)
if defined NGL (
  set "LLAMA=%BIN%\llama\win-vulkan"
  echo Using the graphics card.
)
exit /b

:waithttp
powershell -NoProfile -Command "for($i=0;$i -lt 180;$i++){try{Invoke-WebRequest -UseBasicParsing '%~1' -TimeoutSec 2 | Out-Null; exit 0}catch{Start-Sleep 1}}; exit 1"
exit /b

:chat
call :pickllama
echo Starting the model (first load can take a minute)...
start "" /b "%LLAMA%\llama-server.exe" -m "%USB%models\%~1" -c 8192 %NGL% --host 127.0.0.1 --port 8080
call :waithttp http://127.0.0.1:8080/health && start "" http://127.0.0.1:8080
echo.
echo   Chat is open in your browser at http://127.0.0.1:8080
echo   Press any key here to STOP the model and go back to the menu.
pause >nul
taskkill /im llama-server.exe /f >nul 2>&1
exit /b

:ask
rem Searches every .zim in library\ and the vault's .txt/.md files per question, then answers with sources.
call :startwiki
call :pickllama
powershell -NoProfile -ExecutionPolicy Bypass -File "%BIN%\ask.ps1" -Vault "%VAULT%." -Llama "%LLAMA%" -Model "%USB%models\Qwen3-4B-Q4_K_M.gguf" -Ngl "%NGL%"
taskkill /im kiwix-serve.exe /f >nul 2>&1
exit /b

:startwiki
set "ZIMS="
for %%f in ("%USB%library\*.zim") do call set ZIMS=%%ZIMS%% "%%f"
if defined ZIMS start "" /b "%BIN%\kiwix\win\kiwix-serve.exe" --address 127.0.0.1 --port 8081 %ZIMS%
exit /b

:wiki
call :startwiki
call :waithttp http://127.0.0.1:8081 && start "" http://127.0.0.1:8081
echo.
echo   Medical encyclopedia is open at http://127.0.0.1:8081
echo   Press any key here to STOP it and go back to the menu.
pause >nul
taskkill /im kiwix-serve.exe /f >nul 2>&1
exit /b

:vault
if not exist "%USB%vault\vault.hc" (
  echo No vault yet. Run MAKE-VAULT-Windows.bat first.
  pause
  exit /b
)
if exist "%VAULT%" (
  "%VC%\VeraCrypt-x64.exe" /dismount V /quit /silent
  echo Vault closed.
  pause
  exit /b
)
echo VeraCrypt will ask for administrator rights and then your vault password.
"%VC%\VeraCrypt-x64.exe" /volume "%USB%vault\vault.hc" /letter V /explore /quit
exit /b
