Register-Tool @{
    ID          = 'NET-002'
    Name        = 'Advanced Network Scan'
    Category    = 'NET'
    Description = 'Traceroute, PathPing, TCP connection stats, bandwidth estimation'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only advanced network scan with traceroute.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── ADVANCED NETWORK SCAN ───" "Cyan"
        Write-Color "  1. Traceroute to host" "White"
        Write-Color "  2. PathPing (combined ping/trace)" "White"
        Write-Color "  3. Active TCP Connections" "White"
        Write-Color "  4. Network Statistics" "White"
        Write-Color "  0. Back" "Red"
        $c = Read-Host "> "
        switch ($c) {
            "1" { $h = Read-Host "  Host"; Test-NetConnection -TraceRoute -ComputerName $h | Out-String | ForEach-Object { Write-Color $_ "Gray" } }
            "2" { $h = Read-Host "  Host"; Start-Process -FilePath pathping.exe -ArgumentList $h -NoNewWindow -Wait }
            "3" { Get-NetTCPConnection | Group-Object State | Sort-Object Count -Descending | Format-Table Name, Count -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" } }
            "4" { Get-NetAdapterStatistics | Format-Table Name, ReceivedBytes, SentBytes -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" } }
        }
        Pause
    }
}
