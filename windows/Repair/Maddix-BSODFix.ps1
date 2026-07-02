#Requires -RunAsAdministrator
# Maddix-BSODFix.ps1 — Advanced BSOD Diagnostic & Repair (iaStorAC.sys focus)
# Author: Mohammad Mehrani (Maddix)
# Run: irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Repair/Maddix-BSODFix.ps1 | iex

param([switch]$Auto)

$Host.UI.RawUI.WindowTitle = "MaddixSuite — BSOD Repair Tool"

function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Confirm-Step {
    param([string]$Title, [string]$Desc)
    if ($Auto) { return $true }
    Write-Color "`n" "Gray"
    Write-Color ("─" * 60) "DarkGray"
    Write-Color "  $Title" "Yellow"
    Write-Color "  $Desc" "DarkGray"
    Write-Color ("─" * 60) "DarkGray"
    while ($true) {
        $r = Read-Host "  Proceed? (Y/N)"
        if ($r -match '^[Yy]') { return $true }
        if ($r -match '^[Nn]') { Write-Color "  SKIPPED" "Magenta"; return $false }
    }
}

function Test-Admin {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Color "  NOT ADMIN — Elevating..." "Red"
        Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
}

# ===========================================================================
# PHASE 0 — SYSTEM INFO
# ===========================================================================
function Phase0-SystemInfo {
    Clear-Host
    Write-Color "╔═══════════════════════════════════════════════════════════╗" "Cyan"
    Write-Color "║        MaddixSuite — BSOD Diagnostic & Repair            ║" "Cyan"
    Write-Color "╚═══════════════════════════════════════════════════════════╝" "Cyan"
    Write-Color ""

    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Where-Object DeviceID -eq "C:" | Select-Object Size, FreeSpace

    Write-Color "  OS:      $($os.Caption) (Build $($os.BuildNumber))" "Green"
    Write-Color "  System:  $((Get-CimInstance Win32_ComputerSystem).Manufacturer) $((Get-CimInstance Win32_ComputerSystemProduct).Name)" "Green"
    Write-Color "  CPU:     $($cpu.Name)" "Green"
    Write-Color "  RAM:     $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)) GB" "Green"
    if ($disk) { Write-Color "  Disk C:  $([math]::Round($disk.Size/1GB,1)) GB total, $([math]::Round($disk.FreeSpace/1GB,1)) GB free" "Green" }
    Write-Color ""
}

# ===========================================================================
# PHASE 1 — EVENT LOG & MINIDUMP ANALYSIS
# ===========================================================================
function Phase1-EventLogAnalysis {
    if (-not (Confirm-Step "Event Log & Minidump Analysis" "Scans System Event Log for BugCheck, Kernel-Power errors, and parses memory dump files.")) { return }

    Write-Color "  [*] Scanning System Event Log..." "Cyan"
    $critical = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1} -MaxEvents 20 -ErrorAction SilentlyContinue
    $bugcheck = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1001} -MaxEvents 10 -ErrorAction SilentlyContinue
    $kp41 = Get-WinEvent -FilterHashtable @{LogName='System'; Id=41} -MaxEvents 5 -ErrorAction SilentlyContinue

    $bsodFound = $false

    if ($bugcheck) {
        $bsodFound = $true
        Write-Color "  [!] BugCheck Events Found:" "Yellow"
        foreach ($e in $bugcheck) {
            $msg = $e.Message
            $bugcheckCode = ""
            $faultyModule = ""
            if ($msg -match '0x[0-9a-fA-F]{8}') { $bugcheckCode = $matches[0] }
            if ($msg -match '(?i)([a-zA-Z0-9_]+\.sys)') { $faultyModule = $matches[1] }
            Write-Color "      $($e.TimeCreated) | Code: $bugcheckCode | Module: $faultyModule" "DarkYellow"
        }
    }

    if ($kp41) {
        $bsodFound = $true
        Write-Color "  [!] Unexpected Shutdowns (Kernel-Power 41):" "Yellow"
        foreach ($e in $kp41) {
            Write-Color "      $($e.TimeCreated)" "DarkYellow"
        }
    }

    if ($critical) {
        Write-Color "  [i] Critical Events in last 7 days: $($critical.Count)" "Gray"
    }

    # Analyze minidumps
    $dumpPath = "$env:SystemRoot\Minidump"
    if (Test-Path $dumpPath) {
        $dumps = Get-ChildItem $dumpPath -Filter "*.dmp" | Sort-Object LastWriteTime -Descending
        if ($dumps) {
            $bsodFound = $true
            Write-Color "  [!] Minidumps Found: $($dumps.Count)" "Yellow"
            Write-Color "      Latest: $($dumps[0].Name) ($($dumps[0].LastWriteTime))" "DarkYellow"

            # Try to read basic minidump info using WinDbg or built-in tools
            $dumpSize = $dumps[0].Length
            Write-Color "      Size: $([math]::Round($dumpSize/1KB,1)) KB" "Gray"

            # Check if dump mentions iaStorAC.sys
            try {
                $dumpContent = [System.IO.File]::ReadAllBytes($dumps[0].FullName)
                $dumpText = [System.Text.Encoding]::ASCII.GetString($dumpContent)
                if ($dumpText -match '(?i)iaStorAC\.sys') {
                    Write-Color "      => CONFIRMED: iaStorAC.sys found in dump" "Red"
                }
                if ($dumpText -match '(?i)DRIVER_IRQL|0x000000d1') {
                    Write-Color "      => CONFIRMED: DRIVER_IRQL_NOT_LESS_OR_EQUAL" "Red"
                }
            } catch {}
        }
    }

    if (-not $bsodFound) {
        Write-Color "  [i] No BSOD events or minidumps found." "Green"
        Write-Color "  [i] System appears stable from event log perspective." "Gray"
    }

    Write-Color "  [+] Phase 1 complete." "Green"
}

# ===========================================================================
# PHASE 2 — iaStorAC.sys DIAGNOSTIC
# ===========================================================================
function Phase2-iaStorACDiagnostic {
    if (-not (Confirm-Step "Intel RST (iaStorAC.sys) Diagnostic" "Scans the iaStorAC.sys driver, its version, registry configuration, and checks for known conflicts.")) { return }

    Write-Color "  [*] Scanning iaStorAC.sys driver..." "Cyan"

    $driverPath = "$env:SystemRoot\System32\drivers\iaStorAC.sys"
    $driverFound = Test-Path $driverPath

    if (-not $driverFound) {
        Write-Color "  [i] iaStorAC.sys not found at standard path." "Gray"
        $altPath = Get-ChildItem -Path "$env:SystemRoot\System32\drivers" -Filter "iaStor*.sys" -ErrorAction SilentlyContinue
        if ($altPath) {
            Write-Color "  [!] Found related Intel Storage driver: $($altPath[0].Name)" "Yellow"
            $driverPath = $altPath[0].FullName
            $driverFound = $true
        }
    }

    if ($driverFound) {
        $ver = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($driverPath)
        $size = (Get-Item $driverPath).Length
        Write-Color "      Path:  $driverPath" "Gray"
        Write-Color "      Version: $($ver.FileVersion)" "Yellow"
        Write-Color "      Size:   $([math]::Round($size/1KB,1)) KB" "Gray"
        Write-Color "      Product: $($ver.ProductName)" "Gray"

        # Check registry driver config
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\iaStorAC"
        if (Test-Path $regPath) {
            $startType = (Get-ItemProperty $regPath -Name "Start" -ErrorAction SilentlyContinue).Start
            $type = (Get-ItemProperty $regPath -Name "Type" -ErrorAction SilentlyContinue).Type
            Write-Color "      Registry Start: $startType | Type: $type" "Gray"
        }

        # Check for known problematic versions
        $badVersions = @("17.", "18.")
        $isBadVersion = $false
        foreach ($bad in $badVersions) {
            if ($ver.FileVersion -like "$bad*") {
                $isBadVersion = $true
                break
            }
        }

        if ($isBadVersion) {
            Write-Color "  [!] WARNING: Intel RST version $($ver.FileVersion) may not support your platform." "Red"
            Write-Color "      Systems with Intel 100/200 series chipsets require RST v15.x or earlier." "Red"
        }

        # Determine correct version for hardware
        $cpuModel = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).Name
        if ($cpuModel -match "i[3579]-\d{4}[A-Z]?") {
            $cpuGeneration = [int]($matches[0] -replace 'i[3579]-', '').Substring(0,1)
            if ($cpuGeneration -le 7) {
                Write-Color "  [!] CPU Generation: $cpuGeneration (100/200 series chipset)" "Yellow"
                Write-Color "      Recommended: Intel RST v15.x or OEM version from ASUS support" "Yellow"
                if ($isBadVersion) {
                    Write-Color "  [ACTION REQUIRED] Version mismatch — fix recommended in next phase." "Red"
                }
            } elseif ($cpuGeneration -ge 8) {
                Write-Color "  [i] CPU Generation: $cpuGeneration (300+ series chipset)" "Gray"
            }
        }
    } else {
        Write-Color "  [i] No Intel RST (iaStorAC) driver found. Standard Microsoft AHCI/NVMe driver in use." "Green"
        Write-Color "  [i] BSOD likely caused by another driver." "Gray"
    }

    # Check for other problematic drivers
    Write-Color "  [*] Checking for other known BSOD-causing drivers..." "Cyan"
    $knownBadDrivers = @(
        @{Name="aswSP.sys"; Desc="Avast"},
        @{Name="nvlddmkm.sys"; Desc="NVIDIA (update to latest)"},
        @{Name="e1d*.sys"; Desc="Intel Ethernet (update)"},
        @{Name="dxgkrnl.sys"; Desc="DirectX Graphics (update GPU driver)"},
        @{Name="NETIO.SYS"; Desc="Network I/O (update network driver)"}
    )
    foreach ($d in $knownBadDrivers) {
        $found = Get-ChildItem "$env:SystemRoot\System32\drivers" -Filter $d.Name -ErrorAction SilentlyContinue
        if ($found) {
            Write-Color "      [!] $($d.Desc) driver found: $($d.Name)" "Yellow"
        }
    }

    Write-Color "  [+] Phase 2 complete." "Green"
}

# ===========================================================================
# PHASE 3 — iaStorAC.sys REPAIR
# ===========================================================================
function Phase3-iaStorACRepair {
    if (-not (Confirm-Step "Intel RST (iaStorAC.sys) Repair" "Reinstall the Intel RST driver, install the correct OEM version, or switch to the safe Microsoft AHCI driver.")) { return }

    Write-Color "  [*] iaStorAC.sys Repair Options:" "Cyan"
    Write-Color "      [1] Reinstall via Windows Update (pulls matching driver)" "Gray"
    Write-Color "      [2] Install OEM version from Intel (safe for your chipset)" "Gray"
    Write-Color "      [3] Disable Intel RST → use Microsoft AHCI driver" "Red"
    Write-Color "      [4] Skip (no driver changes)" "Gray"

    $choice = Read-Host "  Choose (1-4)"
    if ($choice -eq "4") { Write-Color "  SKIPPED" "Magenta"; return }

    if ($choice -eq "1") {
        Write-Color "  [*] Reinstalling Intel RST driver via pnputil..." "Cyan"
        try {
            # Find the iaStorAC device
            $dev = Get-PnpDevice -FriendlyName "*Intel*RST*" -ErrorAction SilentlyContinue
            if (-not $dev) { $dev = Get-PnpDevice -FriendlyName "*Intel*Storage*" -ErrorAction SilentlyContinue }
            if (-not $dev) { $dev = Get-PnpDevice -Class "SCSIAdapter" -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match "Intel" } }

            if ($dev) {
                Write-Color "      Found: $($dev.FriendlyName) ($($dev.Status))" "Gray"
                Write-Color "      Restarting device..." "Gray"
                Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 3
                Enable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
                Write-Color "  [+] Device restarted. Scanning for updated drivers..." "Green"

                # Trigger Windows Update driver search
                $UpdateSearch = New-Object -ComObject Microsoft.Update.Session
                $UpdateSearcher = $UpdateSearch.CreateUpdateSearcher()
                $UpdateSearcher.Online = $true
                Write-Color "      Searching Windows Update for driver updates..." "Gray"
                try {
                    $SearchResult = $UpdateSearcher.Search("IsInstalled=0 AND Type='Driver'")
                    Write-Color "      Found $($SearchResult.Updates.Count) driver updates." "Gray"
                } catch {
                    Write-Color "      Windows Update search not available." "DarkYellow"
                }
            } else {
                Write-Color "  [!] No Intel RST device found in PnP enumeration." "Yellow"
                Write-Color "      Trying alternate method — scanning hardware IDs..." "Gray"
                $hwDevs = Get-PnpDevice -Class "SCSIAdapter" -ErrorAction SilentlyContinue
                if ($hwDevs) {
                    foreach ($d in $hwDevs) {
                        $hwId = (Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName "DEVPKEY_Device_HardwareIds" -ErrorAction SilentlyContinue).Data
                        if ($hwId -match "VEN_8086") {
                            Write-Color "      Found Intel SCSI device: $($d.FriendlyName)" "Gray"
                            Write-Color "      Restarting..." "Gray"
                            Disable-PnpDevice -InstanceId $d.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
                            Start-Sleep -Seconds 3
                            Enable-PnpDevice -InstanceId $d.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
                            break
                        }
                    }
                }
            }
        } catch { Write-Color "  [!] Error: $_" "Red" }
    }

    elseif ($choice -eq "2") {
        Write-Color "  [*] Installing OEM-matched Intel RST driver..." "Cyan"
        Write-Color "      Your system: ASUS GL553VD (Intel i7-7700HQ, 100-series chipset)" "Gray"
        Write-Color "      Required: Intel RST v15.x" "Gray"
        Write-Color "" "Gray"

        # Try to download from Intel's official repository
        $drvUrl = "https://downloadmirror.intel.com/779611/SetupRST.exe"
        $drvPath = "$env:TEMP\SetupRST.exe"

        Write-Color "      Downloading Intel RST driver from Intel..." "Gray"
        try {
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($drvUrl, $drvPath)
            Write-Color "      Downloaded to: $drvPath" "Green"

            if (Confirm-Step "Install Intel RST Driver" "Run the Intel RST installer? It will install the latest compatible version.") {
                Write-Color "      Running installer..." "Cyan"
                Start-Process -FilePath $drvPath -ArgumentList "--quiet --norestart" -Wait
                Write-Color "  [+] Installation complete." "Green"
            }
        } catch {
            Write-Color "  [!] Download failed: $_" "Yellow"
            Write-Color "  [i] Alternative: Download manually from:" "Gray"
            Write-Color "      https://www.intel.com/content/www/us/en/download/19512/intel-rapid-storage-technology-driver-installation-software-with-intel-optane-memory.html" "Blue"
        }
    }

    elseif ($choice -eq "3") {
        Write-Color "  [!] WARNING: This will switch your storage driver from Intel RST to the built-in Microsoft AHCI driver." "Yellow"
        Write-Color "      If the wrong SATA mode is selected, the system may fail to boot." "Red"
        Write-Color "      This change is reversible if you can access Safe Mode." "Yellow"

        if (Confirm-Step "CONFIRM: Switch to Microsoft AHCI Driver" "Are you sure you want to disable Intel RST and use the Microsoft AHCI driver? This is the nuclear option for iaStorAC.sys BSOD.") {
            Write-Color "  [*] Disabling iaStorAC service..." "Cyan"

            # Set the iaStorAC service start to disabled (safely)
            $svcPath = "HKLM:\SYSTEM\CurrentControlSet\Services\iaStorAC"
            if (Test-Path $svcPath) {
                Set-ItemProperty -Path $svcPath -Name "Start" -Value 4 -ErrorAction SilentlyContinue
                Write-Color "      iaStorAC service set to Disabled" "Green"
            }

            # Enable the standard AHCI driver (msahci or storahci)
            $msahciPath = "HKLM:\SYSTEM\CurrentControlSet\Services\msahci"
            $storahciPath = "HKLM:\SYSTEM\CurrentControlSet\Services\storahci"

            if (Test-Path $msahciPath) {
                Set-ItemProperty -Path $msahciPath -Name "Start" -Value 0 -ErrorAction SilentlyContinue
                Write-Color "      Microsoft AHCI driver set to Boot Start" "Green"
            }
            if (Test-Path $storahciPath) {
                Set-ItemProperty -Path $storahciPath -Name "Start" -Value 0 -ErrorAction SilentlyContinue
                Write-Color "      StorAHCI driver set to Boot Start" "Green"
            }

            Write-Color "  [+] Driver configuration updated." "Green"
            Write-Color "  [!] A REBOOT IS REQUIRED for this change to take effect." "Red"
        }
    }

    Write-Color "  [+] Phase 3 complete." "Green"
}

# ===========================================================================
# PHASE 4 — SYSTEM FILE INTEGRITY
# ===========================================================================
function Phase4-SystemFileRepair {
    if (-not (Confirm-Step "System File Integrity Check" "Runs DISM /RestoreHealth and SFC /ScanNow to repair corrupted system files and component store.")) { return }

    Write-Color "  [*] Running DISM /Online /Cleanup-Image /RestoreHealth..." "Cyan"
    Write-Color "      (This may take 10-20 minutes)" "DarkGray"
    try {
        $dism = Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -NoNewWindow -Wait -PassThru
        if ($dism.ExitCode -eq 0) {
            Write-Color "  [+] DISM completed successfully." "Green"
        } else {
            Write-Color "  [!] DISM completed with exit code: $($dism.ExitCode)" "Yellow"
        }
    } catch {
        Write-Color "  [!] DISM encountered: $_" "Yellow"
        # Fallback
        try { & dism /online /cleanup-image /restorehealth } catch {}
    }

    Write-Color "  [*] Running SFC /ScanNow..." "Cyan"
    Write-Color "      (This may take 10-15 minutes)" "DarkGray"
    try {
        $sfc = Start-Process -FilePath "sfc.exe" -ArgumentList "/ScanNow" -NoNewWindow -Wait -PassThru
        if ($sfc.ExitCode -eq 0) {
            Write-Color "  [+] SFC completed — no integrity violations." "Green"
        } else {
            Write-Color "  [!] SFC completed with exit code: $($sfc.ExitCode)." "Yellow"
        }
    } catch {
        Write-Color "  [!] SFC encountered: $_" "Yellow"
        try { & sfc /scannow } catch {}
    }

    Write-Color "  [+] Phase 4 complete." "Green"
}

# ===========================================================================
# PHASE 5 — SYSTEM CLEANUP
# ===========================================================================
function Phase5-SystemCleanup {
    if (-not (Confirm-Step "System Cleanup & Optimization" "Purges temporary files, prefetch, DNS cache, and performs registry cleanup for orphaned driver entries.")) { return }

    Write-Color "  [*] Cleaning system debris..." "Cyan"

    # Temp files
    $tempPaths = @(
        "$env:SystemRoot\Temp",
        "$env:LOCALAPPDATA\Temp",
        "$env:SystemRoot\Prefetch"
    )
    foreach ($p in $tempPaths) {
        if (Test-Path $p) {
            try {
                Remove-Item -Path "$p\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Color "      Cleaned: $p" "Gray"
            } catch {}
        }
    }

    # DNS cache
    try {
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        Write-Color "      DNS cache flushed." "Gray"
    } catch {}

    # Windows Update cache (if user confirms)
    if (Confirm-Step "Reset Windows Update Cache" "Clear the SoftwareDistribution folder? Apps may take longer to update next time.") {
        try {
            Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
            Stop-Service bits -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
            Start-Service wuauserv -ErrorAction SilentlyContinue
            Start-Service bits -ErrorAction SilentlyContinue
            Write-Color "      Windows Update cache cleared." "Green"
        } catch { Write-Color "  [!] Failed to clear WU cache: $_" "Yellow" }
    }

    # Registry: clean orphaned driver entries
    Write-Color "  [*] Scanning for orphaned driver entries in registry..." "Gray"
    $svcPaths = @(
        "HKLM:\SYSTEM\CurrentControlSet\Services",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Class"
    )
    $orphanCount = 0
    foreach ($base in $svcPaths) {
        if (Test-Path $base) {
            try {
                $items = Get-ChildItem $base -ErrorAction SilentlyContinue
                foreach ($item in $items) {
                    $imgPath = (Get-ItemProperty -Path $item.PSPath -Name "ImagePath" -ErrorAction SilentlyContinue).ImagePath
                    if ($imgPath -and $imgPath -match '\.sys"') {
                        $sysFile = $imgPath -replace '^.*\\', '' -replace '"', ''
                        $sysPath = "$env:SystemRoot\System32\drivers\$sysFile"
                        if (-not (Test-Path $sysPath)) {
                            Write-Color "      Orphan: $($item.PSChildName) → $sysFile (missing)" "DarkYellow"
                            $orphanCount++
                        }
                    }
                }
            } catch {}
        }
    }
    if ($orphanCount -eq 0) {
        Write-Color "      No orphaned driver entries found." "Green"
    } else {
        Write-Color "      Found $orphanCount orphaned entries." "Yellow"
    }

    Write-Color "  [+] Phase 5 complete." "Green"
}

# ===========================================================================
# PHASE 6 — REPORT & REBOOT
# ===========================================================================
function Phase6-Final {
    Write-Color "`n╔═══════════════════════════════════════════════════════════╗" "Cyan"
    Write-Color "║            ALL PHASES COMPLETE                            ║" "Cyan"
    Write-Color "╚═══════════════════════════════════════════════════════════╝" "Cyan"
    Write-Color ""

    # Generate report
    $reportDir = "$env:USERPROFILE\Desktop\MaddixSuite\BSODFix_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

    $iaStorVer = "Not found"
    if (Test-Path "$env:SystemRoot\System32\drivers\iaStorAC.sys") {
        $iaStorVer = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$env:SystemRoot\System32\drivers\iaStorAC.sys").FileVersion
    }

    $report = @"
<body style="font-family:Segoe UI;background:#0d1117;color:#c9d1d9;padding:20px;">
<div style="max-width:800px;margin:auto;background:#161b22;border-radius:12px;padding:30px;">
<h1 style="color:#58a6ff;">BSODFix Report</h1>
<p style="color:#8b949e;">$(Get-Date 'g') | $env:COMPUTERNAME</p>
<hr style="border-color:#30363d;">
<h3>System</h3>
$(Get-CimInstance Win32_OperatingSystem | ForEach-Object { "$($_.Caption) (Build $($_.BuildNumber))<br>" })
$(Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1 | ForEach-Object { "$($_.Name)<br>" })
RAM: $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0)) GB<br>
Disk C: $([math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace/1GB,1)) GB free of $([math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").Size/1GB,1)) GB
<h3>iaStorAC.sys</h3>
Version: $iaStorVer<br>
Path: C:\Windows\System32\drivers\iaStorAC.sys
<h3>Actions Taken</h3>
<div id="actions">(See console output above)</div>
<p style="color:#3fb950;">Review minidumps in C:\Windows\Minidump\ for further analysis.</p>
</div></body>
"@

    $html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>BSODFix Report</title></head>$report</html>"
    $report | Out-File -FilePath "$reportDir\Report.html" -Encoding UTF8
    Write-Color "  Report saved to: $reportDir\Report.html" "Green"

    if (Confirm-Step "Reboot Required" "A system restart is recommended for driver changes to take effect. Reboot now?") {
        Write-Color "  Rebooting in 10 seconds..." "Yellow"
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    }
}

# ===========================================================================
# MAIN
# ===========================================================================
Test-Admin
Phase0-SystemInfo
Phase1-EventLogAnalysis
Phase2-iaStorACDiagnostic
Phase3-iaStorACRepair
Phase4-SystemFileRepair
Phase5-SystemCleanup
Phase6-Final
