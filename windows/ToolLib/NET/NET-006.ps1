Register-Tool @{
    ID          = 'NET-006'
    Name        = 'Connection Monitor'
    Category    = 'NET'
    Description = 'Real-time TCP connection monitoring with Get-NetTCPConnection'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only. Monitors active TCP connections in real time.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── TCP CONNECTION MONITOR ───" "Cyan"
        Write-Color "  Refreshing every 3 seconds. Press Ctrl+C to exit." "Yellow"
        Write-Color "`n  Interface: $((Get-NetAdapter -Physical | Where-Object Status -eq Up | Select-Object -First 1).Name)"
        Write-Color "  Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-Color "`n  Refresh interval: 3s" "Gray"
        try {
            $lastRun = 0
            while ($true) {
                $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue
                $total = $connections.Count
                $established = ($connections | Where-Object State -eq Established).Count
                $listening = ($connections | Where-Object State -eq Listen).Count
                $timeWait = ($connections | Where-Object State -eq TimeWait).Count
                $closeWait = ($connections | Where-Object State -eq CloseWait).Count
                $foreign = ($connections | Where-Object RemotePort -gt 0 | Select-Object -ExpandProperty RemoteAddress -Unique).Count
                $localPorts = ($connections | Where-Object State -eq Listen | Select-Object -ExpandProperty LocalPort -Unique)
                Clear-Host
                Write-Color "  ─── TCP CONNECTION MONITOR ───" "Cyan"
                Write-Color "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Gray"
                Write-Color "`n  ┌──────────────────────────────────────┐" "Cyan"
                Write-Color "  │ Total Connections:  $total".PadRight(39) + "│" "White"
                Write-Color "  │ Established:        $established".PadRight(39) + "│" ($established -gt 0 ? "Green" : "Gray")
                Write-Color "  │ Listening:          $listening".PadRight(39) + "│" "Yellow"
                Write-Color "  │ Time Wait:          $timeWait".PadRight(39) + "│" "Gray"
                Write-Color "  │ Close Wait:         $closeWait".PadRight(39) + "│" ($closeWait -gt 10 ? "Red" : "Gray")
                Write-Color "  │ Unique Remotes:     $foreign".PadRight(39) + "│" "White"
                Write-Color "  └──────────────────────────────────────┘" "Cyan"
                Write-Color "`n  Top 5 Remote Addresses:" "White"
                $connections | Where-Object RemoteAddress -ne $null | Group-Object RemoteAddress | Sort-Object Count -Descending | Select-Object -First 5 | Format-Table Count, Name -AutoSize -HideTableHeaders | Out-String | ForEach-Object { Write-Color $_ "Gray" }
                Write-Color "  Listening Ports: $($localPorts -join ', ')" "Gray"
                Start-Sleep -Seconds 3
            }
        } catch {
            Write-Color "  [!] Monitor stopped: $_" "Red"
        }
        Pause
    }
}
