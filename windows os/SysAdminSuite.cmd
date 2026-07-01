@echo off
title MaddixSuite - SysAdminSuite v2.0 (CMD)
chcp 65001 >nul

:: Check Admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ============================================
    echo   MaddixSuite - SysAdminSuite v2.0
    echo   Created by Mohammad Mehrani (Maddix)
    echo ============================================
    echo.
    echo ERROR: This script requires Administrator privileges.
    echo Please right-click and select 'Run as administrator'.
    echo.
    pause
    exit /b 1
)

set "START_TIME=%TIME%"
set "BASE_PATH=%USERPROFILE%\Desktop\MaddixSuite"
set "REPORT_DIR=%BASE_PATH%\Reports"
set "BACKUP_DIR=%BASE_PATH%\Backups"
if not exist "%REPORT_DIR%" mkdir "%REPORT_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: Colors via ANSI
set "CYAN=[96m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "MAGENTA=[95m"
set "GRAY=[90m"
set "RESET=[0m"

:menu
cls
echo %CYAN%================================================================================%RESET%
echo %CYAN%  SysAdminSuite v2.0 - CMD Edition%RESET%
echo %CYAN%  Created by Mohammad Mehrani (Maddix)%RESET%
echo %CYAN%================================================================================%RESET%
echo.
echo  %MAGENTA%---- DIAGNOSTIC ^& REPAIR ----%RESET%
echo    1.  Create System Restore Point
echo    2.  Run Full Diagnostic (SFC + DISM + CHKDSK)
echo    3.  Repair System Files (SFC)
echo    4.  Repair System Image (DISM)
echo    5.  Check Disk for Errors (CHKDSK)
echo    6.  Repair Boot Records
echo    7.  Reset Windows Update Components
echo.
echo  %MAGENTA%---- DRIVER MANAGEMENT ----%RESET%
echo    8.  List Installed Drivers
echo    9.  Backup All Drivers (pnputil)
echo.
echo  %MAGENTA%---- CLEANUP ^& OPTIMIZATION ----%RESET%
echo   10.  Clean Temporary Files
echo   11.  Disk Cleanup (cleanmgr)
echo   12.  Optimize Performance
echo.
echo  %MAGENTA%---- NETWORK TOOLS ----%RESET%
echo   13.  Network Diagnostics (Ping, Tracert)
echo   14.  Reset Network Stack
echo   15.  Flush DNS Cache
echo.
echo  %MAGENTA%---- SYSTEM INFO ----%RESET%
echo   16.  System Information
echo   17.  Check Disk Health (WMIC)
echo.
echo  %MAGENTA%---- GENERAL ----%RESET%
echo   18.  Run ALL Repairs
echo    0.  Exit
echo.
set /p choice="Select option (0-18): "

if "%choice%"=="1" goto restore_point
if "%choice%"=="2" goto full_diag
if "%choice%"=="3" goto sfc
if "%choice%"=="4" goto dism
if "%choice%"=="5" goto chkdsk
if "%choice%"=="6" goto bootrepair
if "%choice%"=="7" goto resetwu
if "%choice%"=="8" goto listdrv
if "%choice%"=="9" goto backupdrv
if "%choice%"=="10" goto cleantemp
if "%choice%"=="11" goto diskclean
if "%choice%"=="12" goto optimize
if "%choice%"=="13" goto netdiag
if "%choice%"=="14" goto netreset
if "%choice%"=="15" goto flushdns
if "%choice%"=="16" goto sysinfo
if "%choice%"=="17" goto diskhealth
if "%choice%"=="18" goto runall
if "%choice%"=="0" goto exit
goto invalid

:restore_point
echo.
echo %YELLOW%Creating System Restore Point...%RESET%
wmic.exe /Namespace:\\root\default Path SystemRestore Call Create "MaddixSuite_RestorePoint_%DATE:/=-%_%TIME::=-%" 2>nul
if %errorLevel% equ 0 ( echo %GREEN%Restore Point created.%RESET% ) else ( echo %RED%Failed. System Restore may be disabled.%RESET% )
echo.
echo %CYAN%To enable: SystemPropertiesProtection.exe%RESET%
pause
goto menu

:full_diag
echo.
echo %YELLOW%Running Full Diagnostic...%RESET%
echo.
echo [1/4] System File Checker...
sfc /scannow
echo.
echo [2/4] DISM Health Restore...
dism /Online /Cleanup-Image /RestoreHealth
echo.
echo [3/4] CHKDSK Scan...
chkdsk %SystemDrive% /scan
echo.
echo [4/4] IP Config...
ipconfig /all > "%REPORT_DIR%\ipconfig.txt"
echo %GREEN%Full diagnostic output captured.%RESET%
set "REPORT_FILE=%REPORT_DIR%\FullDiag_%DATE:/=-%_%TIME::=-%.log"
(echo === MaddixSuite Full Diagnostic ===) > "%REPORT_FILE%"
pause
goto menu

:sfc
echo.
echo %YELLOW%Running SFC /SCANNOW...%RESET%
sfc /scannow
pause
goto menu

:dism
echo.
echo %YELLOW%Running DISM...%RESET%
dism /Online /Cleanup-Image /RestoreHealth
pause
goto menu

:chkdsk
echo.
echo %YELLOW%Running CHKDSK (Scan)...%RESET%
chkdsk %SystemDrive% /scan
echo.
echo %YELLOW%To run with repair: chkdsk %SystemDrive% /f /r%RESET%
pause
goto menu

:bootrepair
echo.
echo %YELLOW%Repairing Boot Records...%RESET%
bootrec /fixmbr
bootrec /fixboot
bootrec /scanos
bootrec /rebuildbcd
echo %GREEN%Boot repair completed.%RESET%
pause
goto menu

:resetwu
echo.
echo %YELLOW%Resetting Windows Update...%RESET%
net stop wuauserv
net stop bits
net stop cryptsvc
if exist "%SystemRoot%\SoftwareDistribution" (
    takeown /f "%SystemRoot%\SoftwareDistribution" /r /d y 2>nul
    icacls "%SystemRoot%\SoftwareDistribution" /grant Administrators:F /t 2>nul
    rmdir /s /q "%SystemRoot%\SoftwareDistribution"
)
if exist "%SystemRoot%\System32\catroot2" (
    rmdir /s /q "%SystemRoot%\System32\catroot2"
)
net start wuauserv
net start bits
net start cryptsvc
echo %GREEN%Windows Update reset completed.%RESET%
pause
goto menu

:listdrv
echo.
echo %YELLOW%Installed Drivers (pnputil):%RESET%
pnputil /enum-drivers
pause
goto menu

:backupdrv
echo.
echo %YELLOW%Backing up drivers...%RESET%
set "DRV_BACKUP=%BACKUP_DIR%\Drivers_%DATE:/=-%_%TIME::=-%"
mkdir "%DRV_BACKUP%" 2>nul
pnputil /export-driver * "%DRV_BACKUP%"
echo %GREEN%Drivers exported to: %DRV_BACKUP%%RESET%
pause
goto menu

:cleantemp
echo.
echo %YELLOW%Cleaning Temporary Files...%RESET%
del /q /f /s "%TEMP%\*" 2>nul
del /q /f /s "%SystemRoot%\Temp\*" 2>nul
del /q /f /s "%SystemRoot%\Prefetch\*" 2>nul
echo %GREEN%Temp files cleaned.%RESET%
pause
goto menu

:diskclean
echo.
echo %YELLOW%Starting Disk Cleanup...%RESET%
cleanmgr /sagerun:1 2>nul
if %errorLevel% neq 0 (
    echo %YELLOW%Running interactive Disk Cleanup...%RESET%
    cleanmgr
)
echo %GREEN%Disk Cleanup completed.%RESET%
pause
goto menu

:optimize
echo.
echo %YELLOW%Optimizing Performance...%RESET%
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>nul
echo %GREEN%Optimizations applied (Power plan: High Performance).%RESET%
pause
goto menu

:netdiag
echo.
echo %YELLOW%Network Diagnostics...%RESET%
echo.
echo Ping Tests:
ping -n 2 8.8.8.8 | find "TTL"
ping -n 2 1.1.1.1 | find "TTL"
ping -n 2 google.com | find "TTL"
echo.
echo Traceroute:
tracert -h 10 8.8.8.8
echo.
echo DNS:
nslookup google.com 2>nul | find "Address"
pause
goto menu

:netreset
echo.
echo %YELLOW%Resetting Network Stack...%RESET%
netsh int ip reset
netsh winsock reset
ipconfig /flushdns
echo %GREEN%Network stack reset. Reboot recommended.%RESET%
pause
goto menu

:flushdns
echo.
echo %YELLOW%Flushing DNS...%RESET%
ipconfig /flushdns
echo %GREEN%DNS cache flushed.%RESET%
pause
goto menu

:sysinfo
echo.
echo %YELLOW%System Information:%RESET%
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Manufacturer" /C:"System Model" /C:"Total Physical Memory" /C:"Processor"
echo.
wmic cpu get name
wmic memorychip get capacity
wmic diskdrive get size,model
pause
goto menu

:diskhealth
echo.
echo %YELLOW%Disk Health:%RESET%
wmic diskdrive get status,model
echo.
echo %CYAN%SMART status requires PowerShell or third-party tools.%RESET%
pause
goto menu

:runall
echo.
echo %YELLOW%Running ALL Repairs...%RESET%
echo.
call :sfc
call :dism
call :chkdsk
call :bootrepair
call :cleantemp
call :optimize
echo.
echo %GREEN%ALL REPAIRS COMPLETED!%RESET%
pause
goto menu

:invalid
echo %RED%Invalid option. Try again.%RESET%
pause
goto menu

:exit
echo %CYAN%Goodbye!%RESET%
exit /b 0
