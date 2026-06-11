@echo off
rem Double-click to ASSESS apps & startup, then be asked per-category before anything is removed.
rem Protected apps (email, Teams, Office, OneDrive, dev tools, core Windows) are NEVER removed.
rem Right-click "Run as administrator" to also be offered a System Restore Point first.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\debloat-assistant.ps1" -Apply
echo.
pause
