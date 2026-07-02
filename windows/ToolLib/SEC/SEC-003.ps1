Register-Tool @{
    ID          = 'SEC-003'
    Name        = 'User Account Audit'
    Category    = 'SEC'
    Description = 'List users, admins, disabled accounts, password policy'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Audit local user accounts and password policy'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Local Users:" "Green"
            Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordExpires, PasswordChangeableDate | Format-Table -AutoSize

            Write-Color "`n  [+] Administrator Accounts:" "Yellow"
            $admins = Get-LocalGroupMember -Group 'Administrators'
            $admins | Format-Table -AutoSize

            Write-Color "`n  [+] Disabled Accounts:" "Yellow"
            $disabled = Get-LocalUser | Where-Object { -not $_.Enabled }
            if ($disabled) {
                $disabled | Select-Object Name, LastLogon | Format-Table -AutoSize
            } else {
                Write-Color "    None found" "Green"
            }

            Write-Color "`n  [+] Password Policy:" "Green"
            net accounts | Write-Color "Cyan"

            Write-Color "`n  [+] Accounts with Password Never Expires:" "Yellow"
            $neverExpires = Get-LocalUser | Where-Object { $_.PasswordExpires -eq $null -and $_.Enabled }
            if ($neverExpires) {
                $neverExpires | Select-Object Name | Format-Table -AutoSize
            } else {
                Write-Color "    None found" "Green"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
