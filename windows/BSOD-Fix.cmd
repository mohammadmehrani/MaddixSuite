@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

title MaddixSuite - BSOD 0xD1 Finder & Fixer
color 0B

echo.
echo     /\_/\   MaddixSuite - BSOD 0xD1 Finder ^& Fixer
echo    ( o.o )  Author: Mohammad Mehrani (Maddix)
echo     ^> ^^ ^<   https://github.com/mohammadmehrani/MaddixSuite
echo.

echo [i] This tool detects and fixes BSOD 0xD1 caused by
echo     iaStorAC.sys (Intel RST) on hibernation resume.
echo.

REM Check if running as admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script requires Administrator privileges.
    echo     Right-click and select "Run as Administrator".
    echo.
    pause
    exit /b 1
)

REM Try to run the PowerShell script
set "PS_SCRIPT=%~dp0BSOD-Fix.ps1"
if exist "%PS_SCRIPT%" (
    echo [i] Found BSOD-Fix.ps1, launching...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
    if !errorlevel! neq 0 (
        echo.
        echo [!] PowerShell script encountered an error.
        echo     Try downloading the latest version:
        echo     https://github.com/mohammadmehrani/MaddixSuite
    )
) else (
    echo [!] BSOD-Fix.ps1 not found alongside this script.
    echo     Download the full suite from:
    echo     https://github.com/mohammadmehrani/MaddixSuite
    echo.
    echo     Or run the one-liner:
    echo     irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/BSOD-Fix.ps1 ^| iex
)

echo.
echo     ___   ____________________________________________________________
echo    /   ^|  Author: Mohammad Mehrani (Maddix)
echo   / /^| ^|  Repository: https://github.com/mohammadmehrani/MaddixSuite
echo  /_/ ^|_^|  Website: https://mohammadmehrani.github.io/
echo           "Empower yourself with the right tools"
echo.

pause
