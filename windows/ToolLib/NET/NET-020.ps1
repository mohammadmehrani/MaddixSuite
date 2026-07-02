Register-Tool @{
    ID          = 'NET-020'
    Name        = 'Netstat Analyzer'
    Category    = 'NET'
    Description = 'Analyze listening ports, connections, and network statistics'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only. Analyzes network connections and listening ports.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── NETSTAT ANALYZER ───" "Cyan"
        Write-Color "  1. All connections (summary)" "White"
        Write-Color "  2. Listening ports with owning processes" "White"
        Write-Color "  3. Established connections" "White"
        Write-Color "  4. Connection by process name" "White"
        Write-Color "  5. Network statistics" "White"
        Write-Color "  0. Back" "Red"
        $c = Read-Host "`n  Select option"
        switch ($c) {
            "1" {
                try {
                    $conns = Get-NetTCPConnection -ErrorAction Stop
                    $total = $conns.Count
                    $states = $conns | Group-Object State | Sort-Object Count -Descending
                    Write-Color "  Total TCP connections: $total" "White"
                    Write-Color "`n  Connection states:" "Cyan"
                    $states | Format-Table Count, Name -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
                    $udp = Get-NetUDPEndpoint -ErrorAction SilentlyContinue
                    Write-Color "  UDP endpoints: $($udp.Count)" "White"
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "2" {
                try {
                    $listeners = Get-NetTCPConnection -State Listen -ErrorAction Stop
                    Write-Color "  Listening ports ($($listeners.Count)):" "Cyan"
                    $result = foreach ($l in $listeners) {
                        $proc = Get-Process -Id $l.OwningProcess -ErrorAction SilentlyContinue
                        [PSCustomObject]@{
                            Port = $l.LocalPort
                            ProcessName = if ($proc) { $proc.ProcessName } else { "Unknown" }
                            PID = $l.OwningProcess
                            Address = $l.LocalAddress
                        }
                    }
                    $result | Sort-Object Port | Format-Table Port, ProcessName, PID, Address -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "3" {
                try {
                    $established = Get-NetTCPConnection -State Established -ErrorAction Stop
                    Write-Color "  Established connections ($($established.Count)):" "Cyan"
                    $established | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess | ForEach-Object {
                        $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
                        $pname = if ($proc) { $proc.ProcessName } else { "?" }
                        Write-Color "  $($_.LocalAddress):$($_.LocalPort) -> $($_.RemoteAddress):$($_.RemotePort) [$pname]" "Gray"
                    }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "4" {
                try {
                    $conns = Get-NetTCPConnection -ErrorAction Stop
                    $grouped = $conns | Group-Object OwningProcess
                    $result = foreach ($g in $grouped) {
                        $proc = Get-Process -Id $g.Name -ErrorAction SilentlyContinue
                        $pname = if ($proc) { $proc.ProcessName } else { "Unknown" }
                        [PSCustomObject]@{
                            Process = $pname
                            PID = $g.Name
                            Connections = $g.Count
                            Est = ($g.Group | Where-Object State -eq Established).Count
                            Listen = ($g.Group | Where-Object State -eq Listen).Count
                        }
                    }
                    $result | Sort-Object Connections -Descending | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "5" {
                try {
                    $stats = Get-NetTCPConnection -ErrorAction Stop
                    $total = $stats.Count
                    $est = ($stats | Where-Object State -eq Established).Count
                    $listen = ($stats | Where-Object State -eq Listen).Count
                    $tw = ($stats | Where-Object State -eq TimeWait).Count
                    $cw = ($stats | Where-Object State -eq CloseWait).Count
                    $fw1 = ($stats | Where-Object State -eq FinWait1).Count
                    $fw2 = ($stats | Where-Object State -eq FinWait2).Count
                    $sw = ($stats | Where-Object State -eq SynWait).Count
                    $la = ($stats | Where-Object State -eq LastAck).Count
                    Write-Color "  ┌──────────────────────────────────────┐" "Cyan"
                    Write-Color "  │         NETWORK STATISTICS           │" "Cyan"
                    Write-Color "  ├──────────────────────────────────────┤" "Cyan"
                    Write-Color "  │ Total:           $total".PadRight(39) + "│" "White"
                    Write-Color "  │ Established:     $est".PadRight(39) + "│" "Green"
                    Write-Color "  │ Listening:       $listen".PadRight(39) + "│" "Yellow"
                    Write-Color "  │ Time Wait:       $tw".PadRight(39) + "│" "Gray"
                    Write-Color "  │ Close Wait:      $cw".PadRight(39) + "│" ($cw -gt 5 ? "Red" : "Gray")
                    Write-Color "  │ Fin Wait 1:      $fw1".PadRight(39) + "│" "Gray"
                    Write-Color "  │ Fin Wait 2:      $fw2".PadRight(39) + "│" "Gray"
                    Write-Color "  │ Syn Wait:        $sw".PadRight(39) + "│" "Gray"
                    Write-Color "  │ Last Ack:        $la".PadRight(39) + "│" "Gray"
                    Write-Color "  └──────────────────────────────────────┘" "Cyan"
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
        }
        Pause
    }
}
