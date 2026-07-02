Register-Tool @{
    ID          = 'SEC-002'
    Name        = 'Firewall Audit'
    Category    = 'SEC'
    Description = 'Check firewall rules, profiles, blocked events'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Audit Windows Firewall configuration and rules'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Active Firewall Profiles:" "Green"
            Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table -AutoSize

            Write-Color " `n  [+] Firewall Rules Count: $( (Get-NetFirewallRule).Count )" "Green"

            $blocked = Get-NetFirewallRule | Where-Object { $_.Action -eq 'Block' -and $_.Enabled -eq 'True' }
            if ($blocked) {
                Write-Color "  [+] Blocking Rules ($($blocked.Count)):" "Yellow"
                $blocked | Select-Object DisplayName, Direction, Profile | Format-Table -AutoSize
            }

            $events = Get-WinEvent -FilterHashtable @{LogName='Security';ID=5152} -MaxEvents 50 -ErrorAction SilentlyContinue
            if ($events) {
                Write-Color "  [+] Recent Blocked Connections (last 50):" "Yellow"
                $events | Select-Object TimeCreated, Message | Format-Table -AutoSize
            } else {
                Write-Color "  [+] No blocked connection events found in Security log" "Green"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
