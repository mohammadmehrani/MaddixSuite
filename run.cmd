@echo off
title MaddixSuite - SysAdminSuite
echo ===========================================
echo   MaddixSuite - SysAdminSuite Launcher
echo   Created by Mohammad Mehrani
echo ===========================================
echo.
echo [INFO] Running with PowerShell...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows os\SysAdminSuite.ps1"
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Script execution failed.
    echo Make sure you run this file as Administrator.
    pause
)
