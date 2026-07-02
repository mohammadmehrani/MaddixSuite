# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
<#
.SYNOPSIS
    Maddix-SystemCleaner - Deep Windows System & Application Cleaner
.DESCRIPTION
    Comprehensive cleaning utility by Mohammad Mehrani (Maddix).
    Cleans: temp files, browser caches, app caches, logs, old Windows versions,
    duplicate files, empty folders, and privacy traces.
.NOTES
    Version: 1.0
    Author: Mohammad Mehrani (Maddix)
    Part of MaddixSuite: https://github.com/mohammadmehrani/MaddixSuite
    One-liner: irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Cleaner/Maddix-SystemCleaner.ps1 | iex
#>

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: Administrator privileges required." -ForegroundColor Red
    Pause; Exit
}

$script:TotalCleaned = 0
$script:LogFile = "$env:USERPROFILE\Desktop\MaddixSuite\Cleaner\Cleaner_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Show-Banner {
    Clear-Host
    Write-Host "████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host "  ███╗   ███╗ █████╗ ██████╗ ██████╗ ██╗██╗  ██╗" -ForegroundColor Cyan
    Write-Host "  ████╗ ████║██╔══██╗██╔══██╗██╔══██╗██║╚██╗██╔╝" -ForegroundColor Cyan
    Write-Host "  ██╔████╔██║███████║██║  ██║██║  ██║██║ ╚███╔╝ " -ForegroundColor Cyan
    Write-Host "  ██║╚██╔╝██║██╔══██║██║  ██║██║  ██║██║ ██╔██╗ " -ForegroundColor Cyan
    Write-Host "  ██║ ╚═╝ ██║██║  ██║██████╔╝██████╔╝██║██╔╝ ██╗" -ForegroundColor Cyan
    Write-Host "  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═╝" -ForegroundColor Cyan
    Write-Host "████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host "  Maddix-SystemCleaner v1.0 · Deep System Cleaner" -ForegroundColor Cyan
    Write-Host "  Created by Mohammad Mehrani (Maddix)" -ForegroundColor Cyan
    Write-Host "████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host ""
}

function Write-CleanLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $script:LogFile -Value "[$timestamp] $Message"
}

function Get-Size {
    param([string]$Path)
    if (Test-Path $Path) {
        $items = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
        $size = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        $count = ($items | Measure-Object).Count
        return @{Size = $size; Count = $count}
    }
    return @{Size = 0; Count = 0}
}

function Clean-TempFiles {
    Write-Host "`n[1/8] === CLEANING TEMPORARY FILES ===" -ForegroundColor Cyan
    $paths = @(
        "$env:TEMP\*",
        "$env:WINDIR\Temp\*",
        "$env:WINDIR\Prefetch\*",
        "$env:LOCALAPPDATA\Temp\*",
        "$env:WINDIR\Logs\*",
        "$env:WINDIR\System32\LogFiles\*"
    )
    $total = 0
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $before = Get-Size $p
            Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  Cleaned: $p ($(if($before.Count){$before.Count}else{0}) items)" -ForegroundColor Gray
            $total += $before.Count
            $script:TotalCleaned += $before.Size
        }
    }
    Write-Host "  Done. Total items: $total" -ForegroundColor Green
    Write-CleanLog "Temp files cleaned: $total items"
}

function Clean-BrowserCaches {
    Write-Host "`n[2/8] === CLEANING BROWSER CACHES ===" -ForegroundColor Cyan
    
    # Chrome
    $chrome = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
    $chrome2 = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache"
    $chrome3 = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Service Worker\CacheStorage"
    $paths = @($chrome, $chrome2, $chrome3)
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $s = Get-Size $p
            Remove-Item -Path "$p\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  Chrome cache: $(if($s.Size){[math]::Round($s.Size/1MB,2)}else{0}) MB" -ForegroundColor Gray
            $script:TotalCleaned += $s.Size
        }
    }
    
    # Firefox
    $ffProfiles = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" -ErrorAction SilentlyContinue
    foreach ($fp in $ffProfiles) {
        $ffCache = "$($fp.FullName)\cache2"
        if (Test-Path $ffCache) { Remove-Item "$ffCache\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Host "  Firefox cache cleaned" -ForegroundColor Gray }
    }
    
    # Edge
    $edge = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
    if (Test-Path $edge) {
        $s = Get-Size $edge
        Remove-Item "$edge\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Edge cache: $(if($s.Size){[math]::Round($s.Size/1MB,2)}else{0}) MB" -ForegroundColor Gray
        $script:TotalCleaned += $s.Size
    }
    
    # Discord, Slack, Teams
    $appCaches = @(
        "$env:APPDATA\discord\Cache",
        "$env:APPDATA\slack\Cache",
        "$env:APPDATA\Microsoft\Teams\Cache"
    )
    foreach ($ac in $appCaches) {
        if (Test-Path $ac) {
            Remove-Item "$ac\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  $(Split-Path $ac -Leaf) cache cleaned" -ForegroundColor Gray
        }
    }
    
    Write-CleanLog "Browser caches cleaned"
}

function Clean-Logs {
    Write-Host "`n[3/8] === CLEANING SYSTEM & APP LOGS ===" -ForegroundColor Cyan
    $logPaths = @(
        "$env:SystemRoot\Logs\*",
        "$env:SystemRoot\Panther\*",
        "$env:SystemRoot\SoftwareDistribution\Download\*",
        "$env:SystemRoot\System32\winevt\Logs\*.evtx",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*",
        "$env:SystemRoot\ServiceProfiles\*\AppData\Local\Temp\*"
    )
    $total = 0
    foreach ($lp in $logPaths) {
        if (Test-Path $lp) {
            $c = (Get-ChildItem $lp -ErrorAction SilentlyContinue | Measure-Object).Count
            Remove-Item $lp -Recurse -Force -ErrorAction SilentlyContinue
            $total += $c
        }
    }
    Write-Host "  Log files cleaned: $total items" -ForegroundColor Green
    Write-CleanLog "Logs cleaned: $total items"
}

function Clean-OldWindows {
    Write-Host "`n[4/8] === CLEANING OLD WINDOWS VERSIONS ===" -ForegroundColor Cyan
    $winsxs = Get-ChildItem "$env:SystemRoot\WinSxS\Backup" -ErrorAction SilentlyContinue
    $windowsOld = Test-Path "$env:SystemDrive\Windows.old"
    
    if ($windowsOld) {
        $size = Get-Size "$env:SystemDrive\Windows.old"
        $sizeGB = [math]::Round($size.Size / 1GB, 2)
        Write-Host "  Windows.old found: $sizeGB GB" -ForegroundColor Yellow
        $choice = Read-Host "  Remove Windows.old? (y/n)"
        if ($choice -eq 'y') {
            try {
                DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase 2>$null | Out-Null
                Write-Host "  Component cleanup started." -ForegroundColor Green
                $script:TotalCleaned += $size.Size
            } catch { Write-Host "  Failed. Use Disk Cleanup (cleanmgr) instead." -ForegroundColor Red }
        }
    } else {
        Write-Host "  No Windows.old found." -ForegroundColor Gray
    }
    
    Write-Host "  Running DISM component cleanup..." -ForegroundColor Yellow
    try {
        DISM /Online /Cleanup-Image /StartComponentCleanup 2>$null | Out-Null
        Write-Host "  Component cleanup completed." -ForegroundColor Green
    } catch {}
    Write-CleanLog "Old Windows versions cleaned"
}

function Clean-Duplicates {
    Write-Host "`n[5/8] === FINDING DUPLICATE FILES ===" -ForegroundColor Cyan
    Write-Host "WARNING: Scanning for duplicates can be slow on large drives." -ForegroundColor Yellow
    $dupeDirs = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop", "$env:USERPROFILE\Documents")
    
    $duplicates = @{}
    $totalDupes = 0
    $totalSize = 0
    
    foreach ($dd in $dupeDirs) {
        if (Test-Path $dd) {
            Get-ChildItem -Path $dd -File -ErrorAction SilentlyContinue | ForEach-Object {
                $key = "$($_.Name)_$($_.Length)"
                if ($duplicates.ContainsKey($key)) {
                    $duplicates[$key] += @($_.FullName)
                } else {
                    $duplicates[$key] = @($_.FullName)
                }
            }
        }
    }
    
    $foundDupes = $duplicates.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
    if ($foundDupes) {
        Write-Host "  Found potential duplicates:" -ForegroundColor Yellow
        $foundDupes | ForEach-Object {
            $fileSize = [math]::Round((Get-Item $_.Value[0]).Length / 1KB, 1)
            Write-Host "  $($_.Key) ($fileSize KB)" -ForegroundColor Gray
            $_.Value | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
            $totalDupes += $_.Value.Count - 1
            $totalSize += (Get-Item $_.Value[0]).Length * ($_.Value.Count - 1)
        }
        Write-Host "`n  Total duplicate files: $totalDupes" -ForegroundColor Cyan
        Write-Host "  Wasted space: $([math]::Round($totalSize/1MB, 2)) MB" -ForegroundColor Cyan
    } else {
        Write-Host "  No duplicates found in scanned directories." -ForegroundColor Green
    }
    Write-CleanLog "Duplicate scan completed"
}

function Clean-EmptyFolders {
    Write-Host "`n[6/8] === REMOVING EMPTY FOLDERS ===" -ForegroundColor Cyan
    $scanDirs = @("$env:USERPROFILE\Desktop", "$env:USERPROFILE\Documents", "$env:USERPROFILE\Downloads", "$env:TEMP")
    $removed = 0
    
    foreach ($sd in $scanDirs) {
        if (Test-Path $sd) {
            Get-ChildItem -Path $sd -Directory -Recurse -Force -ErrorAction SilentlyContinue |
                Sort-Object -Property FullName -Descending |
                ForEach-Object {
                    $sub = Get-ChildItem -Path $_.FullName -Force -ErrorAction SilentlyContinue
                    if (-not $sub) {
                        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
                        $removed++
                    }
                }
        }
    }
    Write-Host "  Removed $removed empty folders." -ForegroundColor Green
    Write-CleanLog "Empty folders removed: $removed"
}

function Clean-Privacy {
    Write-Host "`n[7/8] === CLEANING PRIVACY TRACES ===" -ForegroundColor Cyan
    
    # Recent documents
    $recent = "$env:APPDATA\Microsoft\Windows\Recent"
    if (Test-Path $recent) { Remove-Item "$recent\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Host "  Recent documents cleared" -ForegroundColor Gray }
    
    # Clipboard
    $clip = "$env:LOCALAPPDATA\Microsoft\Windows\Clipboard"
    if (Test-Path $clip) { Remove-Item "$clip\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Host "  Clipboard history cleared" -ForegroundColor Gray }
    
    # RunMRU
    if (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU") {
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*" -ErrorAction SilentlyContinue
        Write-Host "  Run MRU cleared" -ForegroundColor Gray
    }
    
    # Notification cache
    $notif = "$env:LOCALAPPDATA\Microsoft\Windows\Notifications"
    if (Test-Path $notif) { Remove-Item "$notif\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Host "  Notification cache cleared" -ForegroundColor Gray }
    
    # Thumbnail cache
    try {
        $thumbPath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
        Get-ChildItem "$thumbPath\thumbcache_*.db" -ErrorAction SilentlyContinue | Remove-Item -Force
        Write-Host "  Thumbnail cache cleared" -ForegroundColor Gray
    } catch {}
    
    Write-CleanLog "Privacy traces cleaned"
}

function Clean-FontCache {
    Write-Host "`n[8/8] === CLEANING FONT CACHE ===" -ForegroundColor Cyan
    try {
        Stop-Service -Name FontCache -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:SystemRoot\ServiceProfiles\LocalService\AppData\Local\FontCache\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service -Name FontCache -ErrorAction SilentlyContinue
        Write-Host "  Font cache rebuilt." -ForegroundColor Green
    } catch { Write-Host "  Failed to rebuild font cache." -ForegroundColor Red }
    Write-CleanLog "Font cache rebuilt"
}

function Run-AllClean {
    Write-Host "`n=== RUNNING ALL CLEANERS ===" -ForegroundColor Cyan
    Write-Host "Estimated time: 2-5 minutes`n" -ForegroundColor Yellow
    
    Clean-TempFiles
    Clean-BrowserCaches
    Clean-Logs
    Clean-OldWindows
    Clean-Duplicates
    Clean-EmptyFolders
    Clean-Privacy
    Clean-FontCache
    
    $totalGB = [math]::Round($script:TotalCleaned / 1GB, 2)
    Write-Host "`n==============================================" -ForegroundColor Cyan
    Write-Host "  ALL CLEANERS COMPLETED!" -ForegroundColor Green
    Write-Host "  Total space reclaimed: $totalGB GB" -ForegroundColor Yellow
    Write-Host "  Log saved: $script:LogFile" -ForegroundColor Yellow
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-CleanLog "All cleaners completed. Total: $totalGB GB"
    Pause
}

function Show-Menu {
    Show-Banner
    Write-Host " ──── CLEANING OPERATIONS ────" -ForegroundColor Magenta
    Write-Host "   1.  Clean Temporary Files"
    Write-Host "   2.  Clean Browser Caches (Chrome, Firefox, Edge)"
    Write-Host "   3.  Clean System & App Logs"
    Write-Host "   4.  Clean Old Windows Versions"
    Write-Host "   5.  Find Duplicate Files"
    Write-Host "   6.  Remove Empty Folders"
    Write-Host "   7.  Clean Privacy Traces"
    Write-Host "   8.  Rebuild Font Cache"
    Write-Host ""
    Write-Host " ──── GENERAL ────" -ForegroundColor Magenta
    Write-Host "   9.  Run ALL Cleaners"
    Write-Host "   0.  Exit"
    Write-Host ""
}

function Main {
    New-Item -ItemType Directory -Path "$env:USERPROFILE\Desktop\MaddixSuite\Cleaner" -Force | Out-Null
    while ($true) {
        Show-Menu
        $c = Read-Host "Select option (0-9)"
        switch ($c) {
            "1" { Clean-TempFiles; Pause }
            "2" { Clean-BrowserCaches; Pause }
            "3" { Clean-Logs; Pause }
            "4" { Clean-OldWindows; Pause }
            "5" { Clean-Duplicates; Pause }
            "6" { Clean-EmptyFolders; Pause }
            "7" { Clean-Privacy; Pause }
            "8" { Clean-FontCache; Pause }
            "9" { Run-AllClean }
            "0" { Write-Host "Goodbye!" -ForegroundColor Cyan; exit }
            default { Write-Host "Invalid." -ForegroundColor Red; Pause }
        }
    }
}

Main

