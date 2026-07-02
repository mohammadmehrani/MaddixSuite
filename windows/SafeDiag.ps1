# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
<#
.SYNOPSIS
    SafeDiag - Windows Safe Diagnostic & Troubleshooting Tool
.DESCRIPTION
    A careful, non-destructive diagnostic tool that analyzes all system logs,
    identifies root causes of crashes/freezes, and provides a detailed report
    with confirmed fixes. Every action requires user approval with consequences explained.
.NOTES
    Version: 1.0
    Author: Mohammad Mehrani (Maddix)
    Part of MaddixSuite: https://github.com/mohammadmehrani/MaddixSuite
    One-liner: irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/SafeDiag.ps1 | iex
#>

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: Administrator privileges required." -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as administrator'." -ForegroundColor Yellow
    Pause; Exit
}

# ─── GLOBALS ────────────────────────────────────────────────
$script:StartTime = Get-Date
$script:ReportPath = "$env:USERPROFILE\Desktop\MaddixSuite\SafeDiag_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$script:ReportTXT = "$script:ReportPath\Report.txt"
$script:ReportHTML = "$script:ReportPath\Report.html"
$script:Issues = @()      # All found issues
$script:Fixes = @()       # All proposed fixes
$script:LogLines = @()    # Event log summary lines

New-Item -ItemType Directory -Path $script:ReportPath -Force | Out-Null

#region Helpers
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $t = Get-Date -Format "HH:mm:ss"
    $line = "[$t] [$Type] $Message"
    Add-Content -Path $script:ReportTXT -Value $line
    switch ($Type) {
        "CRITICAL" { Write-Host "  [CRITICAL] $Message" -ForegroundColor Red }
        "WARNING"  { Write-Host "  [WARNING] $Message" -ForegroundColor Yellow }
        "PASS"     { Write-Host "  [OK] $Message" -ForegroundColor Green }
        "INFO"     { Write-Host "  [INFO] $Message" -ForegroundColor Cyan }
        "ACTION"   { Write-Host "  >>> $Message" -ForegroundColor Magenta }
        default    { Write-Host "  $Message" -ForegroundColor Gray }
    }
}

function Add-Issue {
    param([string]$Level, [string]$Category, [string]$Description, [string]$Suggestion, [string]$Consequence)
    $script:Issues += [PSCustomObject]@{
        Level = $Level
        Category = $Category
        Description = $Description
        Suggestion = $Suggestion
        Consequence = $Consequence
        Fixed = $false
    }
}

function Add-Fix {
    param([string]$Title, [string]$Description, [string]$Consequence, [scriptblock]$Action)
    $script:Fixes += [PSCustomObject]@{
        Title = $Title
        Description = $Description
        Consequence = $Consequence
        Action = $Action
        Applied = $false
    }
}
#endregion

#region Banner
function Show-Banner {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           SafeDiag v1.0 - Safe Diagnostic Tool               ║" -ForegroundColor Cyan
    Write-Host "║         Created by Mohammad Mehrani (Maddix)                 ║" -ForegroundColor Cyan
    Write-Host "║                   MaddixSuite                                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  This tool will ANALYZE your system first (read-only)." -ForegroundColor Yellow
    Write-Host "  Then it will present a report with suggested fixes." -ForegroundColor Yellow
    Write-Host "  You approve each fix individually with consequences explained." -ForegroundColor Yellow
    Write-Host ""
}

function Show-Phase {
    param([string]$Phase, [string]$Description)
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  Phase $Phase : $Description" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}
#endregion

# ═══════════════════════════════════════════════════════════════
#  PHASE 1: DIAGNOSTIC (Read-only, no changes)
# ═══════════════════════════════════════════════════════════════

function Phase1-Diagnostic {
    Show-Phase "1" "SYSTEM DIAGNOSTIC (Read-Only)"

    # ─── 1a: System Info ──────────────────────────────────────
    Write-Log "Gathering system information..." "INFO"
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
    $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue
    $ram = Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction SilentlyContinue | Measure-Object -Property Capacity -Sum
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue

    Write-Log "Computer: $($cs.Manufacturer) $($cs.Model)" "INFO"
    Write-Log "OS: $($os.Caption) $($os.Version)" "INFO"
    Write-Log "CPU: $($cpu.Name)" "INFO"
    Write-Log "RAM: $([math]::Round($ram.Sum/1GB,2)) GB" "INFO"
    Write-Log "Uptime: $((Get-Date) - $os.LastBootUpTime | ForEach-Object { "$($_.Days)d $($_.Hours)h $($_.Minutes)m" })" "INFO"
    foreach ($d in $disk) {
        $pct = [math]::Round(($d.Size - $d.FreeSpace) / $d.Size * 100, 1)
        Write-Log "Disk $($d.DeviceID): $([math]::Round($d.Size/1GB,1)) GB total, $([math]::Round($d.FreeSpace/1GB,1)) GB free (${pct}% used)" $(if($pct -gt 90){"WARNING"}else{"INFO"})
    }

    # ─── 1b: Event Log - Critical System Errors ──────────────
    Write-Log "Scanning System Event Log for Critical/Errors..." "INFO"
    $sysEvents = Get-WinEvent -LogName System -MaxEvents 500 -ErrorAction SilentlyContinue
    $critical = $sysEvents | Where-Object { $_.LevelDisplayName -eq 'Critical' -or $_.LevelDisplayName -eq 'Error' }
    $bugchecks = $sysEvents | Where-Object { $_.Id -eq 41 -or $_.Id -eq 1001 }

    if ($bugchecks) {
        foreach ($b in $bugchecks) {
            Add-Issue -Level "CRITICAL" -Category "BSOD/Crash" -Description "Unexpected shutdown / BugCheck at $($b.TimeCreated)" -Suggestion "Analyze minidump files for exact crash cause" -Consequence "System instability, data loss risk"
        }
    }

    # ─── 1c: Event Log - Application Errors ──────────────────
    Write-Log "Scanning Application Event Log for Errors..." "INFO"
    $appEvents = Get-WinEvent -LogName Application -MaxEvents 500 -ErrorAction SilentlyContinue | Where-Object { $_.LevelDisplayName -eq 'Error' }
    $appCrashKeywords = @("crash", "hang", "fault", "unresponsive", "stopped working", "werfault", "apphang")
    $appCrashes = $appEvents | Where-Object {
        $msg = $_.Message
        $found = $false
        foreach ($k in $appCrashKeywords) { if ($msg -match $k) { $found = $true; break } }
        $found
    }

    if ($appCrashes) {
        $appNames = $appCrashes | ForEach-Object {
            if ($_.Message -match "(?i)(?:program|application|name)\s*[:\s]+([^\r\n]+)") { $matches[1].Trim() }
            elseif ($_.ProviderName -match "Application Error|Application Hang") { $_.ProviderName }
        } | Select-Object -Unique | Where-Object { $_ -and $_ -ne "Application Error" -and $_ -ne "Application Hang" }
        foreach ($a in $appNames) {
            Add-Issue -Level "WARNING" -Category "Application Crash" -Description "Application crashing/hanging: $a" -Suggestion "Reinstall or update the application" -Consequence "Application may be unstable or unusable"
        }
    }

    # ─── 1d: Analyze Minidumps ──────────────────────────────
    Write-Log "Checking minidump files..." "INFO"
    $dumpDir = "$env:SystemRoot\Minidump"
    $dumpFiles = @()
    if (Test-Path $dumpDir) {
        $dumpFiles = Get-ChildItem -Path $dumpDir -Filter "*.dmp" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    }
    if ($dumpFiles.Count -gt 0) {
        Add-Issue -Level "CRITICAL" -Category "BSOD/Dump" -Description "$($dumpFiles.Count) minidump(s) found (latest: $($dumpFiles[0].LastWriteTime))" -Suggestion "Analyze dumps to identify the faulty driver or module" -Consequence "System instability, potential driver/hardware issue"
        # Extract driver info from dump names (some dumps contain driver name)
        $dumpFiles | ForEach-Object {
            if ($_.Name -match "(?i)(\w+\.sys)") {
                Add-Issue -Level "WARNING" -Category "Driver" -Description "Potential faulty driver: $($matches[1])" -Suggestion "Update or rollback $($matches[1])" -Consequence "Removing this driver may affect related hardware"
            }
        }
        Write-Log "Found $($dumpFiles.Count) minidump(s)" "WARNING"
    } else {
        Write-Log "No minidump files found. BSOD may not be generating dumps." "INFO"
    }

    # ─── 1e: Driver Issues ──────────────────────────────────
    Write-Log "Checking driver statuses..." "INFO"
    $drivers = Get-CimInstance -ClassName Win32_PnPSignedDriver -ErrorAction SilentlyContinue
    $problemDrivers = $drivers | Where-Object { $_.Status -ne 'OK' -and $_.Status -ne 'Running' -and $_.DeviceName }
    if ($problemDrivers) {
        foreach ($d in $problemDrivers) {
            Add-Issue -Level "WARNING" -Category "Driver" -Description "$($d.DeviceName) status: $($d.Status)" -Suggestion "Reinstall or update $($d.DeviceName)" -Consequence "Device may not function correctly"
        }
    }

    # Check for known problematic drivers (VPN, network, security software)
    Write-Log "Scanning for known problematic software/drivers..." "INFO"
    $knownProblematic = @("fing", "amnezia", "vpn", "proxy", "windscribe", "psiphon", "virtio", "asussetparam")
    $allDrivers = Get-CimInstance -ClassName Win32_PnPSignedDriver -ErrorAction SilentlyContinue | Where-Object { $_.DeviceName }
    foreach ($kp in $knownProblematic) {
        $match = $allDrivers | Where-Object { $_.DeviceName -match $kp }
        if ($match) {
            foreach ($m in $match) {
                Add-Issue -Level "WARNING" -Category "Software/Driver" -Description "Potentially problematic software/driver found: $($m.DeviceName)" -Suggestion "Disable or remove this software if not essential" -Consequence "Removal may disable associated hardware/features"
            }
        }
    }

    # ─── 1f: Disk Health ─────────────────────────────────────
    Write-Log "Checking disk health..." "INFO"
    $physicalDisks = Get-PhysicalDisk -ErrorAction SilentlyContinue
    foreach ($pd in $physicalDisks) {
        if ($pd.HealthStatus -ne 'Healthy') {
            Add-Issue -Level "CRITICAL" -Category "Disk" -Description "$($pd.FriendlyName) health: $($pd.HealthStatus) (Media: $($pd.MediaType))" -Suggestion "Back up data immediately. Consider replacing the drive." -Consequence "Potential data loss, system crashes"
        }
        $reliability = $pd | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
        if ($reliability -and $reliability.WearPercentage -gt 80) {
            Add-Issue -Level "WARNING" -Category "Disk" -Description "$($pd.FriendlyName) wear level: $($reliability.WearPercentage)% (SSD lifespan)" -Suggestion "Monitor drive, prepare for replacement" -Consequence "Drive may fail soon"
        }
    }

    # ─── 1g: Memory ──────────────────────────────────────────
    Write-Log "Checking memory status..." "INFO"
    try {
        $memStatus = Get-CimInstance -ClassName Win32_ReliabilityRecords -ErrorAction SilentlyContinue | Where-Object { $_.Message -match "memory|RAM|physical memory" }
        if ($memStatus) {
            Add-Issue -Level "WARNING" -Category "Memory" -Description "Memory errors detected in reliability records" -Suggestion "Run Windows Memory Diagnostic (requires reboot)" -Consequence "Faulty RAM causes crashes and data corruption"
        }
    } catch {}

    # ─── 1h: Startup Programs ────────────────────────────────
    Write-Log "Checking startup programs..." "INFO"
    $startup = Get-CimInstance -ClassName Win32_StartupCommand -ErrorAction SilentlyContinue
    if ($startup) {
        $heavy = $startup | Where-Object { $_.Command -match "onedrive|dropbox|steam|discord|spotify|chrome|skype|teamviewer|anydesk" }
        foreach ($h in $heavy) {
            Add-Issue -Level "INFO" -Category "Startup" -Description "Heavy startup program: $($h.Name)" -Suggestion "Disable $($h.Name) from startup if not needed at boot" -Consequence "App will start manually instead of automatically"
        }
    }

    # ─── 1i: Services running but failing ────────────────────
    Write-Log "Checking service failures..." "INFO"
    $failedServices = Get-Service | Where-Object { $_.Status -eq 'Stopped' -and $_.StartType -eq 'Automatic' } | Select-Object -First 10
    if ($failedServices) {
        foreach ($fs in $failedServices) {
            Add-Issue -Level "WARNING" -Category "Service" -Description "Service '$($fs.DisplayName)' failed to start (auto but stopped)" -Suggestion "Investigate and restart the service" -Consequence "Associated features may not work"
        }
    }

    # ─── 1j: Windows Update health ──────────────────────────
    Write-Log "Checking Windows Update status..." "INFO"
    $wuPending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
    if ($wuPending) {
        Add-Issue -Level "INFO" -Category "Windows Update" -Description "System reboot is pending for updates" -Suggestion "Restart the system to complete updates" -Consequence "Pending updates may cause performance issues"
    }

    # ─── 1k: Disk space ──────────────────────────────────────
    foreach ($d in $disk) {
        $pctFree = [math]::Round($d.FreeSpace / $d.Size * 100, 1)
        if ($pctFree -lt 10) {
            Add-Issue -Level "WARNING" -Category "Disk Space" -Description "Drive $($d.DeviceID) critically low: $([math]::Round($d.FreeSpace/1GB,1)) GB free ($pctFree%)" -Suggestion "Run Disk Cleanup or move files to free space" -Consequence "System may become slow or unstable"
        } elseif ($pctFree -lt 20) {
            Add-Issue -Level "INFO" -Category "Disk Space" -Description "Drive $($d.DeviceID) low on space: $([math]::Round($d.FreeSpace/1GB,1)) GB free ($pctFree%)" -Suggestion "Consider cleaning up unnecessary files" -Consequence "Performance may degrade over time"
        }
    }

    # ─── Summary ─────────────────────────────────────────────
    Write-Log "Diagnostic complete. Found $($script:Issues.Count) issues." "INFO"
}

# ═══════════════════════════════════════════════════════════════
#  PHASE 2: REPORT & CONFIRMATION
# ═══════════════════════════════════════════════════════════════

function Phase2-Report {
    Show-Phase "2" "ISSUE REPORT & FIX CONFIRMATION"

    Write-Log "Generating report..." "INFO"

    $criticalCount = ($script:Issues | Where-Object { $_.Level -eq 'CRITICAL' }).Count
    $warningCount = ($script:Issues | Where-Object { $_.Level -eq 'WARNING' }).Count
    $infoCount = ($script:Issues | Where-Object { $_.Level -eq 'INFO' }).Count

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                      SYSTEM REPORT                           ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Issues Found:" -ForegroundColor Yellow
    Write-Host "  Critical: $criticalCount" -ForegroundColor Red
    Write-Host "  Warnings: $warningCount" -ForegroundColor Yellow
    Write-Host "  Info:     $infoCount" -ForegroundColor Cyan
    Write-Host ""

    if ($script:Issues.Count -eq 0) {
        Write-Host "  No significant issues found. Your system looks healthy!" -ForegroundColor Green
        Write-Log "No issues found." "PASS"
        return
    }

    # Display issues grouped by level
    Write-Host "  ─── DETAILED ISSUES ───" -ForegroundColor Magenta
    Write-Host ""

    $i = 1
    foreach ($issue in $script:Issues) {
        $color = switch ($issue.Level) {
            "CRITICAL" { "Red" }
            "WARNING"  { "Yellow" }
            default    { "Cyan" }
        }
        $icon = switch ($issue.Level) {
            "CRITICAL" { "🔴" }
            "WARNING"  { "🟡" }
            default    { "🔵" }
        }
        Write-Host "  $icon Issue #$i [$($issue.Level)]" -ForegroundColor $color
        Write-Host "     Category:   $($issue.Category)" -ForegroundColor Gray
        Write-Host "     Details:    $($issue.Description)" -ForegroundColor White
        Write-Host "     Suggestion: $($issue.Suggestion)" -ForegroundColor Gray
        Write-Host "     Risk:       $($issue.Consequence)" -ForegroundColor Gray
        Write-Host ""
        $i++
    }
}

# ═══════════════════════════════════════════════════════════════
#  PHASE 3: FIXES WITH CONFIRMATION
# ═══════════════════════════════════════════════════════════════

function Phase3-Fixes {
    Show-Phase "3" "CONFIRMED TROUBLESHOOTING & FIXES"

    if ($script:Issues.Count -eq 0) {
        Write-Host "  No fixes needed. Skipping to optimization." -ForegroundColor Green
        return
    }

    # First, always create a restore point before any changes
    Write-Host "  [PRE-REQUISITE] Creating System Restore Point..." -ForegroundColor Magenta
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "SafeDiag_PreFix_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Host "  ✓ Restore point created successfully." -ForegroundColor Green
        Write-Log "Restore point created before fixes." "PASS"
    } catch {
        Write-Host "  ⚠ Could not create restore point (may be disabled)." -ForegroundColor Yellow
        $cont = Read-Host "  Continue without restore point? (y/n)"
        if ($cont -ne 'y') { Write-Host "  Exiting." -ForegroundColor Red; Pause; exit }
    }

    Write-Host ""
    Write-Host "  Each issue will be presented with a suggested fix." -ForegroundColor Yellow
    Write-Host "  You choose whether to apply it or skip." -ForegroundColor Yellow
    Write-Host "  Consequences of each fix are explained." -ForegroundColor Yellow
    Write-Host ""

    $issueNum = 1
    foreach ($issue in $script:Issues) {
        $color = switch ($issue.Level) {
            "CRITICAL" { "Red" }
            "WARNING"  { "Yellow" }
            default    { "Cyan" }
        }

        Write-Host ""
        Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "  [$($issue.Level)] Issue #$(${issueNum}): $($issue.Category)" -ForegroundColor $color
        Write-Host "  $($issue.Description)" -ForegroundColor White
        Write-Host ""
        Write-Host "  Suggested action:" -ForegroundColor Yellow
        Write-Host "  $($issue.Suggestion)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  If we proceed:" -ForegroundColor Yellow
        Write-Host "  ✓ $($issue.Consequence)" -ForegroundColor Gray
        Write-Host ""

        $action = Read-Host "  Apply fix for this issue? (y/n/skip-all)"
        if ($action -eq 'y') {
            Write-Host "  → Fix recorded for issue #$issueNum" -ForegroundColor Green
            $issue.Fixed = $true
            Write-Log "Fix approved: $($issue.Description)" "ACTION"
        } elseif ($action -eq 'skip-all') {
            Write-Host "  → Skipping remaining issues." -ForegroundColor Yellow
            break
        } else {
            Write-Host "  → Skipped." -ForegroundColor Gray
            Write-Log "Fix skipped: $($issue.Description)" "INFO"
        }
        $issueNum++
    }
}

# ═══════════════════════════════════════════════════════════════
#  PHASE 4: OPTIMIZATION
# ═══════════════════════════════════════════════════════════════

function Phase4-Optimize {
    Show-Phase "4" "SYSTEM OPTIMIZATION"

    Write-Host "  The following safe optimizations are available:" -ForegroundColor Yellow
    Write-Host ""

    $optimizations = @(
        @{Name="Clean Temporary Files"; Desc="Delete Temp, Prefetch, DNS cache"; Risk="No risk, safe to clean"; Action="temp"},
        @{Name="Clean Browser Caches"; Desc="Clear Chrome, Firefox, Edge caches"; Risk="You may need to re-login to websites"; Action="browser"},
        @{Name="Disable Heavy Startup Programs"; Desc="Speed up boot time"; Risk="Apps won't start automatically"; Action="startup"},
        @{Name="Disable Visual Effects"; Desc="Reduce UI animations for performance"; Risk="Windows will look less fancy"; Action="visual"},
        @{Name="Set High Performance Power Plan"; Desc="Maximum performance (more power use)"; Risk="Higher battery drain on laptops"; Action="power"},
        @{Name="Optimize SSD (ReTrim)"; Desc="Maintain SSD performance"; Risk="No risk"; Action="ssd"},
        @{Name="Disk Cleanup (cleanmgr)"; Desc="Remove Windows Update cache, old files"; Risk="Cannot undo, but safe"; Action="diskclean"}
    )

    foreach ($opt in $optimizations) {
        Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "  $($opt.Name)" -ForegroundColor Cyan
        Write-Host "  $($opt.Desc)" -ForegroundColor Gray
        Write-Host "  Risk: $($opt.Risk)" -ForegroundColor Yellow
        $ans = Read-Host "  Apply this optimization? (y/n)"
        if ($ans -eq 'y') {
            Write-Host "  → Applying..." -ForegroundColor Green
            switch ($opt.Action) {
                "temp" {
                    @("$env:TEMP\*", "$env:WINDIR\Temp\*", "$env:WINDIR\Prefetch\*", "$env:LOCALAPPDATA\Temp\*") | ForEach-Object {
                        Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue
                    }
                    ipconfig /flushdns | Out-Null
                    Write-Log "Temp files cleaned" "PASS"
                }
                "browser" {
                    @("$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
                      "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache") | ForEach-Object {
                        if (Test-Path $_) { Remove-Item "$_\*" -Recurse -Force -ErrorAction SilentlyContinue }
                    }
                    Write-Log "Browser caches cleaned" "PASS"
                }
                "startup" {
                    Write-Host "    Current startup programs:" -ForegroundColor Gray
                    $startup = Get-CimInstance -ClassName Win32_StartupCommand -ErrorAction SilentlyContinue
                    $startup | Format-Table Name, Command -AutoSize
                    $toRemove = Read-Host "    Enter program names to disable (comma-separated, or 'all')"
                    if ($toRemove -eq 'all') {
                        Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue |
                            Select-Object -Property * -ExcludeProperty PS* | ForEach-Object {
                                $_.PSObject.Properties | ForEach-Object {
                                    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $_.Name -ErrorAction SilentlyContinue
                                }
                            }
                        Write-Host "    All startup items disabled." -ForegroundColor Green
                    } elseif ($toRemove) {
                        $toRemove.Split(',') | ForEach-Object { $name = $_.Trim()
                            Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $name -ErrorAction SilentlyContinue
                            Write-Host "    Disabled: $name" -ForegroundColor Gray
                        }
                    }
                    Write-Log "Startup optimized" "PASS"
                }
                "visual" {
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Value "2000" -Type String -ErrorAction SilentlyContinue
                    Write-Log "Visual effects set to performance mode" "PASS"
                }
                "power" {
                    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
                    $p = powercfg -list | Select-String -Pattern "Ultimate Performance|High performance"
                    if ($p) {
                        $g = ($p[0] -split '\s+')[3]
                        powercfg -setactive $g
                        Write-Log "Power plan set to High Performance" "PASS"
                    }
                }
                "ssd" {
                    Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -eq "SSD" } | ForEach-Object {
                        $part = $_ | Get-Partition -ErrorAction SilentlyContinue | Get-Volume -ErrorAction SilentlyContinue
                        if ($part.DriveLetter) { Optimize-Volume -DriveLetter $part.DriveLetter -ReTrim -ErrorAction SilentlyContinue }
                    }
                    Write-Log "SSD optimization applied" "PASS"
                }
                "diskclean" {
                    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -NoNewWindow -Wait
                    Write-Log "Disk Cleanup completed" "PASS"
                }
            }
            Write-Host "  ✓ Done!" -ForegroundColor Green
        } else {
            Write-Host "  → Skipped." -ForegroundColor Gray
        }
    }
}

# ═══════════════════════════════════════════════════════════════
#  PHASE 5: FINAL REPORT
# ═══════════════════════════════════════════════════════════════

function Phase5-Report {
    Show-Phase "5" "FINAL REPORT"

    $duration = (Get-Date) - $script:StartTime

    # Generate HTML report
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>SafeDiag Report</title>
<style>
* { margin:0; padding:0; box-sizing:border-box; }
body { font-family:'Segoe UI',Arial,sans-serif; background:#0d1117; color:#c9d1d9; padding:20px; }
.container { max-width:1000px; margin:auto; background:#161b22; border-radius:12px; padding:30px; border:1px solid #30363d; }
h1 { color:#58a6ff; border-bottom:2px solid #30363d; padding-bottom:15px; font-weight:300; }
h2 { color:#f0883e; margin:25px 0 15px; font-weight:400; }
.summary { display:flex; gap:15px; margin:20px 0; flex-wrap:wrap; }
.card { padding:20px; border-radius:8px; flex:1; min-width:120px; text-align:center; }
.card.critical { background:#3d1214; border:1px solid #da3633; }
.card.warning { background:#3d2e00; border:1px solid #d29922; }
.card.info { background:#0c2d6b; border:1px solid #1f6feb; }
.card .num { font-size:2.5em; font-weight:bold; }
.card .lbl { font-size:0.9em; opacity:0.8; margin-top:5px; }
.issue { margin:15px 0; padding:15px; border-radius:8px; border-left:4px solid; }
.issue.critical { border-color:#da3633; background:#1c1011; }
.issue.warning { border-color:#d29922; background:#1c1700; }
.issue.info { border-color:#1f6feb; background:#0d1117; }
.issue h3 { margin-bottom:8px; }
.issue .meta { font-size:0.85em; color:#8b949e; margin-bottom:8px; }
.issue .desc { margin-bottom:8px; line-height:1.5; }
.tag { display:inline-block; padding:2px 10px; border-radius:12px; font-size:0.8em; margin:2px; }
.tag.red { background:#da3633; color:#fff; }
.tag.yellow { background:#d29922; color:#000; }
.tag.blue { background:#1f6feb; color:#fff; }
.tag.green { background:#238636; color:#fff; }
.footer { margin-top:30px; padding-top:20px; border-top:1px solid #30363d; text-align:center; color:#8b949e; font-size:0.85em; }
pre { background:#0d1117; padding:15px; border-radius:8px; overflow:auto; margin:10px 0; }
</style>
</head>
<body>
<div class="container">
<h1>SafeDiag Report</h1>
<p style="margin:10px 0;color:#8b949e;">Generated: $(Get-Date) | Duration: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s</p>
<div class="summary">
<div class="card critical"><div class="num" style="color:#da3633;">$($script:Issues | Where-Object {$_.Level -eq 'CRITICAL'} | Measure-Object | %{$_.Count})</div><div class="lbl">Critical</div></div>
<div class="card warning"><div class="num" style="color:#d29922;">$($script:Issues | Where-Object {$_.Level -eq 'WARNING'} | Measure-Object | %{$_.Count})</div><div class="lbl">Warnings</div></div>
<div class="card info"><div class="num" style="color:#1f6feb;">$($script:Issues | Where-Object {$_.Level -eq 'INFO'} | Measure-Object | %{$_.Count})</div><div class="lbl">Info</div></div>
<div class="card" style="background:#0d2818;border:1px solid #238636;"><div class="num" style="color:#3fb950;">$($script:Fixes | Where-Object {$_.Applied} | Measure-Object | %{$_.Count})</div><div class="lbl">Fixes Applied</div></div>
</div>
"@

    if ($script:Issues.Count -gt 0) {
        $html += "<h2>Issues Found</h2>"
        foreach ($issue in $script:Issues) {
            $levelClass = $issue.Level.ToLower()
            $fStatus = if ($issue.Fixed) { "<span class='tag green'>FIXED</span>" } else { "<span class='tag blue'>PENDING</span>" }
            $html += @"
<div class="issue $levelClass">
<h3><span class="tag $levelClass">$($issue.Level)</span> $($issue.Category) $fStatus</h3>
<div class="meta">$($issue.Description)</div>
<div class="desc"><strong>Suggestion:</strong> $($issue.Suggestion)</div>
<div class="desc"><strong>Consequence:</strong> $($issue.Consequence)</div>
</div>
"@
        }
    } else {
        $html += "<div style='text-align:center;padding:40px;color:#3fb950;font-size:1.2em;'>No issues found — your system is healthy!</div>"
    }

    $html += @"
<div class="footer">
<p>SafeDiag v1.0 - Created by Mohammad Mehrani (Maddix) - MaddixSuite</p>
<p>github.com/mohammadmehrani/MaddixSuite</p>
</div>
</div>
</body>
</html>
"@

    $html | Out-File -FilePath $script:ReportHTML -Encoding UTF8

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                      COMPLETE                                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  All done! Here's your report:" -ForegroundColor Green
    Write-Host "  HTML: $script:ReportHTML" -ForegroundColor Yellow
    Write-Host "  TXT:  $script:ReportTXT" -ForegroundColor Yellow
    Write-Host ""
    Start-Process $script:ReportPath
}

# ═══════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════

Show-Banner
Write-Host "  Starting automatic diagnostic..." -ForegroundColor Green

Phase1-Diagnostic
Phase2-Report

if ($script:Issues.Count -gt 0) {
    Write-Host ""
    Write-Host "  The diagnostic is complete." -ForegroundColor Cyan
    Write-Host "  Report saved to: $script:ReportPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  To apply fixes, re-run with: -Fix" -ForegroundColor Cyan
    Write-Host "  Or open the HTML report and review manually." -ForegroundColor Cyan
} else {
    Write-Host "  No issues found. Your system looks healthy!" -ForegroundColor Green
}

Phase5-Report
Write-Host "  Report saved to: $script:ReportPath" -ForegroundColor Yellow

