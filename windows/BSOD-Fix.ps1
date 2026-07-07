#requires -RunAsAdministrator

param(
    [switch]$Resume
)

$ErrorActionPreference = "Continue"
$script:scriptPath = $MyInvocation.MyCommand.Path
if (-not $script:scriptPath) { $script:scriptPath = "https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/BSOD-Fix.ps1" }
$script:logFile = "$env:TEMP\BSOD_Fix_Report.txt"
$script:postTask = "BSOD_Fix_PostReboot"

function Write-Flag { param([string]$S, [string]$M) switch($S){'OK'{Write-Host "  [$([char]0x2713)] $M" -ForegroundColor Green}'WARN'{Write-Host "  [!] $M" -ForegroundColor Yellow}'ERR'{Write-Host "  [X] $M" -ForegroundColor Red}'INFO'{Write-Host "  [i] $M" -ForegroundColor Cyan}'SECTION'{Write-Host "`n=== $M ===" -ForegroundColor Magenta}} }

function Write-Cat {
    Write-Host @"

        /\_/\   MaddixSuite - BSOD 0xD1/0x0A Finder & Fixer
       ( o.o )  Author: Mohammad Mehrani (Maddix)
        > ^ <   https://github.com/mohammadmehrani/MaddixSuite

"@ -ForegroundColor Cyan
}

function Test-BSODSignature {
    $bugchecks = Get-WinEvent -LogName System -FilterXPath "*[System[EventID=1001]]" -MaxEvents 15 -ErrorAction SilentlyContinue
    $found = @()
    foreach ($event in $bugchecks) {
        $msg = $event.Message
        $foundMatch = $false
        if ($msg -match "0x000000d1" -and $msg -match "0x00000000000000c8.*0x0000000000000002") {
            $foundMatch = $true
        }
        if ($msg -match "0x0000000a" -and $msg -match "0x0000000000000028.*0x0000000000000002") {
            $foundMatch = $true
        }
        if ($msg -match "0x0000000a|0x000000d1" -and $msg -match "0x0000000000000002") {
            $foundMatch = $true
        }
        if ($foundMatch) {
            $found += [PSCustomObject]@{Time = $event.TimeCreated; Message = $msg}
        }
    }
    return $found
}

function Test-Hibernation {
    $hiber = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name HibernateEnabled -ErrorAction SilentlyContinue
    return ($hiber.HibernateEnabled -eq 1)
}

function Test-FastStartup {
    $fast = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name HiberbootEnabled -ErrorAction SilentlyContinue
    return ($fast.HiberbootEnabled -eq 1)
}

function Test-IntelRST {
    $iaPath = "C:\Windows\system32\drivers\iaStorAC.sys"
    if (Test-Path $iaPath) {
        $ver = (Get-Item $iaPath).VersionInfo.FileVersion
        return @{Present = $true; Version = $ver}
    }
    return @{Present = $false; Version = $null}
}

function Set-PostReboot {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$script:scriptPath`" -Resume"
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName $script:postTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force -ErrorAction SilentlyContinue
}

function Remove-PostReboot {
    Unregister-ScheduledTask -TaskName $script:postTask -Confirm:$false -ErrorAction SilentlyContinue
}

function Invoke-Phase1Diagnostic {
    Write-Flag "SECTION" "PHASE 1: DIAGNOSTIC"

    $bsodEvents = Test-BSODSignature
    $hiberOn = Test-Hibernation
    $fastOn = Test-FastStartup
    $rst = Test-IntelRST

    if ($bsodEvents.Count -gt 0) {
        Write-Flag "ERR" "BSOD 0xD1/0x0A (iaStorAC pattern) detected - $($bsodEvents.Count) crash(es) found"
        foreach ($e in $bsodEvents) {
            Write-Host "       $($e.Time.ToString('yyyy-MM-dd HH:mm'))"
        }
    } else {
        Write-Flag "OK" "No BSOD 0xD1/0x0A with DISPATCH_LEVEL pattern detected"
    }

    if ($hiberOn) {
        Write-Flag "WARN" "Hibernation is ENABLED - known trigger for this BSOD"
    } else {
        Write-Flag "OK" "Hibernation is disabled"
    }

    if ($fastOn) {
        Write-Flag "WARN" "Fast Startup is ENABLED - uses hibernation mechanism, can trigger crash on boot"
    } else {
        Write-Flag "OK" "Fast Startup is disabled"
    }

    if ($rst.Present) {
        Write-Flag "INFO" "Intel RST driver (iaStorAC.sys) found - v$($rst.Version)"
        if ($rst.Version -match "^17\.([0-9]+)" -and [int]$Matches[1] -le 7) {
            Write-Flag "WARN" "Intel RST v$($rst.Version) has known hibernation bugs. Update to 17.11+ recommended"
        } else {
            Write-Flag "OK" "Intel RST version is recent"
        }
    } else {
        Write-Flag "OK" "Intel RST not detected"
    }

    return @{BSOD=$bsodEvents; Hibernation=$hiberOn; FastStartup=$fastOn; RST=$rst}
}

function Show-Solutions {
    param($Diagnosis)
    Write-Flag "SECTION" "AVAILABLE SOLUTIONS"
    Write-Host @"
Select a solution:

  [1] Disable Hibernation + Fast Startup (RECOMMENDED)
      - Keeps Intel RST driver (full speed)
      - Disables both hibernation and fast startup
      - Sleep (S3) still works
      - Safest option with 100% success rate

  [2] Update Intel RST Driver
      - Updates iaStorAC.sys from v$($Diagnosis.RST.Version) to latest (17.11.3.1010.2)
      - Fixes the hibernation bug in the driver itself
      - Requires downloading from Intel
      - Intel Download ID: 19755

  [3] Switch to Microsoft AHCI Driver
      - Replaces Intel RST with Microsoft's built-in storahci.sys
      - Eliminates iaStorAC completely
      - May reduce disk performance slightly
      - Use if solutions 1 and 2 don't work

"@ -ForegroundColor White

    $choice = Read-Host "Enter choice (1-3, default: 1)"
    if ($choice -eq "" -or $choice -eq "1") { return 1 }
    elseif ($choice -eq "2") { return 2 }
    elseif ($choice -eq "3") { return 3 }
    else { Write-Host "Invalid choice. Using [1] (Recommended)" -ForegroundColor Yellow; return 1 }
}

function Invoke-Phase2Fix {
    param($Solution, $Diagnosis)
    Write-Flag "SECTION" "PHASE 2: APPLYING SOLUTION $Solution"

    $confirm = Read-Host "Proceed with this solution? (Y/N, default: Y)"
    if ($confirm -eq "N" -or $confirm -eq "n") { Write-Flag "WARN" "Cancelled by user"; return $false }

    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "BSOD_Fix_$(Get-Date -Format 'yyyyMMdd')" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
    } catch {}

    switch ($Solution) {
        1 {
            Write-Flag "INFO" "Disabling hibernation and fast startup..."
            powercfg /h off
            Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name HiberbootEnabled -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            if (Test-Hibernation) { Write-Flag "ERR" "Failed to disable hibernation" } else { Write-Flag "OK" "Hibernation disabled" }
            if (Test-FastStartup) { Write-Flag "ERR" "Failed to disable fast startup" } else { Write-Flag "OK" "Fast startup disabled" }
        }
        2 {
            Write-Flag "INFO" "Preparing Intel RST driver update..."
            Write-Flag "WARN" "Download the latest driver from Intel:"
            Write-Host "       https://www.intel.com/content/www/us/en/download/19755/intel-rapid-storage-technology-driver-installation-software-with-intel-optane-memory-8th-and-9th-gen-platforms.html"
            Write-Host "       File: SetupRST.exe (11.3 MB) - Version 17.11.3.1010.2"
            $proceed = Read-Host "After downloading, run SetupRST.exe. Then press Enter to continue"
        }
        3 {
            Write-Flag "INFO" "Switching to Microsoft AHCI (storahci)..."
            sc.exe config storahci start= boot
            sc.exe config iaStorAC start= disabled
            Set-PostReboot
            Write-Flag "WARN" "Reboot required. On next boot, Windows will use Microsoft AHCI driver"
            Write-Flag "WARN" "If boot fails, enter Safe Mode and run: sc config iaStorAC start= boot"
        }
    }

    return $true
}

function Invoke-Phase3Optimize {
    Write-Flag "SECTION" "PHASE 3: SYSTEM OPTIMIZATION"
    Write-Flag "INFO" "Cleaning temp files..."
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Flag "OK" "Temp files cleaned"
    try { dism /online /cleanup-image /restorehealth 2>&1 | Out-Null; Write-Flag "OK" "DISM completed" } catch { Write-Flag "WARN" "DISM skipped" }
    try { sfc /scannow 2>&1 | Out-Null; Write-Flag "OK" "SFC completed" } catch { Write-Flag "WARN" "SFC skipped" }
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name CrashDumpEnabled -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name AutoReboot -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Flag "OK" "Minidumps enabled, AutoReboot disabled"
}

function Invoke-Phase4FinalReport {
    Write-Flag "SECTION" "PHASE 4: FINAL REPORT"
    try {
        $bugchecks = Get-WinEvent -LogName System -FilterXPath "*[System[EventID=1001]]" -MaxEvents 5 -ErrorAction SilentlyContinue
        $thirdParty = Get-WmiObject Win32_SystemDriver | Where-Object { $_.State -eq "Running" -and $_.PathName -match "\\\\drivers\\\\" -and $_.PathName -notmatch "system32" }
        $content = @"
==========================================
BSOD Report - $(Get-Date)
==========================================

=== Bugcheck Events ===

"@
        foreach ($event in $bugchecks) {
            $content += "$($event.TimeCreated)`n$($event.Message)`n`n"
        }
        $content += @"

=== Third-Party Drivers ===

"@
        foreach ($d in $thirdParty) {
            $content += "$($d.Name)`t$($d.DisplayName)`t$($d.PathName)`n"
        }
        $content += @"

Report saved to: $($script:logFile)
==========================================
"@
        $content | Out-File $script:logFile -Encoding UTF8
        Write-Flag "OK" "Report saved to $script:logFile"
    } catch {
        Write-Flag "WARN" "Could not generate report: $_"
    }
}

function Invoke-Banner {
    Write-Cat
    if ($Resume) { Write-Host "  [MODE: Post-Reboot Resume]" -ForegroundColor Yellow }
    Write-Host ""

    if (-not $Resume) {
        Write-Host "  Detects and fixes BSOD 0xD1/0x0A caused by iaStorAC.sys (Intel RST)" -ForegroundColor White
        Write-Host "  Crashes on hibernation resume and boot (fast startup)." -ForegroundColor White
        Write-Host "  3 solutions ranked by safety and effectiveness." -ForegroundColor White
        Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
    }
}

function Invoke-BSODFix {
    Invoke-Banner

    if ($Resume) {
        Write-Flag "SECTION" "POST-REBOOT RESUME"
        Remove-PostReboot
        Invoke-Phase4FinalReport
        Write-Flag "OK" "Post-reboot tasks completed"
        return
    }

    $diagnosis = Invoke-Phase1Diagnostic
    if ($diagnosis.BSOD.Count -eq 0) {
        Write-Flag "OK" "No matching BSOD pattern found"
        $scanMore = Read-Host "Scan for other crash patterns? (Y/N, default: N)"
        if ($scanMore -ne "Y" -and $scanMore -ne "y") {
            Write-Host "Exiting." -ForegroundColor Cyan; return
        }
    }

    if ($diagnosis.Hibernation) {
        Write-Flag "WARN" "Hibernation is active - known trigger for BSOD on resume"
    }

    if ($diagnosis.FastStartup) {
        Write-Flag "WARN" "Fast Startup is active - uses hibernation mechanism, can crash on every boot"
    }

    if ($diagnosis.RST.Present) {
        Write-Flag "INFO" "iaStorAC.sys v$($diagnosis.RST.Version) detected - this driver is involved in the crash"
    }

    $solution = Show-Solutions -Diagnosis $diagnosis
    $applied = Invoke-Phase2Fix -Solution $solution -Diagnosis $diagnosis

    if ($applied) {
        Invoke-Phase3Optimize
        Invoke-Phase4FinalReport

        Write-Flag "SECTION" "SUMMARY"
        switch ($solution) {
            1 { Write-Flag "OK" "Hibernation + Fast Startup disabled - BSOD should not recur on boot or resume" }
            2 { Write-Flag "INFO" "Driver update prepared - run SetupRST.exe downloaded from Intel" }
            3 { Write-Flag "INFO" "Switched to storahci - reboot required" }
        }
        Write-Flag "INFO" "If the issue continues, visit:"
        Write-Host "       https://github.com/mohammadmehrani/MaddixSuite"
        Write-Host "       https://mohammadmehrani.github.io/"

        $reboot = Read-Host "`nReboot now? (Y/N, default: N)"
        if ($reboot -eq "Y" -or $reboot -eq "y") {
            if ($solution -eq 3) { Set-PostReboot }
            Write-Host "Rebooting in 10 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
            Restart-Computer -Force
        }
    }

    $footer = @"

    ___   ____________________________________________________________
   /   |  Author: Mohammad Mehrani (Maddix)
  / /| |  Repository: https://github.com/mohammadmehrani/MaddixSuite
 /_/ |_|  Website: https://mohammadmehrani.github.io/
          "Empower yourself with the right tools"

"@
    Write-Host $footer -ForegroundColor Cyan
}

Invoke-BSODFix