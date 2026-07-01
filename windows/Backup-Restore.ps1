<#
.SYNOPSIS
    MaddixSuite Backup & Restore Tool - Standalone Windows System State Backup
.DESCRIPTION
    Comprehensive backup and restore utility for Windows system state including:
    Registry, Drivers, BCD, Task Scheduler, Network profiles, Environment variables,
    Hosts file, and more. Supports full backup and selective restore.
.NOTES
    Version: 1.0
    Author: Mohammad Mehrani (Maddix)
    GitHub: https://github.com/mohammadmehrani/MaddixSuite
    Run from GitHub: irm https://raw.githubusercontent.com/maddix/MaddixSuite/main/windows/Backup-Restore.ps1 | iex
#>

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: Administrator privileges required." -ForegroundColor Red
    Pause; Exit
}

$script:BasePath = "$env:USERPROFILE\Desktop\MaddixSuite\Backups"
$script:CurrentBackup = "$script:BasePath\Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

function Show-Banner {
    Clear-Host
    Write-Host "████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host "  MaddixSuite - Backup & Restore Tool v1.0" -ForegroundColor Cyan
    Write-Host "  Created by Mohammad Mehrani (Maddix)" -ForegroundColor Cyan
    Write-Host "████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host ""
}

function Backup-Registry {
    Write-Host "[1/7] Backing up Registry..." -ForegroundColor Yellow
    $p = "$script:CurrentBackup\Registry"
    New-Item -ItemType Directory -Path $p -Force | Out-Null
    $hives = @("HKLM\Software", "HKLM\System", "HKLM\SAM", "HKLM\Security", "HKCU\Software")
    foreach ($h in $hives) {
        $name = $h -replace '\\', '_'
        reg export $h "$p\$name.reg" /y 2>$null | Out-Null
    }
    Write-Host "  Registry exported to $p" -ForegroundColor Green
}

function Backup-Drivers {
    Write-Host "[2/7] Backing up Drivers..." -ForegroundColor Yellow
    $p = "$script:CurrentBackup\Drivers"
    New-Item -ItemType Directory -Path $p -Force | Out-Null
    try {
        Export-WindowsDriver -Online -Destination $p -ErrorAction Stop
        Write-Host "  Drivers exported ($( (Get-ChildItem $p -Recurse -Filter "*.inf" | Measure-Object).Count ) files)" -ForegroundColor Green
    } catch { Write-Host "  Driver backup failed: $_" -ForegroundColor Red }
}

function Backup-BCD {
    Write-Host "[3/7] Backing up BCD..." -ForegroundColor Yellow
    try {
        bcdedit /export "$script:CurrentBackup\BCD.bak" 2>$null
        Write-Host "  BCD backed up." -ForegroundColor Green
    } catch { Write-Host "  BCD backup failed." -ForegroundColor Red }
}

function Backup-Tasks {
    Write-Host "[4/7] Backing up Task Scheduler..." -ForegroundColor Yellow
    try {
        schtasks /query /XML /TN "*" > "$script:CurrentBackup\Tasks.xml" 2>$null
        Write-Host "  Scheduled tasks exported." -ForegroundColor Green
    } catch { Write-Host "  Tasks export failed." -ForegroundColor Red }
}

function Backup-Network {
    Write-Host "[5/7] Backing up Network Config..." -ForegroundColor Yellow
    try {
        netsh dump > "$script:CurrentBackup\network.txt" 2>$null
        netsh wlan export profile folder="$script:CurrentBackup\WiFi" key=clear 2>$null
        Write-Host "  Network config saved." -ForegroundColor Green
    } catch { }
}

function Backup-Hosts {
    Write-Host "[6/7] Backing up Hosts & Environment..." -ForegroundColor Yellow
    Copy-Item -Path "$env:SystemRoot\System32\drivers\etc\hosts" -Destination "$script:CurrentBackup\hosts.backup" -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path "Env:" | Export-Clixml -Path "$script:CurrentBackup\EnvVars.xml" -Force -ErrorAction SilentlyContinue
    Write-Host "  Hosts + Env vars saved." -ForegroundColor Green
}

function Backup-Summary {
    $size = (Get-ChildItem -Path $script:CurrentBackup -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "[7/7] Creating checksums..." -ForegroundColor Yellow
    Get-ChildItem -Path $script:CurrentBackup -Recurse -File | ForEach-Object {
        $hash = (Get-FileHash $_.FullName -Algorithm MD5).Hash
        "$hash  $($_.Name)" | Out-File "$script:CurrentBackup\checksums.md5" -Append
    }
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  BACKUP COMPLETED!" -ForegroundColor Green
    Write-Host "  Location: $script:CurrentBackup" -ForegroundColor Yellow
    Write-Host "  Size: $([math]::Round($size, 2)) MB" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
}

function Do-Backup {
    Show-Banner
    Write-Host "Starting Full System Backup..." -ForegroundColor Cyan
    Write-Host "Destination: $script:CurrentBackup`n" -ForegroundColor Gray
    New-Item -ItemType Directory -Path $script:CurrentBackup -Force | Out-Null
    Backup-Registry
    Backup-Drivers
    Backup-BCD
    Backup-Tasks
    Backup-Network
    Backup-Hosts
    Backup-Summary
    Pause
}

function List-Backups {
    $backups = Get-ChildItem -Path $script:BasePath -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if (-not $backups) {
        Write-Host "No backups found in $script:BasePath" -ForegroundColor Yellow
        return $null
    }
    Write-Host "Available backups:" -ForegroundColor Cyan
    $i = 1
    foreach ($b in $backups) {
        $size = "{0:N2}" -f ((Get-ChildItem $b.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "  $i. $($b.Name)  ($size MB)"
        $i++
    }
    return $backups
}

function Do-Restore {
    Show-Banner
    $backups = List-Backups
    if (-not $backups) { Pause; return }
    $sel = Read-Host "`nSelect backup number to restore"
    $idx = [int]$sel - 1
    if ($idx -lt 0 -or $idx -ge $backups.Count) { Write-Host "Invalid." -ForegroundColor Red; Pause; return }

    $src = $backups[$idx].FullName
    Write-Host "`nWhat would you like to restore?" -ForegroundColor Cyan
    Write-Host "  1. Registry only"
    Write-Host "  2. Drivers only"
    Write-Host "  3. Everything"
    $rChoice = Read-Host "Select (1-3)"
    switch ($rChoice) {
        "1" {
            $regPath = "$src\Registry"
            if (Test-Path $regPath) {
                Write-Host "WARNING: Restoring registry can destabilize your system!" -ForegroundColor Red
                $confirm = Read-Host "Type YES to confirm"
                if ($confirm -eq "YES") {
                    Get-ChildItem $regPath -Filter "*.reg" | ForEach-Object {
                        reg import $_.FullName 2>$null
                        Write-Host "  Restored: $($_.Name)" -ForegroundColor Gray
                    }
                    Write-Host "Registry restored." -ForegroundColor Green
                }
            }
        }
        "2" {
            $drvPath = "$src\Drivers"
            if (Test-Path $drvPath) {
                Get-ChildItem $drvPath -Filter "*.inf" -Recurse | ForEach-Object {
                    Add-WindowsDriver -Online -Driver $_.FullName -ErrorAction SilentlyContinue
                }
                Write-Host "Drivers restored." -ForegroundColor Green
            }
        }
        "3" {
            $regPath = "$src\Registry"
            if (Test-Path $regPath) {
                Write-Host "Restoring Registry..." -ForegroundColor Yellow
                Get-ChildItem $regPath -Filter "*.reg" | ForEach-Object {
                    reg import $_.FullName 2>$null
                }
            }
            $drvPath = "$src\Drivers"
            if (Test-Path $drvPath) {
                Write-Host "Restoring Drivers..." -ForegroundColor Yellow
                Get-ChildItem $drvPath -Filter "*.inf" -Recurse | ForEach-Object {
                    Add-WindowsDriver -Online -Driver $_.FullName -ErrorAction SilentlyContinue
                }
            }
            $bcdFile = "$src\BCD.bak"
            if (Test-Path $bcdFile) { bcdedit /import $bcdFile 2>$null }
            $hostsFile = "$src\hosts.backup"
            if (Test-Path $hostsFile) { Copy-Item $hostsFile "$env:SystemRoot\System32\drivers\etc\hosts" -Force }
            Write-Host "Full restore completed." -ForegroundColor Green
        }
    }
    Pause
}

function Show-Menu {
    Show-Banner
    Write-Host "  1.  Create Full System Backup" -ForegroundColor White
    Write-Host "  2.  Restore from Backup" -ForegroundColor White
    Write-Host "  3.  List Available Backups" -ForegroundColor White
    Write-Host "  0.  Exit" -ForegroundColor White
    Write-Host ""
    $c = Read-Host "Select option"
    switch ($c) {
        "1" { Do-Backup }
        "2" { Do-Restore }
        "3" { Show-Banner; List-Backups; Pause }
        "0" { Exit }
    }
}

while ($true) { Show-Menu }
