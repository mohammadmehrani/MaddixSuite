Register-Tool @{
    ID          = 'NET-013'
    Name        = 'IP Release/Renew'
    Category    = 'NET'
    Description = 'DHCP release and renew for all network adapters'
    DangerLevel = 'Caution'
    ConfirmMessage = 'Releases and renews DHCP leases on all active adapters.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── DHCP RELEASE / RENEW ───" "Cyan"
        try {
            $adapters = Get-NetAdapter -Physical | Where-Object Status -eq Up
            if (-not $adapters) {
                Write-Color "  [!] No active network adapters found." "Red"
                Pause
                return
            }
            Write-Color "  Active adapters:" "White"
            foreach ($a in $adapters) {
                $ip = (Get-NetIPAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
                Write-Color "    $($a.Name): $ip" "Gray"
            }
            Write-Color "`n  This will temporarily disconnect your network." "Yellow"
            $confirm = Read-Host "  Proceed? (y/N)"
            if ($confirm -ne "y") { Write-Color "  Cancelled." "Red"; Pause; return }
            Write-Color "`n  [1/4] Releasing DHCP leases..." "White"
            try {
                ipconfig /release | Out-Null
                Write-Color "  [+] All leases released" "Green"
            } catch { Write-Color "  [!] Release error: $_" "Red" }
            Start-Sleep -Seconds 2
            Write-Color "  [2/4] Flushing DNS cache..." "White"
            try {
                Clear-DnsClientCache -ErrorAction Stop
                Write-Color "  [+] DNS cache flushed" "Green"
            } catch { Write-Color "  [!] DNS flush error: $_" "Red" }
            Write-Color "  [3/4] Renewing DHCP leases..." "White"
            try {
                ipconfig /renew | Out-Null
                Write-Color "  [+] Leases renewed" "Green"
            } catch { Write-Color "  [!] Renew error: $_" "Red" }
            Start-Sleep -Seconds 2
            Write-Color "  [4/4] Refreshing DNS..." "White"
            try {
                Register-DnsClient -ErrorAction Stop
                Write-Color "  [+] DNS registration complete" "Green"
            } catch { Write-Color "  [!] DNS registration error: $_" "Red" }
            Write-Color "`n  ─── NEW IP CONFIGURATION ───" "Cyan"
            foreach ($a in $adapters) {
                $ip = (Get-NetIPAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
                Write-Color "  $($a.Name): $ip" "White"
            }
            Write-Color "`n  [+] DHCP release/renew complete." "Green"
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
