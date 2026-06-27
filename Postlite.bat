@echo off
setlocal enableextensions
cd /d "%~dp0"

rem ============================================================
rem  Postlite - launches as a Chrome app window with web
rem  security disabled (so internal/VPN APIs work). Uses its own
rem  isolated profile next to this file, so your normal Chrome is
rem  unaffected and nothing needs to be closed.
rem ============================================================

set "CHROME="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" set "CHROME=%LocalAppData%\Google\Chrome\Application\chrome.exe"
if not defined CHROME for /f "skip=2 tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" /ve 2^>nul') do set "CHROME=%%B"

rem fall back to Edge if Chrome isn't installed
set "BROWSER=%CHROME%"
if not defined BROWSER if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" set "BROWSER=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if not defined BROWSER if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" set "BROWSER=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"

if not defined BROWSER (
  echo  Could not find Chrome or Edge. Edit this file and set BROWSER manually.
  pause & exit /b 1
)
if not exist "%~dp0postlite.html" (
  echo  postlite.html not found next to this launcher.
  pause & exit /b 1
)

set "DIR=%~dp0"
set "DIR=%DIR:\=/%"
set "URL=file:///%DIR%postlite.html"
set "PROFILE=%~dp0app-profile"

start "" "%BROWSER%" --app="%URL%" --window-size=1280,840 --disable-web-security --disable-site-isolation-trials --user-data-dir="%PROFILE%" --no-first-run --no-default-browser-check --test-type

endlocal
exit /b 0
