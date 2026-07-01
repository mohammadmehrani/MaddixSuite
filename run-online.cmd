@echo off
title MaddixSuite - Direct GitHub Run
echo ===========================================
echo   MaddixSuite - Running from GitHub...
echo   Created by Mohammad Mehrani
echo ===========================================
echo.
echo [INFO] This will download and execute SysAdminSuite
echo [INFO] directly from the MaddixSuite repository.
echo.
echo [WARNING] Ensure you trust the source before continuing.
echo.
pause
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/maddix/MaddixSuite/main/windows%20os/SysAdminSuite.ps1 | iex"
pause
