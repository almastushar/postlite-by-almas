@echo off
setlocal enableextensions
title Postlite launcher
color 0f

rem ============================================================
rem  Postlite launcher  -  opens postlite.html as a Chrome app
rem  window with web security disabled (for internal/VPN APIs).
rem  Keep this .bat in the SAME folder as postlite.html.
rem ============================================================

rem ---- find chrome.exe (no for-loop: the (x86) path has a ")") ----
set "CHROME="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" set "CHROME=%LocalAppData%\Google\Chrome\Application\chrome.exe"
if not defined CHROME for /f "skip=2 tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" /ve 2^>nul') do set "CHROME=%%B"

if not defined CHROME (
  echo  [X] chrome.exe not found. Open this file in Notepad and set it manually:
  echo        set "CHROME=C:\Program Files\Google\Chrome\Application\chrome.exe"
  echo.
  pause & exit /b 1
)

rem ---- locate postlite.html next to this bat ----
set "HTML=%~dp0postlite.html"
if not exist "%HTML%" (
  echo  [X] postlite.html not found next to this launcher.
  echo      Put Postlite.bat and postlite.html in the SAME folder.
  echo.
  pause & exit /b 1
)
set "DIR=%~dp0"
set "DIR=%DIR:\=/%"
set "URL=file:///%DIR%postlite.html"
set "PROFILE=%~dp0plchrome-profile"

echo  Chrome  : %CHROME%
echo  Page    : %URL%
echo  Profile : %PROFILE%
echo.

rem ---- the --disable-web-security flag is IGNORED if a Chrome using this
rem      profile is already running. Offer to close Chrome first. ----
tasklist /FI "IMAGENAME eq chrome.exe" 2>nul | find /I "chrome.exe" >nul
if not errorlevel 1 (
  echo  Chrome is currently running. The security flag will NOT apply
  echo  unless Chrome is fully closed first.
  echo.
  choice /C YN /M "Close all Chrome windows now and continue"
  if errorlevel 2 ( echo  Cancelled. & echo. & pause & exit /b 0 )
  taskkill /F /IM chrome.exe >nul 2>&1
  timeout /t 2 >nul
)

echo  Launching...
start "" "%CHROME%" --app="%URL%" --disable-web-security --disable-site-isolation-trials --user-data-dir="%PROFILE%" --no-first-run --no-default-browser-check --test-type

echo.
echo  Done. To VERIFY it worked, in the new window open:  chrome://version
echo  The "Command Line" row must list  --disable-web-security
echo  (a yellow "unsupported flag" bar also confirms it).
echo.
pause
endlocal
exit /b 0
