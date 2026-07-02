Register-Tool @{
    ID          = 'OPT-001'
    Name        = 'CPU Optimizer'
    Category    = 'OPT'
    Description = 'Power scheme, processor scheduling, core parking'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Apply CPU performance optimizations (power scheme, scheduling, core parking)'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] CPU Optimization Settings:" "Green"

            $current = (Get-CimInstance -ClassName Win32_PowerPlan -Namespace root\cimv2\power | Where-Object { $_.IsActive -eq $true }).ElementName
            Write-Color "    Current Power Plan: $current" "Cyan"

            Write-Color "`n  [?] Select CPU profile:" "Yellow"
            Write-Color "      1 - High Performance (disable power saving)" "Cyan"
            Write-Color "      2 - Balanced (default)" "Cyan"
            Write-Color "      3 - Power Saver" "Cyan"
            $choice = Read-Host "  [+] Enter choice (1-3)"

            $guidMap = @{
                "1" = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"  # High Perf
                "2" = "381b4222-f694-41f0-9685-ff5bb260df2e"  # Balanced
                "3" = "a1841308-3541-4fab-bc81-f71556f20b4a"  # Power Saver
            }
            if ($guidMap.ContainsKey($choice)) {
                powercfg /setactive $guidMap[$choice] | Out-Null
                Write-Color "  [+] Power plan set" "Green"
            }

            Write-Color "`n  [*] Processor Scheduling:" "Yellow"
            $sched = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' -Name 'Win32PrioritySeparation' -ErrorAction SilentlyContinue
            $schedVal = if ($sched) { $sched.Win32PrioritySeparation } else { 'Default' }
            Write-Color "    Current: $schedVal (38 = Programs, 24 = Background Services)" "Cyan"

            Write-Color "`n  [*] Core Parking:" "Yellow"
            $cpEnabled = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Processor' -Name 'CoreParkingEnabled' -ErrorAction SilentlyContinue
            if ($cpEnabled -and $cpEnabled.CoreParkingEnabled -eq 0) {
                Write-Color "    Core Parking: Disabled (max performance)" "Green"
            } else {
                Write-Color "    Core Parking: Enabled (power saving)" "Yellow"
                $disable = Read-Host "  [+] Disable core parking? (y/N)"
                if ($disable -eq 'y') {
                    powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 1
                    powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 1
                    Write-Color "  [+] Core parking minimized" "Green"
                }
            }

            Write-Color "`n  [*] Processor Idle Disable:" "Yellow"
            $disableIdle = Read-Host "  [+] Disable processor idle states (max perf, more power)? (y/N)"
            if ($disableIdle -eq 'y') {
                powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 1
                powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 1
                Write-Color "  [+] Processor idle states disabled" "Yellow"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
