Register-Tool @{
    ID          = 'NET-014'
    Name        = 'Bandwidth Monitor'
    Category    = 'NET'
    Description = 'Monitor interface bandwidth usage in real time'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only. Monitors network interface bandwidth in real time.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── BANDWIDTH MONITOR ───" "Cyan"
        try {
            $adapters = Get-NetAdapter -Physical | Where-Object Status -eq Up | Sort-Object Name
            if (-not $adapters) {
                Write-Color "  [!] No active adapters found." "Red"
                Pause
                return
            }
            $i = 1
            $aList = @()
            foreach ($a in $adapters) {
                Write-Color "  $i. $($a.Name) ($($a.LinkSpeed))" "White"
                $aList += $a
                $i++
            }
            $sel = Read-Host "`n  Select adapter (number)"
            $selected = $aList[[int]$sel - 1]
            $ifIndex = $selected.ifIndex
            Write-Color "`n  Monitoring $($selected.Name) — press Ctrl+C to exit" "Yellow"
            Write-Color "  Interface speed: $($selected.LinkSpeed)" "Gray"
            $prevRx = 0; $prevTx = 0; $firstRun = $true
            while ($true) {
                try {
                    $stats = Get-NetAdapterStatistics -Name $selected.Name -ErrorAction Stop
                    $rx = $stats.ReceivedBytes
                    $tx = $stats.SentBytes
                    if (-not $firstRun) {
                        $rxSpeed = (($rx - $prevRx) / 1KB)
                        $txSpeed = (($tx - $prevTx) / 1KB)
                        $rxUnit = "KB/s"
                        $txUnit = "KB/s"
                        if ($rxSpeed -gt 1024) { $rxSpeed = $rxSpeed / 1MB; $rxUnit = "MB/s" }
                        if ($txSpeed -gt 1024) { $txSpeed = $txSpeed / 1MB; $txUnit = "MB/s" }
                        Clear-Host
                        Write-Color "  ─── BANDWIDTH MONITOR ───" "Cyan"
                        Write-Color "  Adapter: $($selected.Name)" "White"
                        Write-Color "  Speed:   $($selected.LinkSpeed)" "Gray"
                        Write-Color "  Time:    $(Get-Date -Format 'HH:mm:ss')" "Gray"
                        Write-Color "`n  ┌──────────────────────────────────────┐" "Cyan"
                        Write-Color "  │  DOWNLOAD  │  UPLOAD  │  TOTAL        │" "White"
                        Write-Color "  ├──────────────────────────────────────┤" "Cyan"
                        Write-Color "  │  $('{0:N2}' -f $rxSpeed) $rxUnit".PadRight(12) + "│  $('{0:N2}' -f $txSpeed) $txUnit".PadRight(10) + "│  $('{0:N2}' -f ($rxSpeed+$txSpeed)) $rxUnit".PadRight(11) + "│" ($rxSpeed -gt 1024 ? "Yellow" : "Green")
                        Write-Color "  └──────────────────────────────────────┘" "Cyan"
                        $totalRxMb = $rx / 1MB
                        $totalTxMb = $tx / 1MB
                        Write-Color "  Total RX: $('{0:N2}' -f $totalRxMb) MB" "Gray"
                        Write-Color "  Total TX: $('{0:N2}' -f $totalTxMb) MB" "Gray"
                        Write-Color "`n  Refreshing every 1s — Ctrl+C to stop" "DarkGray"
                    }
                    $prevRx = $rx; $prevTx = $tx; $firstRun = $false
                    Start-Sleep -Seconds 1
                } catch {
                    Write-Color "  [!] Monitor error: $_" "Red"
                    break
                }
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
