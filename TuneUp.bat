@echo off
rem Double-click to run the report and then be offered safe fixes one by one.
rem Right-click "Run as administrator" to unlock sfc /scannow and DISM repair.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\performance-check.ps1" -Tune
echo.
pause
