@echo off
setlocal enableextensions
title Postlite proxy
color 0f
cd /d "%~dp0"

rem Starts the local CORS proxy so Postlite works in any normal browser.
rem Uses Python if available, otherwise falls back to built-in PowerShell.
rem Keep this window OPEN while testing. Optional port: Proxy.bat 9000

set "PORT=%~1"

rem ---- prefer Python ----
set "PY="
for %%X in (py.exe python.exe python3.exe) do if not defined PY (
  for %%I in (%%X) do if not "%%~$PATH:I"=="" set "PY=%%~$PATH:I"
)

if defined PY (
  echo  Using Python: %PY%
  echo.
  "%PY%" "%~dp0proxy.py" %PORT%
  echo.
  pause
  exit /b 0
)

rem ---- fallback: PowerShell (built into Windows, no install) ----
echo  Python not found - using built-in PowerShell proxy instead.
echo.
if not exist "%~dp0proxy.ps1" (
  echo  [X] proxy.ps1 not found next to this launcher.
  echo.
  pause & exit /b 1
)
where powershell >nul 2>&1
if errorlevel 1 (
  echo  [X] Neither Python nor PowerShell was found.
  echo      Install Python from python.org, or use Postlite-Edge.bat instead.
  echo.
  pause & exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0proxy.ps1" %PORT%
echo.
echo  If PowerShell was blocked by policy, run this instead (built into Windows):
echo     powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0proxy.ps1"
echo  or use Postlite-Edge.bat / install Python.
echo.
pause
endlocal
