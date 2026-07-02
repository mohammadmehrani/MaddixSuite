Register-Tool @{
    ID          = 'NET-016'
    Name        = 'VPN Connection Manager'
    Category    = 'NET'
    Description = 'List, connect, and disconnect VPN connections'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Lists, connects, and disconnects VPN connections.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── VPN CONNECTION MANAGER ───" "Cyan"
        Write-Color "  1. List all VPN connections" "White"
        Write-Color "  2. Show active VPN connections" "White"
        Write-Color "  3. Connect to VPN" "White"
        Write-Color "  4. Disconnect active VPN" "White"
        Write-Color "  0. Back" "Red"
        $c = Read-Host "`n  Select option"
        switch ($c) {
            "1" {
                try {
                    $vpns = Get-VpnConnection -ErrorAction Stop
                    if (-not $vpns) { Write-Color "  No VPN connections configured." "Yellow"; break }
                    foreach ($v in $vpns) {
                        $status = if ($v.ConnectionStatus -eq "Connected") { "Connected" } else { "Disconnected" }
                        Write-Color "  Name: $($v.Name)" "White"
                        Write-Color "  Server: $($v.ServerAddress)" "Gray"
                        Write-Color "  Type: $($v.TunnelType)" "Gray"
                        Write-Color "  Status: $status" ($status -eq "Connected" ? "Green" : "Yellow")
                        Write-Color "  ─────────────────────" "DarkGray"
                    }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "2" {
                try {
                    $active = Get-VpnConnection -ErrorAction Stop | Where-Object ConnectionStatus -eq Connected
                    if ($active) {
                        Write-Color "  Active VPN connections:" "Green"
                        foreach ($v in $active) {
                            Write-Color "  - $($v.Name) ($($v.ServerAddress))" "White"
                            $if = Get-NetAdapter | Where-Object Name -like "*$($v.Name)*"
                            if ($if) {
                                $ip = (Get-NetIPAddress -InterfaceIndex $if.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
                                Write-Color "    IP: $ip" "Gray"
                            }
                        }
                    } else {
                        Write-Color "  No active VPN connections." "Yellow"
                    }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "3" {
                try {
                    $vpns = Get-VpnConnection -ErrorAction Stop
                    if (-not $vpns) { Write-Color "  No VPN connections available." "Yellow"; break }
                    $i = 1
                    $vpnList = @()
                    foreach ($v in $vpns) {
                        Write-Color "  $i. $($v.Name) ($($v.ServerAddress))" "White"
                        $vpnList += $v
                        $i++
                    }
                    $sel = Read-Host "`n  Select VPN to connect"
                    $target = $vpnList[[int]$sel - 1]
                    Write-Color "  Connecting to $($target.Name)..." "Yellow"
                    rasdial $target.Name | Out-String | ForEach-Object { Write-Color $_ "Gray" }
                    Start-Sleep -Seconds 2
                    $check = Get-VpnConnection -Name $target.Name -ErrorAction SilentlyContinue
                    if ($check.ConnectionStatus -eq "Connected") {
                        Write-Color "  [+] Connected to $($target.Name)" "Green"
                    } else {
                        Write-Color "  [!] Connection may have failed. Check credentials." "Red"
                    }
                } catch { Write-Color "  [!] Connection failed: $_" "Red" }
            }
            "4" {
                try {
                    $active = Get-VpnConnection -ErrorAction Stop | Where-Object ConnectionStatus -eq Connected
                    if (-not $active) { Write-Color "  No active VPN connections." "Yellow"; break }
                    foreach ($v in $active) {
                        Write-Color "  Disconnecting $($v.Name)..." "Yellow"
                        rasdial $v.Name /disconnect | Out-Null
                        Write-Color "  [+] $($v.Name) disconnected" "Green"
                    }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
        }
        Pause
    }
}
