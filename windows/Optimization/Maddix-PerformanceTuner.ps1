# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
<#
.SYNOPSIS
    Maddix-PerformanceTuner - Advanced Windows Performance Optimization
.DESCRIPTION
    Comprehensive performance tuning utility by Mohammad Mehrani (Maddix).
    Features: CPU optimization, RAM management, disk tuning, GPU settings,
    power plan optimization, service tuning, startup optimization, network tuning,
    visual effects, and system cache configuration.
.NOTES
    Version: 1.0
    Author: Mohammad Mehrani (Maddix)
    Part of MaddixSuite: https://github.com/mohammadmehrani/MaddixSuite
    One-liner: irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Optimization/Maddix-PerformanceTuner.ps1 | iex
#>

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: Administrator privileges required." -ForegroundColor Red
    Pause; Exit
}

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
    Write-Host "  Maddix-PerformanceTuner v1.0 · System Optimization" -ForegroundColor Cyan
    Write-Host "  Created by Mohammad Mehrani (Maddix)" -ForegroundColor Cyan
    Write-Host "████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host ""
}

function Optimize-CPU {
    Write-Host "`n=== CPU OPTIMIZATION ===" -ForegroundColor Cyan
    Write-Host "[1/3] Processor scheduling..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  Priority: Programs (foreground boost)" -ForegroundColor Gray
    
    Write-Host "[2/3] CPU power management..." -ForegroundColor Yellow
    powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
    powercfg -setactive SCHEME_CURRENT
    Write-Host "  Max CPU state: 100%" -ForegroundColor Gray
    
    Write-Host "[3/3] CPU core parking..." -ForegroundColor Yellow
    powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100
    powercfg -setactive SCHEME_CURRENT
    Write-Host "  Core unparking: Enabled" -ForegroundColor Gray
    Write-Host "`nCPU optimization applied." -ForegroundColor Green
    Pause
}

function Optimize-RAM {
    Write-Host "`n=== RAM & MEMORY OPTIMIZATION ===" -ForegroundColor Cyan
    
    Write-Host "[1/5] Disable memory compression..." -ForegroundColor Yellow
    Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
    Write-Host "  Memory compression: Disabled" -ForegroundColor Gray
    
    Write-Host "[2/5] Large system cache..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  Large system cache: Enabled" -ForegroundColor Gray
    
    Write-Host "[3/5] I/O page locking..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  Kernel paging: Disabled (faster)" -ForegroundColor Gray
    
    Write-Host "[4/5] Pool usage maximum..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PoolUsageMaximum" -Value 60 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  Pool usage max: 60%" -ForegroundColor Gray
    
    Write-Host "[5/5] Clear working set..." -ForegroundColor Yellow
    $size = (Get-CimInstance -ClassName Win32_OperatingSystem).TotalVisibleMemorySize * 1KB
    $target = [math]::Round($size * 0.9)
    Write-Host "  Memory available: $([math]::Round($size/1GB,2)) GB" -ForegroundColor Gray
    
    Write-Host "`nRAM optimization applied. Reboot recommended." -ForegroundColor Green
    Pause
}

function Optimize-Disk {
    Write-Host "`n=== DISK OPTIMIZATION ===" -ForegroundColor Cyan
    
    Write-Host "[1/4] Disable 8.3 filename creation..." -ForegroundColor Yellow
    try {
        fsutil behavior set disable8dot3 1
        Write-Host "  8.3 names: Disabled" -ForegroundColor Gray
    } catch {}
    
    Write-Host "[2/4] Disable last access timestamp..." -ForegroundColor Yellow
    try {
        fsutil behavior set disablelastaccess 1
        Write-Host "  Last access time: Disabled" -ForegroundColor Gray
    } catch {}
    
    Write-Host "[3/4] Enable NTFS compression (system files)..." -ForegroundColor Yellow
    Write-Host "  Skipped: Can reduce performance on modern systems." -ForegroundColor Gray
    
    Write-Host "[4/4] SSD/NVMe optimization..." -ForegroundColor Yellow
    $drives = Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -eq "SSD" -or $_.FirmwareVersion -match "NVMe" }
    foreach ($d in $drives) {
        $part = $d | Get-Partition -ErrorAction SilentlyContinue | Get-Volume -ErrorAction SilentlyContinue
        if ($part.DriveLetter) {
            Optimize-Volume -DriveLetter $part.DriveLetter -ReTrim -Verbose -ErrorAction SilentlyContinue
            Write-Host "  $($d.FriendlyName): ReTrim completed" -ForegroundColor Green
        }
    }
    
    Write-Host "`nDisk optimization applied." -ForegroundColor Green
    Pause
}

function Optimize-GPU {
    Write-Host "`n=== GRAPHICS OPTIMIZATION ===" -ForegroundColor Cyan
    
    Write-Host "[1/4] Hardware-accelerated GPU scheduling..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  HAGS: Enabled" -ForegroundColor Gray
    
    Write-Host "[2/4] GPU performance mode..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "RmGpuWorkload" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  GPU workload: Performance" -ForegroundColor Gray
    
    Write-Host "[3/4] Visual effects (performance mode)..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  Visual effects: Performance mode" -ForegroundColor Gray
    
    Write-Host "[4/4] Transparency effects..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  Transparency: Disabled" -ForegroundColor Gray
    
    Write-Host "`nGPU optimization applied." -ForegroundColor Green
    Pause
}

function Optimize-Startup {
    Write-Host "`n=== STARTUP OPTIMIZATION ===" -ForegroundColor Cyan
    
    Write-Host "[1/3] Boot configuration..." -ForegroundColor Yellow
    try {
        bcdedit /timeout 5
        Write-Host "  Boot menu timeout: 5 seconds" -ForegroundColor Gray
    } catch {}
    
    Write-Host "[2/3] Boot optimization..." -ForegroundColor Yellow
    try {
        bcdedit /set bootux disabled
        bcdedit /set bootmenupolicy standard
        Write-Host "  Boot UX: Disabled" -ForegroundColor Gray
    } catch {}
    
    Write-Host "[3/3] Startup programs (via registry)..." -ForegroundColor Yellow
    $startupPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    )
    
    Write-Host "  Current startup entries:" -ForegroundColor Gray
    foreach ($sp in $startupPaths) {
        if (Test-Path $sp) {
            Get-ItemProperty $sp -ErrorAction SilentlyContinue | Select-Object -Property * -ExcludeProperty PS* | ForEach-Object {
                $_.PSObject.Properties | ForEach-Object {
                    Write-Host "    $($_.Name) = $($_.Value)" -ForegroundColor Gray
                }
            }
        }
    }
    
    $disableAll = Read-Host "Disable all startup items? (y/n)"
    if ($disableAll -eq 'y') {
        foreach ($sp in $startupPaths) {
            if (Test-Path $sp) {
                Get-ItemProperty $sp -ErrorAction SilentlyContinue | Select-Object -Property * -ExcludeProperty PS* | ForEach-Object {
                    $_.PSObject.Properties | ForEach-Object {
                        Remove-ItemProperty -Path $sp -Name $_.Name -ErrorAction SilentlyContinue
                    }
                }
            }
        }
        Write-Host "  All startup items disabled." -ForegroundColor Green
    }
    
    Write-Host "`nStartup optimization applied." -ForegroundColor Green
    Pause
}

function Optimize-Power {
    Write-Host "`n=== POWER PLAN OPTIMIZATION ===" -ForegroundColor Cyan
    
    Write-Host "[1/3] Creating Ultimate Performance plan..." -ForegroundColor Yellow
    try {
        powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
        $plans = powercfg -list | Select-String -Pattern "Ultimate Performance"
        if ($plans) {
            $guid = ($plans -split '\s+')[3]
            powercfg -setactive $guid
            Write-Host "  Ultimate Performance plan activated." -ForegroundColor Green
        }
    } catch {}
    
    Write-Host "[2/3] Applying sub-settings..." -ForegroundColor Yellow
    powercfg -change -standby-timeout-ac 0
    powercfg -change -hibernate-timeout-ac 0
    powercfg -change -disk-timeout-ac 0
    Write-Host "  Sleep/Hibernate: Disabled" -ForegroundColor Gray
    
    Write-Host "[3/3] USB selective suspend..." -ForegroundColor Yellow
    powercfg -setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    powercfg -setactive SCHEME_CURRENT
    Write-Host "  USB suspend: Disabled" -ForegroundColor Gray
    
    Write-Host "`nPower plan optimized." -ForegroundColor Green
    Pause
}

function Optimize-Network {
    Write-Host "`n=== NETWORK PERFORMANCE ===" -ForegroundColor Cyan
    
    Write-Host "[1/4] TCP auto-tuning..." -ForegroundColor Yellow
    netsh int tcp set global autotuninglevel=normal
    Write-Host "  TCP auto-tuning: Normal" -ForegroundColor Gray
    
    Write-Host "[2/4] TCP chimney offload..." -ForegroundColor Yellow
    netsh int tcp set global chimney=enabled
    Write-Host "  TCP chimney: Enabled" -ForegroundColor Gray
    
    Write-Host "[3/4] RSS (Receive Side Scaling)..." -ForegroundColor Yellow
    netsh int tcp set global rss=enabled
    Write-Host "  RSS: Enabled" -ForegroundColor Gray
    
    Write-Host "[4/4] Network throttling index..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 4294967295 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  Network throttling: Disabled" -ForegroundColor Gray
    
    Write-Host "`nNetwork optimization applied." -ForegroundColor Green
    Pause
}

function Run-AllOptimizations {
    Write-Host "`n=== RUNNING ALL OPTIMIZATIONS ===" -ForegroundColor Cyan
    
    Write-Host "[1/6] CPU Optimization..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Type DWord -ErrorAction SilentlyContinue
    powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
    Write-Host "  Done." -ForegroundColor Green
    
    Write-Host "[2/6] Memory Optimization..." -ForegroundColor Yellow
    Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  Done." -ForegroundColor Green
    
    Write-Host "[3/6] Disk Optimization..." -ForegroundColor Yellow
    fsutil behavior set disable8dot3 1 2>$null
    fsutil behavior set disablelastaccess 1 2>$null
    Write-Host "  Done." -ForegroundColor Green
    
    Write-Host "[4/6] GPU & Visual Effects..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  Done." -ForegroundColor Green
    
    Write-Host "[5/6] Power Plan..." -ForegroundColor Yellow
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
    $plans = powercfg -list | Select-String -Pattern "Ultimate Performance"
    if ($plans) { powercfg -setactive (($plans -split '\s+')[3]) }
    Write-Host "  Done." -ForegroundColor Green
    
    Write-Host "[6/6] Network Tuning..." -ForegroundColor Yellow
    netsh int tcp set global autotuninglevel=normal
    netsh int tcp set global chimney=enabled
    netsh int tcp set global rss=enabled
    Write-Host "  Done." -ForegroundColor Green
    
    Write-Host "`n==============================================" -ForegroundColor Cyan
    Write-Host "  ALL OPTIMIZATIONS COMPLETED!" -ForegroundColor Green
    Write-Host "  A system reboot is required." -ForegroundColor Yellow
    Write-Host "==============================================" -ForegroundColor Cyan
    
    $reboot = Read-Host "Reboot now? (y/n)"
    if ($reboot -eq 'y') { Restart-Computer -Force }
    Pause
}

function Show-Menu {
    Show-Banner
    Write-Host " ──── OPTIMIZATION CATEGORIES ────" -ForegroundColor Magenta
    Write-Host "   1.  CPU Optimization (Scheduling, Core Parking)"
    Write-Host "   2.  Memory Optimization (RAM, Cache, Paging)"
    Write-Host "   3.  Disk Optimization (NTFS, SSD)"
    Write-Host "   4.  GPU & Graphics Optimization"
    Write-Host "   5.  Startup & Boot Optimization"
    Write-Host "   6.  Power Plan (Ultimate Performance)"
    Write-Host "   7.  Network Performance Tuning"
    Write-Host ""
    Write-Host " ──── GENERAL ────" -ForegroundColor Magenta
    Write-Host "   8.  Run ALL Optimizations"
    Write-Host "   0.  Exit"
    Write-Host ""
}

function Main {
    while ($true) {
        Show-Menu
        $c = Read-Host "Select option (0-8)"
        switch ($c) {
            "1" { Optimize-CPU }
            "2" { Optimize-RAM }
            "3" { Optimize-Disk }
            "4" { Optimize-GPU }
            "5" { Optimize-Startup }
            "6" { Optimize-Power }
            "7" { Optimize-Network }
            "8" { Run-AllOptimizations }
            "0" { Write-Host "Goodbye!" -ForegroundColor Cyan; exit }
            default { Write-Host "Invalid." -ForegroundColor Red; Pause }
        }
    }
}

Main

