@echo off
rem Double-click for a read-only health & performance REPORT. Changes nothing.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\performance-check.ps1"
echo.
pause
