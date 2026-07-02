Register-Tool @{
    ID          = 'NET-004'
    Name        = 'DNS Changer'
    Category    = 'NET'
    Description = 'Switch between Google/Cloudflare/OpenDNS/Custom DNS servers'
    DangerLevel = 'Caution'
    ConfirmMessage = 'Changes DNS server settings on all active network adapters.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── DNS CHANGER ───" "Cyan"
        Write-Color "  1. Google DNS (8.8.8.8 / 8.8.4.4)" "White"
        Write-Color "  2. Cloudflare DNS (1.1.1.1 / 1.0.0.1)" "White"
        Write-Color "  3. OpenDNS (208.67.222.222 / 208.67.220.220)" "White"
        Write-Color "  4. Custom DNS" "White"
        Write-Color "  5. Reset to DHCP (automatic)" "White"
        Write-Color "  0. Back" "Red"
        $c = Read-Host "`n  Select option"
        switch ($c) {
            "1" { $dns1 = "8.8.8.8"; $dns2 = "8.8.4.4" }
            "2" { $dns1 = "1.1.1.1"; $dns2 = "1.0.0.1" }
            "3" { $dns1 = "208.67.222.222"; $dns2 = "208.67.220.220" }
            "4" { $dns1 = Read-Host "  Primary DNS"; $dns2 = Read-Host "  Secondary DNS (optional)" }
            "5" { $dns1 = $null; $dns2 = $null }
        }
        if ($c -ne "0") {
            try {
                $adapters = Get-NetAdapter -Physical | Where-Object Status -eq Up
                foreach ($adapter in $adapters) {
                    if ($dns1 -and $dns2) {
                        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ($dns1, $dns2) -ErrorAction Stop
                        Write-Color "  [+] $($adapter.Name): DNS set to $dns1, $dns2" "Green"
                    } elseif ($dns1) {
                        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $dns1 -ErrorAction Stop
                        Write-Color "  [+] $($adapter.Name): DNS set to $dns1" "Green"
                    } else {
                        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses -ErrorAction Stop
                        Write-Color "  [+] $($adapter.Name): DNS reset to DHCP" "Green"
                    }
                }
                Write-Color "  [+] DNS changes applied. Flushing cache..." "Yellow"
                Clear-DnsClientCache -ErrorAction SilentlyContinue
                Write-Color "  [+] DNS cache flushed." "Green"
            } catch {
                Write-Color "  [!] Error: $_" "Red"
            }
        }
        Pause
    }
}
