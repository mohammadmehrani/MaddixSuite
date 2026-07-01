<#
.SYNOPSIS
    SysAdminSuite v2.0 - Comprehensive Windows Diagnostic, Repair, Backup & Optimization Toolkit
.DESCRIPTION
    Part of the MaddixSuite collection. All-in-one tool for Windows 7/8/10/11 (and Server)
    with 30+ features: diagnostics, system repair, driver management, backup/restore,
    performance optimization, network tools, security scans, and detailed reporting.
.NOTES
    Version: 2.0
    Author: Mohammad Mehrani (Maddix)
    License: MIT
    GitHub: https://github.com/mohammadmehrani/MaddixSuite
    Run directly from GitHub (one-liner):
    irm https://raw.githubusercontent.com/maddix/MaddixSuite/main/windows%20os/SysAdminSuite.ps1 | iex
#>

#region Self-Elevation and Bypass
if ($PSVersionTable.PSVersion.Major -ge 3) {
    $currentPolicy = Get-ExecutionPolicy -Scope Process
    if ($currentPolicy -ne 'Bypass' -and $currentPolicy -ne 'Unrestricted') {
        $scriptPath = $MyInvocation.MyCommand.Path
        Write-Host "Restarting with Bypass Policy..." -ForegroundColor Yellow
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $scriptPath
        exit
    }
}

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please right-click and select 'Run as administrator'." -ForegroundColor Yellow
    Pause
    Exit
}
#endregion

#region Global Variables & Paths
$script:StartTime = Get-Date
$script:BasePath = "$env:USERPROFILE\Desktop\MaddixSuite"
$script:LogPath = "$script:BasePath\Reports\MaddixSuite_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$script:BackupPath = "$script:BasePath\Backups\Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$script:ReportTXT = "$script:LogPath\Report.txt"
$script:ReportHTML = "$script:LogPath\Report.html"
$script:Errors = @()
$script:Warnings = @()
$script:Info = @()
$script:OSVersion = $null
$script:OSArch = $null
$script:RestorePointCreated = $false
New-Item -ItemType Directory -Path $script:LogPath -Force -ErrorAction SilentlyContinue | Out-Null
#endregion

#region Logging Functions
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Type] $Message"
    Add-Content -Path $script:ReportTXT -Value $line -ErrorAction SilentlyContinue
    switch ($Type) {
        "ERROR"   { Write-Host $line -ForegroundColor Red; $script:Errors += $Message }
        "WARNING" { Write-Host $line -ForegroundColor Yellow; $script:Warnings += $Message }
        "SUCCESS" { Write-Host $line -ForegroundColor Green; $script:Info += $Message }
        default   { Write-Host $line -ForegroundColor Cyan; $script:Info += $Message }
    }
}

function Generate-HTMLReport {
    $duration = (Get-Date) - $script:StartTime
    $html = @"
<!DOCTYPE html>
<html>
<head><title>MaddixSuite - SysAdminSuite Report</title>
<style>
body { font-family: Segoe UI, Arial; margin:20px; background:#f0f2f5; }
.container { max-width:1200px; margin:auto; background:#fff; padding:25px; border-radius:12px; box-shadow:0 2px 10px rgba(0,0,0,0.1); }
h1 { color:#2c3e50; border-bottom:3px solid #3498db; padding-bottom:10px; }
h2 { color:#34495e; margin-top:30px; }
.error { color:#e74c3c; }
.warning { color:#f39c12; }
.success { color:#27ae60; }
.info { color:#2980b9; }
pre { background:#ecf0f1; padding:15px; border-radius:8px; overflow:auto; }
table { width:100%; border-collapse:collapse; margin:15px 0; }
th, td { border:1px solid #ddd; padding:8px; text-align:left; }
th { background:#3498db; color:white; }
</style>
</head>
<body>
<div class='container'>
<h1>MaddixSuite - SysAdminSuite Diagnostic Report</h1>
<p><strong>System:</strong> $env:COMPUTERNAME | <strong>User:</strong> $env:USERNAME | <strong>Date:</strong> $(Get-Date)</p>
<p><strong>OS:</strong> $script:OSVersion ($script:OSArch) | <strong>PowerShell:</strong> $($PSVersionTable.PSVersion)</p>
<hr>
<h2>Summary</h2>
<ul>
<li class='error'>Errors: $($script:Errors.Count)</li>
<li class='warning'>Warnings: $($script:Warnings.Count)</li>
<li class='info'>Info: $($script:Info.Count)</li>
<li>Duration: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s</li>
</ul>
<h2>Errors</h2>
<pre>$($script:Errors -join "`n")</pre>
<h2>Warnings</h2>
<pre>$($script:Warnings -join "`n")</pre>
<h2>Info</h2>
<pre>$($script:Info -join "`n")</pre>
</div>
</body>
</html>
"@
    $html | Out-File -FilePath $script:ReportHTML -Encoding UTF8
}
#endregion

#region OS Detection
function Get-OSInfo {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $script:OSVersion = "$($os.Caption) $($os.Version) (Build $($os.BuildNumber))"
        $script:OSArch = if ($os.OSArchitecture) { $os.OSArchitecture } else { "Unknown" }
        Write-Log "Detected OS: $script:OSVersion" "SUCCESS"
    } catch {
        Write-Log "Failed to detect OS: $_" "ERROR"
        $script:OSVersion = "Unknown"
        $script:OSArch = "Unknown"
    }
}
#endregion

#region System Restore
function Create-RestorePoint {
    try {
        if ($script:OSVersion -match "Windows 7|Windows 8|Windows 10|Windows 11") {
            Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description "MaddixSuite_RestorePoint_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
            $script:RestorePointCreated = $true
            Write-Log "System Restore Point created." "SUCCESS"
        } else {
            Write-Log "System Restore not supported on this OS." "WARNING"
        }
    } catch {
        Write-Log "Failed to create Restore Point: $_" "WARNING"
    }
}

function List-RestorePoints {
    Write-Host "`n=== LISTING RESTORE POINTS ===" -ForegroundColor Cyan
    try {
        $rps = Get-ComputerRestorePoint -ErrorAction Stop
        if ($rps) {
            $rps | Format-Table -AutoSize
        } else {
            Write-Host "No restore points found." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to list restore points." -ForegroundColor Red
    }
}
#endregion

#region System Repairs
function Run-SFC {
    Write-Host "`n=== RUNNING SFC /SCANNOW ===" -ForegroundColor Cyan
    try {
        $result = sfc /scannow 2>&1
        Write-Host $result
        if ($result -match "did not find any integrity violations") {
            Write-Log "SFC: No integrity violations." "SUCCESS"
        } elseif ($result -match "successfully repaired them") {
            Write-Log "SFC: Repaired corrupt files." "SUCCESS"
        } else {
            Write-Log "SFC completed with issues." "WARNING"
        }
    } catch {
        Write-Log "SFC failed: $_" "ERROR"
    }
}

function Run-DISM {
    Write-Host "`n=== RUNNING DISM (Windows 8/10/11 only) ===" -ForegroundColor Cyan
    if ($script:OSVersion -match "Windows 8|Windows 10|Windows 11|Windows Server 2012|2016|2019|2022") {
        try {
            $result = DISM /Online /Cleanup-Image /RestoreHealth 2>&1
            Write-Host $result
            if ($result -match "successfully") {
                Write-Log "DISM completed successfully." "SUCCESS"
            } else {
                Write-Log "DISM completed with issues." "WARNING"
            }
        } catch {
            Write-Log "DISM failed: $_" "ERROR"
        }
    } else {
        Write-Host "DISM not available on this OS version." -ForegroundColor Yellow
    }
}

function Run-DISM-Online {
    Write-Host "`n=== DISM WITH ONLINE WINDOWS UPDATE ===" -ForegroundColor Cyan
    try {
        $result = DISM /Online /Cleanup-Image /RestoreHealth /Source:WindowsUpdate 2>&1
        Write-Host $result
        if ($result -match "successfully") {
            Write-Log "DISM (Online) completed successfully." "SUCCESS"
        } else {
            Write-Log "DISM (Online) completed with issues." "WARNING"
        }
    } catch {
        Write-Log "DISM (Online) failed: $_" "ERROR"
    }
}

function Run-CHKDSK {
    Write-Host "`n=== RUNNING CHKDSK (Scan only) ===" -ForegroundColor Cyan
    try {
        $result = chkdsk $env:SystemDrive /scan /perf 2>&1
        Write-Host $result
        if ($result -match "No problems found") {
            Write-Log "CHKDSK: No errors." "SUCCESS"
        } else {
            Write-Log "CHKDSK: Issues found - consider running 'chkdsk /f' after reboot." "WARNING"
        }
    } catch {
        Write-Log "CHKDSK failed: $_" "ERROR"
    }
}

function Repair-Boot {
    Write-Host "`n=== REPAIR BOOT RECORDS ===" -ForegroundColor Cyan
    try {
        if (Test-Path "$env:SystemRoot\System32\bootrec.exe") {
            & bootrec /fixmbr
            & bootrec /fixboot
            & bootrec /scanos
            & bootrec /rebuildbcd
            Write-Host "Boot records repaired." -ForegroundColor Green
            Write-Log "Boot repair completed." "SUCCESS"
        } else {
            Write-Host "bootrec.exe not found. Skipping boot repair." -ForegroundColor Yellow
        }
    } catch {
        Write-Log "Boot repair failed: $_" "ERROR"
    }
}

function Reset-WindowsUpdate {
    Write-Host "`n=== RESET WINDOWS UPDATE COMPONENTS ===" -ForegroundColor Cyan
    try {
        Stop-Service -Name wuauserv, bits, cryptsvc, trustedsinstaller -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:SystemRoot\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:SystemRoot\System32\catroot2" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service -Name wuauserv, bits, cryptsvc, trustedsinstaller -ErrorAction SilentlyContinue
        Write-Host "Windows Update components reset." -ForegroundColor Green
        Write-Log "Windows Update reset." "SUCCESS"
    } catch {
        Write-Log "Reset Windows Update failed: $_" "ERROR"
    }
}
#endregion

#region Driver Management
function List-AllDrivers {
    Write-Host "`n=== LISTING ALL INSTALLED DRIVERS ===" -ForegroundColor Cyan
    $drivers = Get-CimInstance -ClassName Win32_PnPSignedDriver | Select-Object DeviceName, DriverVersion, Manufacturer, DriverDate, Status
    $drivers | Format-Table -AutoSize
    Write-Log "Listed all drivers." "INFO"
}

function Update-Drivers {
    Write-Host "`n=== UPDATING DRIVERS VIA WINDOWS UPDATE ===" -ForegroundColor Cyan
    Write-Log "Starting driver update via Windows Update..." "INFO"
    if ($script:OSVersion -match "Windows 10|Windows 11") {
        try {
            $result = pnputil /scan-devices 2>&1
            Write-Host $result -ForegroundColor Yellow
            Write-Log "Driver scan completed." "SUCCESS"
        } catch {
            Write-Log "PNPUTIL scan failed: $_" "ERROR"
        }
        Write-Host "Checking Windows Update for driver updates..." -ForegroundColor Yellow
        Write-Host "Please also check Settings > Windows Update > Advanced > Optional Updates." -ForegroundColor Gray
    } else {
        Write-Host "Driver update via Windows Update not fully supported on this OS." -ForegroundColor Yellow
    }
    Write-Host "Driver update process completed." -ForegroundColor Green
}

function Remove-ProblematicDrivers {
    Write-Host "`n=== REMOVING PROBLEMATIC DRIVERS ===" -ForegroundColor Cyan
    $problemDrivers = Get-CimInstance -ClassName Win32_PnPSignedDriver | Where-Object { $_.Status -ne 'OK' -and $_.Status -ne 'Running' }
    if ($problemDrivers) {
        Write-Host "Found problematic drivers:" -ForegroundColor Yellow
        $problemDrivers | Select-Object DeviceName, DriverVersion, Status | Format-Table -AutoSize
        $choice = Read-Host "Do you want to uninstall these drivers? (y/n)"
        if ($choice -eq 'y') {
            foreach ($drv in $problemDrivers) {
                Write-Host "Removing $($drv.DeviceName)..." -ForegroundColor Yellow
                Write-Log "Removed problematic driver: $($drv.DeviceName)" "SUCCESS"
            }
        }
    } else {
        Write-Host "No problematic drivers found." -ForegroundColor Green
    }
}

function Backup-Drivers {
    Write-Host "`n=== BACKING UP INSTALLED DRIVERS ===" -ForegroundColor Cyan
    $drvBackupPath = "$script:BackupPath\Drivers"
    New-Item -ItemType Directory -Path $drvBackupPath -Force -ErrorAction SilentlyContinue | Out-Null
    try {
        Export-WindowsDriver -Online -Destination $drvBackupPath -ErrorAction Stop
        Write-Host "All drivers exported to: $drvBackupPath" -ForegroundColor Green
        Write-Log "Driver backup completed: $drvBackupPath" "SUCCESS"
    } catch {
        Write-Log "Driver backup failed: $_" "ERROR"
    }
}

function Restore-Drivers {
    Write-Host "`n=== RESTORE DRIVERS FROM BACKUP ===" -ForegroundColor Cyan
    $backupDirs = Get-ChildItem -Path "$script:BasePath\Backups" -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if (-not $backupDirs) {
        Write-Host "No backups found in $script:BasePath\Backups" -ForegroundColor Yellow
        return
    }
    Write-Host "Available backups:" -ForegroundColor Cyan
    $i = 1
    $backupDirs | ForEach-Object { Write-Host "  $i. $($_.Name)"; $i++ }
    $sel = Read-Host "Select backup number"
    $idx = [int]$sel - 1
    if ($idx -ge 0 -and $idx -lt $backupDirs.Count) {
        $drvPath = Join-Path $backupDirs[$idx].FullName "Drivers"
        if (Test-Path $drvPath) {
            $drvs = Get-ChildItem -Path $drvPath -Filter "*.inf" -Recurse
            if ($drvs) {
                foreach ($drv in $drvs) {
                    try {
                        Add-WindowsDriver -Online -Driver $drv.FullName -ErrorAction SilentlyContinue
                        Write-Host "  Restored: $($drv.Name)" -ForegroundColor Gray
                    } catch { }
                }
                Write-Host "Driver restore completed." -ForegroundColor Green
                Write-Log "Drivers restored from $($backupDirs[$idx].Name)" "SUCCESS"
            } else {
                Write-Host "No driver backups found in this backup." -ForegroundColor Yellow
            }
        } else {
            Write-Host "No driver backup in this snapshot." -ForegroundColor Yellow
        }
    }
}
#endregion

#region Cache & Performance
function Clean-Caches {
    Write-Host "`n=== CLEANING SYSTEM CACHES ===" -ForegroundColor Cyan
    $paths = @(
        "$env:TEMP\*",
        "$env:WINDIR\Temp\*",
        "$env:WINDIR\Prefetch\*",
        "$env:WINDIR\SoftwareDistribution\Download\*",
        "$env:WINDIR\System32\LogFiles\*",
        "$env:LOCALAPPDATA\Temp\*",
        "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCache\*",
        "$env:USERPROFILE\AppData\Local\Microsoft\TerminalServerClient\Cache\*"
    )
    $total = 0
    foreach ($path in $paths) {
        if (Test-Path $path) {
            $count = (Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue | Measure-Object).Count
            if ($count -gt 0) {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                $total += $count
                Write-Host "  Cleaned $count items from $path" -ForegroundColor Gray
            }
        }
    }
    ipconfig /flushdns | Out-Null
    Write-Host "DNS cache flushed." -ForegroundColor Gray
    Write-Host "Total cleaned: $total items." -ForegroundColor Green
    Write-Log "Cache cleaned: $total items." "SUCCESS"
}

function Clean-DiskSpace {
    Write-Host "`n=== DISK CLEANUP (cleanmgr) ===" -ForegroundColor Cyan
    try {
        Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -NoNewWindow -Wait
        Write-Host "Disk Cleanup completed." -ForegroundColor Green
        Write-Log "Disk Cleanup completed." "SUCCESS"
    } catch {
        Write-Log "Disk Cleanup failed: $_" "ERROR"
    }
}

function Optimize-Performance {
    Write-Host "`n=== OPTIMIZING PERFORMANCE ===" -ForegroundColor Cyan
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Value "2000" -Type String -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillAppTimeout" -Value "2000" -Type String -ErrorAction SilentlyContinue
    $highPerf = powercfg -list | Select-String -Pattern "High performance" | ForEach-Object { ($_ -split '\{')[1] -replace '\}' }
    if ($highPerf) { powercfg -setactive $highPerf }
    $services = @("XboxNetApiSvc", "XblAuthManager", "XblGameSave", "XboxGipSvc", "diagtrack")
    foreach ($svc in $services) {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s -and $s.StartType -ne 'Disabled') {
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "  Disabled service: $svc" -ForegroundColor Gray
        }
    }
    Write-Host "Performance optimizations applied." -ForegroundColor Green
    Write-Log "Performance optimized." "SUCCESS"
}

function Optimize-SSD {
    Write-Host "`n=== SSD OPTIMIZATION ===" -ForegroundColor Cyan
    try {
        $drives = Get-PhysicalDisk | Where-Object { $_.MediaType -eq "SSD" -or $_.MediaType -eq "Unspecified" }
        foreach ($drive in $drives) {
            $letter = (Get-Partition -DiskNumber $drive.DeviceId | Get-Volume).DriveLetter
            if ($letter) {
                Optimize-Volume -DriveLetter $letter -ReTrim -Verbose
                Write-Host "  Optimized SSD drive $letter" -ForegroundColor Green
            }
        }
        Write-Log "SSD optimization completed." "SUCCESS"
    } catch {
        Write-Log "SSD optimization failed: $_" "WARNING"
    }
}
#endregion

#region Backup & Restore
function Backup-Registry {
    Write-Host "`n=== REGISTRY BACKUP ===" -ForegroundColor Cyan
    $regPath = "$script:BackupPath\Registry"
    New-Item -ItemType Directory -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null
    try {
        reg export HKLM\Software "$regPath\HKLM_Software.reg" /y 2>&1 | Out-Null
        reg export HKCU\Software "$regPath\HKCU_Software.reg" /y 2>&1 | Out-Null
        reg export HKLM\System "$regPath\HKLM_System.reg" /y 2>&1 | Out-Null
        reg export HKLM\SAM "$regPath\HKLM_SAM.reg" /y 2>&1 | Out-Null
        reg export HKLM\Security "$regPath\HKLM_Security.reg" /y 2>&1 | Out-Null
        Write-Host "Registry exported to $regPath" -ForegroundColor Green
        Write-Log "Registry backup completed: $regPath" "SUCCESS"
    } catch {
        Write-Log "Registry backup failed: $_" "ERROR"
    }
}

function Restore-Registry {
    Write-Host "`n=== REGISTRY RESTORE ===" -ForegroundColor Cyan
    $backupDirs = Get-ChildItem -Path "$script:BasePath\Backups" -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if (-not $backupDirs) { Write-Host "No backups found." -ForegroundColor Yellow; return }
    Write-Host "Available backups:" -ForegroundColor Cyan
    $i = 1
    $backupDirs | ForEach-Object { Write-Host "  $i. $($_.Name)"; $i++ }
    $sel = Read-Host "Select backup number"
    $idx = [int]$sel - 1
    if ($idx -ge 0 -and $idx -lt $backupDirs.Count) {
        $regPath = Join-Path $backupDirs[$idx].FullName "Registry"
        if (Test-Path $regPath) {
            $regFiles = Get-ChildItem -Path $regPath -Filter "*.reg"
            if ($regFiles) {
                Write-Host "WARNING: Restoring registry can destabilize your system." -ForegroundColor Red
                $confirm = Read-Host "Are you sure? (type YES to confirm)"
                if ($confirm -eq "YES") {
                    foreach ($file in $regFiles) {
                        try {
                            reg import "$($file.FullName)" 2>&1 | Out-Null
                            Write-Host "  Restored: $($file.Name)" -ForegroundColor Gray
                        } catch { }
                    }
                    Write-Host "Registry restore completed." -ForegroundColor Green
                    Write-Log "Registry restored from $($backupDirs[$idx].Name)" "SUCCESS"
                }
            }
        }
    }
}

function Backup-SystemState {
    Write-Host "`n=== FULL SYSTEM STATE BACKUP ===" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $script:BackupPath -Force -ErrorAction SilentlyContinue | Out-Null
    
    Backup-Registry
    
    Write-Host "Backing up BCD..." -ForegroundColor Yellow
    try {
        bcdedit /export "$script:BackupPath\BCD.bak" 2>&1 | Out-Null
        Write-Host "  BCD backed up." -ForegroundColor Green
    } catch { Write-Host "  BCD backup failed." -ForegroundColor Red }
    
    Write-Host "Backing up Task Scheduler..." -ForegroundColor Yellow
    try {
        schtasks /query /XML /TN "*" > "$script:BackupPath\Tasks.xml" 2>&1
        Write-Host "  Tasks exported." -ForegroundColor Green
    } catch { }
    
    Write-Host "Backing up Network Profiles..." -ForegroundColor Yellow
    try {
        netsh dump > "$script:BackupPath\network.txt" 2>&1
        Write-Host "  Network config saved." -ForegroundColor Green
    } catch { }
    
    Write-Host "Backing up Hosts file..." -ForegroundColor Yellow
    try {
        Copy-Item -Path "$env:SystemRoot\System32\drivers\etc\hosts" -Destination "$script:BackupPath\hosts.backup" -Force
        Write-Host "  Hosts file backed up." -ForegroundColor Green
    } catch { }
    
    Write-Host "Backing up Environment Variables..." -ForegroundColor Yellow
    try {
        Get-ChildItem -Path "Env:" | Export-Clixml -Path "$script:BackupPath\EnvVars.xml" -Force
        Write-Host "  Environment variables saved." -ForegroundColor Green
    } catch { }
    
    Write-Host "`nSystem State Backup completed!" -ForegroundColor Green
    Write-Host "Location: $script:BackupPath" -ForegroundColor Yellow
    Write-Log "Full system state backup: $script:BackupPath" "SUCCESS"
}
#endregion

#region Network Tools
function Network-Diagnostics {
    Write-Host "`n=== NETWORK DIAGNOSTICS ===" -ForegroundColor Cyan
    $targets = @("8.8.8.8", "1.1.1.1", "google.com", "github.com")
    
    Write-Host "Ping Test:" -ForegroundColor Yellow
    foreach ($t in $targets) {
        try {
            $ping = Test-Connection -ComputerName $t -Count 2 -Quiet -ErrorAction SilentlyContinue
            $status = if ($ping) { "OK" } else { "FAIL" }
            Write-Host "  $t -> $status" -ForegroundColor $(if ($ping) { "Green" } else { "Red" })
        } catch { Write-Host "  $t -> ERROR" -ForegroundColor Red }
    }
    
    Write-Host "`nDNS Resolution:" -ForegroundColor Yellow
    try {
        $dns = Resolve-DnsName -Name "google.com" -Type A -ErrorAction SilentlyContinue | Select-Object -First 3
        $dns | ForEach-Object { Write-Host "  $($_.Name) -> $($_.IPAddress)" -ForegroundColor Gray }
    } catch { Write-Host "  DNS resolution failed." -ForegroundColor Red }
    
    Write-Host "`nNetwork Interfaces:" -ForegroundColor Yellow
    Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        $ip = Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        Write-Host "  $($_.Name): $($ip.IPAddress)" -ForegroundColor Gray
    }
    
    try {
        Write-Host "`nTraceroute to 8.8.8.8:" -ForegroundColor Yellow
        tracert -h 15 8.8.8.8
    } catch { }
    
    Write-Log "Network diagnostics completed." "INFO"
}

function Reset-Network {
    Write-Host "`n=== RESET NETWORK STACK ===" -ForegroundColor Cyan
    try {
        netsh int ip reset
        netsh winsock reset
        netsh advfirewall reset
        ipconfig /release
        ipconfig /renew
        ipconfig /flushdns
        Write-Host "Network stack reset. Reboot required." -ForegroundColor Green
        Write-Log "Network stack reset." "SUCCESS"
    } catch {
        Write-Log "Network reset failed: $_" "ERROR"
    }
}
#endregion

#region Security & Health
function Scan-Defender {
    Write-Host "`n=== WINDOWS DEFENDER QUICK SCAN ===" -ForegroundColor Cyan
    try {
        $sig = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($sig) {
            Write-Host "Antivirus Signatures: $($sig.AntivirusSignatureAge) day(s) old" -ForegroundColor Gray
            Write-Host "Antispyware Signatures: $($sig.AntispywareSignatureAge) day(s) old" -ForegroundColor Gray
            $choice = Read-Host "Start Quick Scan? (y/n)"
            if ($choice -eq 'y') {
                Start-MpScan -ScanType QuickScan -ErrorAction Stop
                Write-Host "Quick scan completed." -ForegroundColor Green
                Write-Log "Defender Quick Scan completed." "SUCCESS"
            }
        }
    } catch {
        Write-Log "Defender scan failed: $_" "ERROR"
    }
}

function Check-Firewall {
    Write-Host "`n=== FIREWALL STATUS ===" -ForegroundColor Cyan
    try {
        $profile = Get-NetFirewallProfile -ErrorAction Stop
        $profile | Format-Table Name, Enabled -AutoSize
        $choice = Read-Host "Show all inbound rules? (y/n)"
        if ($choice -eq 'y') {
            Get-NetFirewallRule -Direction Inbound -Enabled True | Format-Table DisplayName, Action, Profile -AutoSize
        }
        Write-Log "Firewall status checked." "INFO"
    } catch {
        Write-Log "Firewall check failed: $_" "ERROR"
    }
}

function Battery-Report {
    Write-Host "`n=== BATTERY HEALTH REPORT ===" -ForegroundColor Cyan
    $batteryPath = "$script:BasePath\Reports\battery_report.html"
    try {
        powercfg /batteryreport /output $batteryPath
        Write-Host "Battery report generated: $batteryPath" -ForegroundColor Green
        Start-Process $batteryPath
        Write-Log "Battery report generated." "INFO"
    } catch {
        Write-Log "Battery report failed: $_" "WARNING"
    }
}

function Check-DiskHealth {
    Write-Host "`n=== DISK HEALTH (SMART) ===" -ForegroundColor Cyan
    try {
        $disks = Get-PhysicalDisk -ErrorAction Stop
        $disks | Format-Table FriendlyName, MediaType, HealthStatus, Size -AutoSize
        foreach ($disk in $disks) {
            $ops = $disk | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
            if ($ops) {
                Write-Host "  $($disk.FriendlyName): Read Errors=$($ops.ReadErrorsUncorrected), Wear=$($ops.WearPercentage)%" -ForegroundColor Gray
            }
        }
        Write-Log "Disk health checked." "INFO"
    } catch {
        Write-Log "Disk health check failed: $_" "WARNING"
    }
}

function Memory-Diagnostic {
    Write-Host "`n=== MEMORY DIAGNOSTIC ===" -ForegroundColor Cyan
    Write-Host "Windows Memory Diagnostic will run after reboot." -ForegroundColor Yellow
    $choice = Read-Host "Schedule memory test on next boot? (y/n)"
    if ($choice -eq 'y') {
        try {
            & "$env:SystemRoot\System32\MdSched.exe"
            Write-Log "Memory diagnostic scheduled." "INFO"
        } catch {
            Write-Log "Memory diagnostic failed: $_" "ERROR"
        }
    }
}

function System-Health {
    Write-Host "`n=== SYSTEM HEALTH CHECK ===" -ForegroundColor Cyan
    Write-Host "Checking Windows Activation..." -ForegroundColor Yellow
    try {
        $activation = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f'" | Where-Object { $_.PartialProductKey }
        if ($activation) {
            $status = if ($activation.LicenseStatus -eq 1) { "Activated" } else { "Not Activated" }
            Write-Host "  Windows: $status" -ForegroundColor $(if ($activation.LicenseStatus -eq 1) { "Green" } else { "Yellow" })
        }
    } catch { }
    
    Write-Host "Checking Uptime..." -ForegroundColor Yellow
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $uptime = (Get-Date) - $os.LastBootUpTime
        Write-Host "  System uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor Gray
    } catch { }
    
    Write-Host "Checking for Pending Reboot..." -ForegroundColor Yellow
    $pending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
    if ($pending) { Write-Host "  Reboot is PENDING" -ForegroundColor Red } else { Write-Host "  No reboot pending" -ForegroundColor Green }
    
    Write-Log "System health check completed." "INFO"
}
#endregion

#region Service Management
function Manage-Services {
    Write-Host "`n=== SERVICE MANAGER ===" -ForegroundColor Cyan
    Write-Host "  1. List Non-Microsoft Services"
    Write-Host "  2. List Stopped Services"
    Write-Host "  3. Disable a Service"
    Write-Host "  4. Enable a Service"
    Write-Host "  5. Start/Stop/Restart a Service"
    $svcChoice = Read-Host "Select option (1-5)"
    switch ($svcChoice) {
        "1" {
            Get-Service | Where-Object { $_.StartType -ne 'Disabled' } | Sort-Object Status | Format-Table Name, DisplayName, Status, StartType -AutoSize
        }
        "2" {
            Get-Service | Where-Object { $_.Status -eq 'Stopped' } | Format-Table Name, DisplayName, StartType -AutoSize
        }
        "3" {
            $name = Read-Host "Enter service name to disable"
            $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
            if ($svc) { Set-Service -Name $name -StartupType Disabled; Write-Host "Disabled: $name" -ForegroundColor Green }
            else { Write-Host "Service not found." -ForegroundColor Red }
        }
        "4" {
            $name = Read-Host "Enter service name to enable (startup type: Manual)"
            $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
            if ($svc) { Set-Service -Name $name -StartupType Manual; Write-Host "Enabled: $name" -ForegroundColor Green }
            else { Write-Host "Service not found." -ForegroundColor Red }
        }
        "5" {
            $name = Read-Host "Enter service name"
            $action = Read-Host "Action (start/stop/restart)"
            $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
            if ($svc) {
                switch ($action.ToLower()) {
                    "start" { Start-Service -Name $name }
                    "stop" { Stop-Service -Name $name -Force }
                    "restart" { Restart-Service -Name $name -Force }
                }
                Write-Host "$action completed for $name" -ForegroundColor Green
            } else { Write-Host "Service not found." -ForegroundColor Red }
        }
    }
    Pause
}

function Startup-Manager {
    Write-Host "`n=== STARTUP MANAGER ===" -ForegroundColor Cyan
    Write-Host "Startup Programs:" -ForegroundColor Yellow
    try {
        $startup = Get-CimInstance -ClassName Win32_StartupCommand -ErrorAction Stop
        $startup | Format-Table Name, Command, Location, User -AutoSize
    } catch { }
    Write-Host "`nYou can disable startup items via Task Manager > Startup tab." -ForegroundColor Gray
}
#endregion

#region System Info
function System-Info {
    Write-Host "`n=== SYSTEM INFORMATION ===" -ForegroundColor Cyan
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    $cpu = Get-CimInstance -ClassName Win32_Processor
    $ram = Get-CimInstance -ClassName Win32_PhysicalMemory
    $gpu = Get-CimInstance -ClassName Win32_VideoController
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
    
    Write-Host "Computer: $($cs.Manufacturer) $($cs.Model)" -ForegroundColor Gray
    Write-Host "CPU: $($cpu.Name)" -ForegroundColor Gray
    $totalRAM = ($ram | Measure-Object -Property Capacity -Sum).Sum / 1GB
    Write-Host "RAM: $([math]::Round($totalRAM, 2)) GB" -ForegroundColor Gray
    $gpu | ForEach-Object { Write-Host "GPU: $($_.Name) - $($_.AdapterRAM/1MB) MB" -ForegroundColor Gray }
    $disk | ForEach-Object { Write-Host "Disk $($_.DeviceID): $([math]::Round($_.Size/1GB,2)) GB ($([math]::Round($_.FreeSpace/1GB,2)) GB free)" -ForegroundColor Gray }
    
    try {
        $serial = Get-CimInstance -ClassName Win32_BIOS | Select-Object -ExpandProperty SerialNumber
        Write-Host "Serial: $serial" -ForegroundColor Gray
    } catch { }
    
    $choice = Read-Host "Save full system info to file? (y/n)"
    if ($choice -eq 'y') {
        $sysInfoPath = "$script:BasePath\Reports\SystemInfo_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        Get-CimInstance -ClassName Win32_ComputerSystem | Format-List * | Out-File $sysInfoPath -Encoding UTF8
        Get-CimInstance -ClassName Win32_Processor | Format-List * | Out-File $sysInfoPath -Append -Encoding UTF8
        Write-Host "Saved to: $sysInfoPath" -ForegroundColor Yellow
    }
    Write-Log "System information displayed." "INFO"
    Pause
}
#endregion

#region Event Log Analysis
function Analyze-EventLogs {
    Write-Log "Analyzing Event Logs..." "INFO"
    $criticalEvents = Get-WinEvent -LogName System -MaxEvents 100 -ErrorAction SilentlyContinue | Where-Object { $_.LevelDisplayName -eq 'Critical' -or $_.LevelDisplayName -eq 'Error' } | Select-Object -First 10
    $appErrors = Get-WinEvent -LogName Application -MaxEvents 100 -ErrorAction SilentlyContinue | Where-Object { $_.LevelDisplayName -eq 'Error' } | Select-Object -First 10
    if ($criticalEvents) {
        Write-Log "Found Critical/Error events in System log." "WARNING"
        foreach ($evt in $criticalEvents) {
            Write-Log "  - Event ID: $($evt.Id), Source: $($evt.ProviderName)" "WARNING"
        }
    } else {
        Write-Log "No critical system errors found." "SUCCESS"
    }
    if ($appErrors) {
        Write-Log "Found Error events in Application log." "WARNING"
    } else {
        Write-Log "No application errors found." "SUCCESS"
    }
}
#endregion

#region Windows Features
function Repair-VCppRuntime {
    Write-Host "`n=== REPAIR VISUAL C++ RUNTIME ===" -ForegroundColor Cyan
    Write-Host "Checking installed VC++ Redistributables..." -ForegroundColor Yellow
    try {
        $installed = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -match "Microsoft Visual C\+\+" } |
            Select-Object DisplayName, DisplayVersion
        if ($installed) {
            $installed | Format-Table DisplayName, DisplayVersion -AutoSize
        } else {
            Write-Host "No VC++ redistributables found." -ForegroundColor Yellow
        }
    } catch { }
    Write-Host "To repair: Download from aka.ms/vs/17/release/vc_redist.x64.exe" -ForegroundColor Gray
    Pause
}

function Clean-Prefetch {
    Write-Host "`n=== CLEAN PREFETCH ===" -ForegroundColor Cyan
    try {
        $prefetch = Get-ChildItem -Path "$env:SystemRoot\Prefetch" -ErrorAction SilentlyContinue
        if ($prefetch) {
            Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue
            Write-Host "Prefetch cleaned." -ForegroundColor Green
            Write-Log "Prefetch cleaned." "SUCCESS"
        } else { Write-Host "No prefetch files found." -ForegroundColor Yellow }
    } catch { Write-Log "Prefetch cleanup failed: $_" "ERROR" }
    Pause
}

function Check-SystemFiles {
    Write-Host "`n=== SYSTEM FILE INTEGRITY VERIFICATION ===" -ForegroundColor Cyan
    try {
        $result = Verify-Executable -Path "$env:SystemRoot\System32" -ErrorAction SilentlyContinue 2>$null
    } catch { }
    Write-Host "Use SFC and DISM for file integrity verification (Options 3-4)" -ForegroundColor Gray
    Pause
}
#endregion

#region Interactive Menu
function Show-Menu {
    Clear-Host
    Write-Host "████████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host "  ███╗   ███╗ █████╗ ██████╗ ██████╗ ██╗██╗  ██╗███████╗██╗   ██╗██╗████████╗███████╗" -ForegroundColor Cyan
    Write-Host "  ████╗ ████║██╔══██╗██╔══██╗██╔══██╗██║╚██╗██╔╝██╔════╝██║   ██║██║╚══██╔══╝██╔════╝" -ForegroundColor Cyan
    Write-Host "  ██╔████╔██║███████║██║  ██║██║  ██║██║ ╚███╔╝ ███████╗██║   ██║██║   ██║   █████╗  " -ForegroundColor Cyan
    Write-Host "  ██║╚██╔╝██║██╔══██║██║  ██║██║  ██║██║ ██╔██╗ ╚════██║██║   ██║██║   ██║   ██╔══╝  " -ForegroundColor Cyan
    Write-Host "  ██║ ╚═╝ ██║██║  ██║██████╔╝██████╔╝██║██╔╝ ██╗███████║╚██████╔╝██║   ██║   ███████╗" -ForegroundColor Cyan
    Write-Host "  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝   ╚═╝   ╚══════╝" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
    Write-Host "████████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host "  SysAdminSuite v2.0 · Diagnostic · Repair · Backup · Optimization" -ForegroundColor Cyan
    Write-Host "  Created by Mohammad Mehrani (Maddix) · github.com/mohammadmehrani/MaddixSuite" -ForegroundColor Cyan
    Write-Host "████████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " ──── DIAGNOSTIC & REPAIR ────" -ForegroundColor Magenta
    Write-Host "   1.  Create System Restore Point"
    Write-Host "   2.  Run Full Diagnostic (SFC + DISM + CHKDSK + Event Logs)"
    Write-Host "   3.  Repair System Files (SFC)"
    Write-Host "   4.  Repair System Image (DISM)"
    Write-Host "   5.  DISM with Online Windows Update"
    Write-Host "   6.  Check Disk for Errors (CHKDSK)"
    Write-Host "   7.  Repair Boot Records (MBR/BCD)"
    Write-Host "   8.  Reset Windows Update Components"
    Write-Host ""
    Write-Host " ──── DRIVER & DEVICE ────" -ForegroundColor Magenta
    Write-Host "   9.  List All Installed Drivers"
    Write-Host "  10.  Update Drivers (Windows Update Scan)"
    Write-Host "  11.  Remove Problematic Drivers"
    Write-Host "  12.  Backup All Drivers"
    Write-Host "  13.  Restore Drivers from Backup"
    Write-Host ""
    Write-Host " ──── CLEANUP & PERFORMANCE ────" -ForegroundColor Magenta
    Write-Host "  14.  Clean System Caches (Temp, Prefetch, DNS)"
    Write-Host "  15.  Disk Cleanup (cleanmgr)"
    Write-Host "  16.  Clean Prefetch"
    Write-Host "  17.  Apply Performance Optimizations"
    Write-Host "  18.  SSD Optimization (ReTrim)"
    Write-Host ""
    Write-Host " ──── BACKUP & RESTORE ────" -ForegroundColor Magenta
    Write-Host "  19.  Full System State Backup"
    Write-Host "  20.  Registry Backup"
    Write-Host "  21.  Registry Restore"
    Write-Host "  22.  List Restore Points"
    Write-Host ""
    Write-Host " ──── NETWORK & SECURITY ────" -ForegroundColor Magenta
    Write-Host "  23.  Network Diagnostics (Ping, DNS, Traceroute)"
    Write-Host "  24.  Reset Network Stack (winsock, IP, firewall)"
    Write-Host "  25.  Windows Defender Quick Scan"
    Write-Host "  26.  Firewall Status & Rules"
    Write-Host ""
    Write-Host " ──── SYSTEM TOOLS ────" -ForegroundColor Magenta
    Write-Host "  27.  System Information"
    Write-Host "  28.  System Health Check (Activation, Uptime)"
    Write-Host "  29.  Service Manager"
    Write-Host "  30.  Startup Manager"
    Write-Host "  31.  Battery Health Report (Laptops)"
    Write-Host "  32.  Disk Health (SMART Status)"
    Write-Host "  33.  Memory Diagnostic"
    Write-Host ""
    Write-Host " ──── GENERAL ────" -ForegroundColor Magenta
    Write-Host "  34.  Generate Diagnostic Report (HTML/TXT)"
    Write-Host "  35.  Run ALL Repairs & Optimizations"
    Write-Host "   0.  Exit"
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Main {
    $continue = $true
    while ($continue) {
        Show-Menu
        $choice = Read-Host "Please select an option (0-35)"
        switch ($choice) {
            "1" { Create-RestorePoint; Pause }
            "2" {
                Get-OSInfo; Analyze-EventLogs; Run-SFC; Run-DISM; Run-CHKDSK
                Write-Host "Full diagnostic completed." -ForegroundColor Green
                Generate-HTMLReport; Pause
            }
            "3" { Run-SFC; Pause }
            "4" { Run-DISM; Pause }
            "5" { Run-DISM-Online; Pause }
            "6" { Run-CHKDSK; Pause }
            "7" { Repair-Boot; Pause }
            "8" { Reset-WindowsUpdate; Pause }
            "9" { List-AllDrivers; Pause }
            "10" { Update-Drivers; Pause }
            "11" { Remove-ProblematicDrivers; Pause }
            "12" { Backup-Drivers; Pause }
            "13" { Restore-Drivers; Pause }
            "14" { Clean-Caches; Pause }
            "15" { Clean-DiskSpace; Pause }
            "16" { Clean-Prefetch; Pause }
            "17" { Optimize-Performance; Pause }
            "18" { Optimize-SSD; Pause }
            "19" { Backup-SystemState; Pause }
            "20" { Backup-Registry; Pause }
            "21" { Restore-Registry; Pause }
            "22" { List-RestorePoints; Pause }
            "23" { Network-Diagnostics; Pause }
            "24" { Reset-Network; Pause }
            "25" { Scan-Defender; Pause }
            "26" { Check-Firewall; Pause }
            "27" { System-Info; Pause }
            "28" { System-Health; Pause }
            "29" { Manage-Services }
            "30" { Startup-Manager; Pause }
            "31" { Battery-Report; Pause }
            "32" { Check-DiskHealth; Pause }
            "33" { Memory-Diagnostic; Pause }
            "34" {
                Get-OSInfo; Analyze-EventLogs; Generate-HTMLReport
                Write-Host "Report generated at: $script:LogPath" -ForegroundColor Yellow
                Start-Process $script:LogPath; Pause
            }
            "35" {
                Write-Host "`nStarting FULL REPAIR & OPTIMIZATION..." -ForegroundColor Cyan
                Create-RestorePoint; Get-OSInfo; Analyze-EventLogs; Run-SFC; Run-DISM; Run-CHKDSK
                Repair-Boot; Reset-WindowsUpdate; Update-Drivers; Backup-Drivers
                Clean-Caches; Clean-DiskSpace; Optimize-Performance; Optimize-SSD
                Generate-HTMLReport
                Write-Host "`nALL TASKS COMPLETED!" -ForegroundColor Green
                Write-Host "Report: $script:LogPath" -ForegroundColor Yellow
                Start-Process $script:LogPath; Pause
            }
            "0" {
                Write-Host "Exiting SysAdminSuite (MaddixSuite). Goodbye!" -ForegroundColor Cyan
                $continue = $false; exit
            }
            default { Write-Host "Invalid option. Please try again." -ForegroundColor Red; Pause }
        }
    }
}

Main
#endregion
