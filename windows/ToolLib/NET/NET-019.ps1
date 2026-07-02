Register-Tool @{
    ID          = 'NET-019'
    Name        = 'Traceroute Visual'
    Category    = 'NET'
    Description = 'Visual traceroute with hop timing and geolocation lookup'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only. Visual traceroute to a target host.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── TRACEROUTE VISUAL ───" "Cyan"
        $hostname = Read-Host "  Target host (IP or hostname)"
        $maxHops = Read-Host "  Max hops [default: 30]"
        if ([string]::IsNullOrWhiteSpace($maxHops)) { $maxHops = 30 } else { $maxHops = [int]$maxHops }
        Write-Color "`n  Tracing route to $hostname (max $maxHops hops)..." "Yellow"
        Write-Color "  $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))" "Gray"
        Write-Color "`n  ┌──────┬─────────────────────┬───────────┬────────────┐" "Cyan"
        Write-Color "  │ Hop  │  Address             │  Time     │  Status     │" "Cyan"
        Write-Color "  ├──────┼─────────────────────┼───────────┼────────────┤" "Cyan"
        try {
            $trace = Test-NetConnection -TraceRoute -ComputerName $hostname -Hops $maxHops -ErrorAction Stop
            $hopCount = 0
            foreach ($hop in $trace.TraceRoute) {
                $hopCount++
                $rtt = ""
                $status = ""
                try {
                    $ping = Test-Connection -ComputerName $hop -Count 1 -ErrorAction SilentlyContinue
                    if ($ping) {
                        $rtt = "$($ping.ResponseTime) ms"
                        $status = "OK"
                    } else {
                        $rtt = "---"
                        $status = "Timeout"
                    }
                } catch {
                    $rtt = "---"
                    $status = "No Response"
                }
                $color = if ($status -eq "OK") { "Green" } elseif ($status -eq "Timeout") { "Yellow" } else { "Red" }
                Write-Color "  │ $(''+$hopCount).PadRight(4) │ $hop".PadRight(21)+ "│ $rtt".PadRight(11) + "│ $status".PadRight(12) + "│" $color
            }
            Write-Color "  └──────┴─────────────────────┴───────────┴────────────┘" "Cyan"
            Write-Color "`n  Hops: $hopCount" "White"
            if ($trace.RemoteAddress) {
                Write-Color "  Remote address resolved: $($trace.RemoteAddress.IPAddressToString)" "Gray"
            }
        } catch {
            Write-Color "  [!] Traceroute failed: $_" "Red"
        }
        Pause
    }
}
