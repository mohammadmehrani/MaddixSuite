Register-Tool @{
    ID          = 'OPT-009'
    Name        = 'Boot Time Reducer'
    Category    = 'OPT'
    Description = 'Boot settings optimization (boot timeout, GUI)'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Apply boot time reduction optimizations'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Boot Time Optimizations:" "Green"

            Write-Color "`n  [*] Boot Configuration Data (BCD):" "Yellow"
            $bootMgr = bcdedit /enum {bootmgr} 2>$null
            $timeout = bcdedit /enum | Select-String 'timeout'
            if ($timeout) {
                $timeoutVal = ($timeout -split '\s+')[-1]
                Write-Color "    Current timeout: $timeoutVal seconds" "Cyan"
                $newTimeout = Read-Host "  [+] Set new timeout in seconds (0-30, default 30)"
                if ($newTimeout -match '^\d+$') {
                    bcdedit /timeout $newTimeout | Out-Null
                    Write-Color "  [+] Boot timeout set to $newTimeout seconds" "Green"
                }
            }

            Write-Color "`n  [*] Boot Menu Policy:" "Yellow"
            $bootPolicy = bcdedit /enum | Select-String 'bootmenupolicy'
            Write-Color "    Current: $(if($bootPolicy){($bootPolicy -split '\s+')[-1]}else{'Standard'})" "Cyan"
            $setLegacy = Read-Host "  [+] Use Legacy boot menu (faster)? (y/N)"
            if ($setLegacy -eq 'y') { bcdedit /set {current} bootmenupolicy legacy; Write-Color "  [+] Legacy boot menu set" "Green" }

            Write-Color "`n  [*] GUI Boot (animation):" "Yellow"
            $guiSetting = bcdedit /enum | Select-String 'bootux'
            if (-not $guiSetting) {
                Write-Color "    GUI Boot: Default (enabled)" "Cyan"
            } else {
                Write-Color "    Current: $($guiSetting.ToString().Trim())" "Cyan"
            }
            $noGui = Read-Host "  [+] Disable boot animation (faster boot)? (y/N)"
            if ($noGui -eq 'y') { bcdedit /set {current} bootux disabled; Write-Color "  [+] Boot animation disabled" "Green" }

            Write-Color "`n  [*] Processor Count (boot):" "Yellow"
            $numa = bcdedit /enum | Select-String 'numproc'
            if ($numa) {
                Write-Color "    Current: $($numa.ToString().Trim())" "Cyan"
            } else {
                Write-Color "    All processors used by default" "Green"
            }

            Write-Color "`n  [*] Fast Startup:" "Yellow"
            $fastStartup = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -ErrorAction SilentlyContinue
            $fsVal = if ($fastStartup -and $fastStartup.HiberbootEnabled -eq 1) { 'Enabled' } else { 'Disabled' }
            Write-Color "    Fast Startup: $fsVal" "Cyan"
            $toggle = Read-Host "  [+] Enable Fast Startup? (y/N)"
            if ($toggle -eq 'y') {
                Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value 1 -Type DWord
                Write-Color "  [+] Fast Startup enabled" "Green"
            }

            Write-Color "`n  [!] Some boot changes require a reboot to take effect" "Yellow"
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
