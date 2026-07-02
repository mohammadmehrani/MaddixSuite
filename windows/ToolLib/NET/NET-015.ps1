Register-Tool @{
    ID          = 'NET-015'
    Name        = 'Wake-on-LAN'
    Category    = 'NET'
    Description = 'Send WOL magic packet to wake a remote computer'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Sends a Wake-on-LAN magic packet to the specified MAC address.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── WAKE-ON-LAN ───" "Cyan"
        $mac = Read-Host "  Target MAC address (e.g. AA:BB:CC:DD:EE:FF)"
        $ip = Read-Host "  Subnet broadcast IP (e.g. 192.168.1.255) [default: 255.255.255.255]"
        $port = Read-Host "  Port [default: 9]"
        if ([string]::IsNullOrWhiteSpace($ip)) { $ip = "255.255.255.255" }
        if ([string]::IsNullOrWhiteSpace($port)) { $port = 9 } else { $port = [int]$port }
        $cleanMac = $mac -replace '[^0-9a-fA-F]', ''
        if ($cleanMac.Length -ne 12) {
            Write-Color "  [!] Invalid MAC address. Use format like AA:BB:CC:DD:EE:FF" "Red"
            Pause
            return
        }
        try {
            $macBytes = @()
            for ($i = 0; $i -lt 6; $i++) {
                $macBytes += [byte]("0x$($cleanMac.Substring($i*2,2))")
            }
            $packet = @(0xFF) * 6
            for ($i = 0; $i -lt 16; $i++) {
                $packet += $macBytes
            }
            $udp = New-Object System.Net.Sockets.UdpClient
            $udp.Connect($ip, $port)
            $udp.Send($packet, $packet.Length) | Out-Null
            $udp.Close()
            Write-Color "  [+] Magic packet sent to $mac via $ip`:$port" "Green"
            Write-Color "  Note: Target must support WOL and be on same subnet." "Yellow"
            Write-Color "  If using 255.255.255.255, packet is broadcast to whole network." "Gray"
        } catch {
            Write-Color "  [!] Failed to send WOL packet: $_" "Red"
        }
        Pause
    }
}
