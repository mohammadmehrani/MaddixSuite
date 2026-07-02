Register-Tool @{
    ID          = 'SRV-005'
    Name        = 'Event Forwarding Setup'
    Category    = 'SRV'
    Description = 'Configure Windows Event Forwarding'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Configure Windows Event Forwarding (WEF) subscription?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking Windows Event Forwarding configuration..." "Cyan"

            $wecSvc = Get-Service -Name Wecsvc -ErrorAction SilentlyContinue
            if (-not $wecSvc) {
                Write-Color "  [i] Windows Event Collector service not available" "Yellow"
                Write-Color "  [i] This feature requires Windows Server or Windows Enterprise/Education" "Gray"
                Pause
                return
            }

            Write-Color "  [+] Windows Event Collector service: $($wecSvc.Status)" "Cyan"

            if ($wecSvc.Status -ne 'Running') {
                Write-Color "  [*] Starting Windows Event Collector service..." "Cyan"
                Set-Service -Name Wecsvc -StartupType Automatic
                Start-Service -Name Wecsvc
                Write-Color "  [+] Service started" "Green"
            }

            $subscriptions = Get-WmiObject -Namespace root\Microsoft\Windows\EventCollector `
                -Class EventCollector_Subscription -ErrorAction SilentlyContinue

            if ($subscriptions) {
                Write-Color "  [+] Existing subscriptions:" "Cyan"
                $subscriptions | Select-Object Name, EventSources, DeliveryMode |
                    Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
            } else {
                Write-Color "  [i] No subscriptions configured" "Yellow"
            }

            $choice = Read-Host "  [?] Create a basic WEF subscription (ForwardedEvents)? (y/N)"
            if ($choice -eq 'y') {
                $subName = Read-Host "  [?] Subscription name (default: MaddixSuite-WEF)"
                if (-not $subName) { $subName = "MaddixSuite-WEF" }

                $sourceComputers = Read-Host "  [?] Source computers (comma-separated, or '*' for all)"
                if (-not $sourceComputers) { $sourceComputers = "*" }

                Write-Color "  [*] Creating subscription '$subName'..." "Cyan"

                $query = @"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">*[System[(EventID=4624 or EventID=4625 or EventID=4634)]]</Select>
    <Select Path="System">*[System[(EventID=1074 or EventID=6005 or EventID=6006)]]</Select>
  </Query>
</QueryList>
"@
                $queryFile = "$env:TEMP\wef_query.xml"
                $query | Out-File $queryFile -Encoding utf8

                wecutil cs $subName /q "$queryFile" /s:$sourceComputers /cm:"All" 2>$null

                if ($?) {
                    wecutil ss $subName /ms:"MinLatency" /ac:"Rpc" 2>$null
                    Write-Color "  [+] Subscription '$subName' created" "Green"
                    Write-Color "  [i] Events will appear in Forwarded Events log" "Cyan"
                } else {
                    Write-Color "  [!] Failed to create subscription. Ensure WinRM is configured." "Yellow"
                    Write-Color "  [i] Run: winrm quickconfig" "Gray"
                }

                Remove-Item $queryFile -Force -ErrorAction SilentlyContinue
            }

            $choice2 = Read-Host "  [?] Check WinRM listener status? (y/N)"
            if ($choice2 -eq 'y') {
                $winrmStatus = winrm e winrm/config/listener 2>$null
                if ($winrmStatus) {
                    Write-Color "  [+] WinRM listeners:" "Green"
                    $winrmStatus | ForEach-Object { Write-Host "      $_" }
                } else {
                    Write-Color "  [i] No WinRM listeners configured" "Yellow"
                    $conf = Read-Host "  [?] Configure WinRM? (y/N)"
                    if ($conf -eq 'y') {
                        winrm quickconfig -quiet
                        Write-Color "  [+] WinRM configured" "Green"
                        netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in protocol=tcp localport=5985 action=allow
                        Write-Color "  [+] Firewall rule added for WinRM" "Green"
                    }
                }
            }
        } catch {
            Write-Color "  [!] Event Forwarding setup failed: $_" "Red"
        }
        Pause
    }
}
