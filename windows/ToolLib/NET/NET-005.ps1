Register-Tool @{
    ID          = 'NET-005'
    Name        = 'Network Reset'
    Category    = 'NET'
    Description = 'Reset Winsock, TCP/IP stack, flush DNS, and reset firewall'
    DangerLevel = 'Caution'
    ConfirmMessage = 'Resets network stack including Winsock, TCP/IP, DNS cache, and Windows Firewall.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── NETWORK RESET ───" "Cyan"
        Write-Color "  This will reset the entire network stack." "Yellow"
        Write-Color "  A reboot may be required afterward." "Yellow"
        Write-Color "`n  Starting in 3 seconds..." "White"
        Start-Sleep -Seconds 3
        try {
            Write-Color "  [1/6] Resetting Winsock..." "White"
            netsh winsock reset | Out-Null
            Write-Color "  [+] Winsock reset complete" "Green"
        } catch { Write-Color "  [!] Winsock reset failed: $_" "Red" }
        try {
            Write-Color "  [2/6] Resetting TCP/IP stack..." "White"
            netsh int ip reset | Out-Null
            Write-Color "  [+] TCP/IP reset complete" "Green"
        } catch { Write-Color "  [!] TCP/IP reset failed: $_" "Red" }
        try {
            Write-Color "  [3/6] Flushing DNS cache..." "White"
            Clear-DnsClientCache -ErrorAction Stop
            Write-Color "  [+] DNS cache flushed" "Green"
        } catch { Write-Color "  [!] DNS flush failed: $_" "Red" }
        try {
            Write-Color "  [4/6] Resetting Windows Firewall..." "White"
            netsh advfirewall reset | Out-Null
            Write-Color "  [+] Firewall reset complete" "Green"
        } catch { Write-Color "  [!] Firewall reset failed: $_" "Red" }
        try {
            Write-Color "  [5/6] Releasing DHCP lease..." "White"
            ipconfig /release | Out-Null
            Write-Color "  [+] DHCP lease released" "Green"
        } catch { Write-Color "  [!] DHCP release failed: $_" "Red" }
        try {
            Write-Color "  [6/6] Renewing DHCP lease..." "White"
            ipconfig /renew | Out-Null
            Write-Color "  [+] DHCP lease renewed" "Green"
        } catch { Write-Color "  [!] DHCP renew failed: $_" "Red" }
        Write-Color "`n  [+] Network reset complete. Reboot recommended." "Green"
        Pause
    }
}
