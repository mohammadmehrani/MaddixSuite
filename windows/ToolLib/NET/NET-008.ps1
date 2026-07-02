Register-Tool @{
    ID          = 'NET-008'
    Name        = 'Port Scanner'
    Category    = 'NET'
    Description = 'Scan remote host for open TCP ports'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Scans specified TCP ports on a remote host.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── PORT SCANNER ───" "Cyan"
        $hostname = Read-Host "  Target host (IP or hostname)"
        $portRange = Read-Host "  Port range (e.g. 1-1000 or 22,80,443)"
        $timeoutMs = Read-Host "  Timeout per port (ms) [default: 1000]"
        if ([string]::IsNullOrWhiteSpace($timeoutMs)) { $timeoutMs = 1000 } else { $timeoutMs = [int]$timeoutMs }
        try {
            $resolved = [System.Net.Dns]::GetHostAddresses($hostname) | Select-Object -First 1
            Write-Color "  Resolved $hostname -> $($resolved.IPAddressToString)" "Gray"
        } catch {
            Write-Color "  [!] Cannot resolve hostname: $_" "Red"
            Pause
            return
        }
        $ports = @()
        if ($portRange -match "^(\d+)-(\d+)$") {
            $ports = $Matches[1]..$Matches[2]
        } elseif ($portRange -match "^(\d+(?:,\d+)*)$") {
            $ports = $portRange -split "," | ForEach-Object { [int]$_ }
        } else {
            Write-Color "  [!] Invalid port format. Use 1-1000 or 22,80,443" "Red"
            Pause
            return
        }
        Write-Color "  Scanning $($ports.Count) ports on $hostname..." "Yellow"
        $openPorts = @()
        $progress = 0
        foreach ($port in $ports) {
            $progress++
            Write-Progress -Activity "Port Scanning $hostname" -Status "$port / $($ports.Count)" -PercentComplete (($progress / $ports.Count) * 100)
            try {
                $tcp = New-Object System.Net.Sockets.TcpClient
                $async = $tcp.BeginConnect($resolved.IPAddressToString, $port, $null, $null)
                $wait = $async.AsyncWaitHandle.WaitOne($timeoutMs, $false)
                if ($wait -and $tcp.Connected) {
                    $tcp.EndConnect($async)
                    $service = "unknown"
                    switch ($port) {
                        21 { $service = "FTP" }
                        22 { $service = "SSH" }
                        23 { $service = "Telnet" }
                        25 { $service = "SMTP" }
                        53 { $service = "DNS" }
                        80 { $service = "HTTP" }
                        110 { $service = "POP3" }
                        143 { $service = "IMAP" }
                        443 { $service = "HTTPS" }
                        445 { $service = "SMB" }
                        3389 { $service = "RDP" }
                        5900 { $service = "VNC" }
                        8080 { $service = "HTTP-Alt" }
                    }
                    $openPorts += [PSCustomObject]@{ Port = $port; Service = $service }
                    Write-Color "  [+] Port $port open ($service)" "Green"
                }
                $tcp.Close()
            } catch { }
        }
        Write-Progress -Activity "Port Scanning $hostname" -Completed
        if ($openPorts.Count -eq 0) {
            Write-Color "`n  No open ports found in range." "Yellow"
        } else {
            Write-Color "`n  ─── RESULTS ───" "Cyan"
            $openPorts | Format-Table Port, Service -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
            Write-Color "  Found $($openPorts.Count) open port(s)" "Green"
        }
        Pause
    }
}
