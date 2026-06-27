@echo off
setlocal enableextensions
cd /d "%~dp0"
title Install Postlite

rem Registers Postlite as a desktop app: creates Desktop + Start Menu
rem shortcuts (with icon) that launch Postlite.bat. No admin needed.

if not exist "%~dp0Postlite.bat" ( echo  Postlite.bat missing next to this file. & pause & exit /b 1 )
if not exist "%~dp0postlite.html" ( echo  postlite.html missing next to this file. & pause & exit /b 1 )

set "PL_DIR=%~dp0"
set "PL_TARGET=%~dp0Postlite.bat"
set "PL_ICON=%~dp0Postlite.ico"
if not exist "%PL_ICON%" set "PL_ICON=%~dp0Postlite.bat"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ws=New-Object -ComObject WScript.Shell; $targets=@([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs')); foreach($p in $targets){ if(-not (Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }; $lnk=$ws.CreateShortcut((Join-Path $p 'Postlite.lnk')); $lnk.TargetPath=$env:PL_TARGET; $lnk.WorkingDirectory=$env:PL_DIR; $lnk.IconLocation=$env:PL_ICON; $lnk.WindowStyle=7; $lnk.Description='Postlite API client'; $lnk.Save() }; Write-Host 'Created Postlite shortcuts on Desktop and Start Menu.'"

if errorlevel 1 (
  echo.
  echo  Shortcut creation failed (PowerShell may be blocked). You can still
  echo  make one manually: right-click Postlite.bat -^> Send to -^> Desktop.
) else (
  echo.
  echo  Done. "Postlite" now appears on your Desktop and in the Start Menu
  echo  (search "Postlite"). It launches Postlite.bat - the app window with
  echo  web security disabled. Right-click its taskbar icon to "Pin to taskbar".
)
echo.
pause
endlocal
