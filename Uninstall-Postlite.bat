@echo off
setlocal enableextensions
title Uninstall Postlite shortcuts
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=@((Join-Path ([Environment]::GetFolderPath('Desktop')) 'Postlite.lnk'), (Join-Path ([Environment]::GetFolderPath('Programs')) 'Postlite.lnk')); foreach($f in $p){ if(Test-Path $f){ Remove-Item $f -Force; Write-Host ('Removed '+$f) } }"
echo.
echo  Shortcuts removed. The Postlite files in this folder are untouched.
echo.
pause
endlocal
