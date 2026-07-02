Register-Tool @{
    ID          = 'SEC-010'
    Name        = 'Windows Firewall Log Analyzer'
    Category    = 'SEC'
    Description = 'Analyze firewall dropped packets'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Analyze Windows Firewall dropped packet logs'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $logPath = "$env:SystemRoot\System32\LogFiles\Firewall\pfirewall.log"
            if (-not (Test-Path $logPath)) {
                Write-Color "  [!] Firewall log not found at $logPath" "Yellow"
                Write-Color "  [+] Enable logging via: netsh advfirewall set allprofiles logging filename '$logPath'" "Cyan"
                $enable = Read-Host "  [+] Enable firewall logging now? (y/N)"
                if ($enable -eq 'y') {
                    netsh advfirewall set allprofiles logging filename "$logPath"
                    netsh advfirewall set allprofiles logging droppedconnections enable
                    Write-Color "  [+] Firewall logging enabled" "Green"
                }
                Pause
                return
            }

            Write-Color "  [+] Analyzing Windows Firewall Log..." "Green"
            $log = Get-Content -Path $logPath -ErrorAction SilentlyContinue

            $dropped = $log | Where-Object { $_ -match 'DROP' }
            $totalLines = ($log | Where-Object { $_ -notmatch '^#' }).Count

            Write-Color "    Total log entries  : $totalLines" "Cyan"
            Write-Color "    Dropped packets    : $($dropped.Count)" "Red"

            if ($dropped.Count -gt 0) {
                Write-Color "`n  [+] Top Source IPs (Dropped):" "Yellow"
                $dropped | ForEach-Object {
                    $parts = $_ -split ' '
                    if ($parts.Length -ge 7) { [PSCustomObject]@{ SrcIP = $parts[4]; DstIP = $parts[5]; DstPort = $parts[7]; Protocol = $parts[8]; Direction = $parts[6] } }
                } | Group-Object SrcIP | Sort-Object Count -Descending | Select-Object Count, Name -First 20 | Format-Table -AutoSize

                Write-Color "`n  [+] Top Destination Ports (Dropped):" "Yellow"
                $dropped | ForEach-Object {
                    $parts = $_ -split ' '
                    if ($parts.Length -ge 8) { [PSCustomObject]@{ Port = $parts[7] } }
                } | Group-Object Port | Sort-Object Count -Descending | Select-Object Count, Name -First 15 | Format-Table -AutoSize

                Write-Color "`n  [+] Last 10 dropped entries:" "Yellow"
                $dropped | Select-Object -Last 10 | ForEach-Object { Write-Color "    $_" "Cyan" }
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
