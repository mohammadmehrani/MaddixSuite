Register-Tool @{
    ID          = 'SEC-013'
    Name        = 'Windows Security Baselines'
    Category    = 'SEC'
    Description = 'Check security baseline compliance'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Check system against common security baseline recommendations'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Security Baseline Compliance Check" "Green"
            $checks = @()
            $passed = 0; $failed = 0

            Write-Color "`n  [*] Account Policies:" "Yellow"
            $pwPolicy = net accounts
            $maxPWAge = ($pwPolicy | Select-String 'Maximum password age').ToString()
            $minPWLen = ($pwPolicy | Select-String 'Minimum password length').ToString()
            Write-Color "    $maxPWAge" "Cyan"
            Write-Color "    $minPWLen" "Cyan"

            Write-Color "`n  [*] UAC Status:" "Yellow"
            $uac = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableLUA' -ErrorAction SilentlyContinue
            if ($uac.EnableLUA -eq 1) { $passed++; Write-Color "    UAC: Enabled" "Green" }
            else { $failed++; Write-Color "    UAC: Disabled" "Red" }

            Write-Color "`n  [*] Local Administrator Password Solution (LAPS):" "Yellow"
            $laps = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft Services\AdmPwd' -Name 'AdmPwdEnabled' -ErrorAction SilentlyContinue
            if ($laps -and $laps.AdmPwdEnabled -eq 1) { Write-Color "    LAPS: Configured" "Green" }
            else { Write-Color "    LAPS: Not configured" "Yellow" }

            Write-Color "`n  [*] Windows Update:" "Yellow"
            $wu = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'IsUpdateNotificationEnabled' -ErrorAction SilentlyContinue
            $au = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -ErrorAction SilentlyContinue
            if (-not $au -or $au.NoAutoUpdate -ne 1) { $passed++; Write-Color "    Auto Update: Enabled" "Green" }
            else { $failed++; Write-Color "    Auto Update: Disabled" "Red" }

            Write-Color "`n  [*] Remote Desktop:" "Yellow"
            $rdp = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -ErrorAction SilentlyContinue
            if ($rdp.fDenyTSConnections -eq 1) { $passed++; Write-Color "    RDP: Disabled (good)" "Green" }
            else { $failed++; Write-Color "    RDP: Enabled (potential risk)" "Red" }

            Write-Color "`n  [*] Guest Account:" "Yellow"
            $guest = Get-LocalUser -Name 'Guest' -ErrorAction SilentlyContinue
            if ($guest -and -not $guest.Enabled) { $passed++; Write-Color "    Guest Account: Disabled" "Green" }
            elseif (-not $guest) { Write-Color "    Guest Account: Not present" "Green" }
            else { $failed++; Write-Color "    Guest Account: Enabled" "Red" }

            Write-Color "`n  [*] SMBv1 (deprecated protocol):" "Yellow"
            $smb1 = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name 'SMB1' -ErrorAction SilentlyContinue
            if (-not $smb1 -or $smb1.SMB1 -eq 0) { $passed++; Write-Color "    SMBv1: Disabled" "Green" }
            else { $failed++; Write-Color "    SMBv1: Enabled (vulnerable)" "Red" }

            Write-Color "`n  [+] Summary: $passed passed, $failed failed out of $($passed+$failed) checks" "Yellow"
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
