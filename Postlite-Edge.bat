@echo off
setlocal enableextensions
title Postlite (Edge) launcher
color 0f

rem Opens Postlite in Microsoft EDGE app mode with web security disabled.
rem Edge is a separate browser, so your normal CHROME stays open and untouched.
rem Keep this .bat in the SAME folder as postlite.html.

set "EDGE="
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" set "EDGE=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if not defined EDGE if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" set "EDGE=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
if not defined EDGE for /f "skip=2 tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" /ve 2^>nul') do set "EDGE=%%B"

if not defined EDGE (
  echo  [X] msedge.exe not found. Open this file in Notepad and set EDGE manually.
  echo.
  pause & exit /b 1
)

set "HTML=%~dp0postlite.html"
if not exist "%HTML%" (
  echo  [X] postlite.html not found next to this launcher.
  echo.
  pause & exit /b 1
)
set "DIR=%~dp0"
set "DIR=%DIR:\=/%"
set "URL=file:///%DIR%postlite.html"
set "PROFILE=%~dp0pledge-profile"

echo  Edge    : %EDGE%
echo  Page    : %URL%
echo.

tasklist /FI "IMAGENAME eq msedge.exe" 2>nul | find /I "msedge.exe" >nul
if not errorlevel 1 (
  echo  Edge is already running; the security flag will not apply until it is closed.
  choice /C YN /M "Close all Edge windows now and continue"
  if errorlevel 2 ( echo Cancelled. & pause & exit /b 0 )
  taskkill /F /IM msedge.exe >nul 2>&1
  timeout /t 2 >nul
)

start "" "%EDGE%" --app="%URL%" --disable-web-security --disable-site-isolation-trials --user-data-dir="%PROFILE%" --no-first-run --no-default-browser-check --test-type
echo  Launched in Edge. Verify at edge://version (Command Line row).
echo.
pause
endlocal
