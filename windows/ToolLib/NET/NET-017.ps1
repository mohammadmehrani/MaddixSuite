Register-Tool @{
    ID          = 'NET-017'
    Name        = 'Network Map'
    Category    = 'NET'
    Description = 'Show network neighbors, shares, and discovered devices'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only. Discovers network neighbors and shared resources.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── NETWORK MAP ───" "Cyan"
        Write-Color "  Scanning network neighborhood..." "Yellow"
        Write-Color "`n  ── Network Neighbors (NetBIOS) ──" "Cyan"
        try {
            $computers = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=True -ErrorAction Stop
            Write-Color "  Local IP(s): $($computers | Select-Object -ExpandProperty IPAddress -First 1)" "White"
        } catch { Write-Color "  Could not determine local IP" "Yellow" }
        try {
            $neighbors = nbtstat -n 2>$null
            if ($neighbors) {
                Write-Color "$neighbors" "Gray"
            } else {
                Write-Color "  No NetBIOS entries found." "Yellow"
            }
        } catch { Write-Color "  NetBIOS scan unavailable" "Yellow" }
        Write-Color "`n  ── SMB Shares ──" "Cyan"
        try {
            $shares = Get-SmbShare -ErrorAction Stop
            if ($shares) {
                $shares | Select-Object Name, Path, Description | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
            } else { Write-Color "  No local SMB shares." "Yellow" }
        } catch { Write-Color "  SMB query failed: $_" "Red" }
        Write-Color "`n  ── Discovered Devices (ARP Table) ──" "Cyan"
        try {
            $arp = arp -a
            Write-Color "$arp" "Gray"
        } catch { Write-Color "  ARP table unavailable" "Yellow" }
        Write-Color "`n  ── Active Network Discovery ──" "Cyan"
        Write-Color "  Scanning subnet for active hosts..." "Yellow"
        try {
            $localIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch "Loopback|Tunnel|Bluetooth" } | Select-Object -First 1).IPAddress
            $subnet = $localIp -replace '\d+$', ''
            $found = 0
            for ($i = 1; $i -le 254; $i++) {
                $target = "$subnet$i"
                if (Test-Connection -ComputerName $target -Count 1 -Quiet -TimeoutSeconds 1 -ErrorAction SilentlyContinue) {
                    try {
                        $hostName = [System.Net.Dns]::GetHostEntry($target).HostName
                    } catch { $hostName = "unknown" }
                    Write-Color "  [+] $target - $hostName" "Green"
                    $found++
                }
            }
            if ($found -eq 0) { Write-Color "  No active hosts found on subnet." "Yellow" }
            else { Write-Color "`n  Found $found active host(s) on subnet." "Green" }
        } catch { Write-Color "  Subnet scan failed: $_" "Red" }
        Pause
    }
}
