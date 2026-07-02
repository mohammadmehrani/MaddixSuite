Register-Tool @{
    ID          = 'SRV-004'
    Name        = 'Performance Monitor'
    Category    = 'SRV'
    Description = 'Start perfmon data collector sets'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Start Performance Monitor data collector sets?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking Performance Monitor configuration..." "Cyan"

            $collectorSets = Get-WmiObject -Namespace root\cimv2 -Class Win32_PerfFormattedData_PerfOS_System -ErrorAction SilentlyContinue
            if ($collectorSets) {
                Write-Color "  [+] Performance counters available" "Green"
            }

            $userSets = Get-WmiObject -Namespace root\Microsoft\Windows\Diagnostics-PLA -Class PLA_DataCollectorSet -ErrorAction SilentlyContinue
            if ($userSets) {
                Write-Color "  [+] Existing Data Collector Sets:" "Cyan"
                $userSets | Select-Object Name, Status | Format-Table -AutoSize |
                    Out-String | ForEach-Object { Write-Host $_ }
            }

            Write-Color "  [*] Available built-in Data Collector Sets:" "Cyan"
            $builtInPath = "$env:SystemDrive\PerfLogs\Admin"
            $builtInSets = @(
                "System\System Performance",
                "System\System Diagnostics",
                "System\Active Directory Diagnostics",
                "System\Network Diagnostics"
            )

            foreach ($set in $builtInSets) {
                $exists = Get-WmiObject -Namespace root\Microsoft\Windows\Diagnostics-PLA `
                    -Class PLA_DataCollectorSet -Filter "Name='$set'" -ErrorAction SilentlyContinue
                if ($exists) {
                    Write-Color "      [+] $set - available" "Gray"
                } else {
                    Write-Color "      [i] $set - can be created" "Gray"
                }
            }

            $choice = Read-Host "  [?] Start System Performance data collector? (y/N)"
            if ($choice -eq 'y') {
                $logDir = "$env:SystemDrive\PerfLogs\Admin\SystemPerformance_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null

                $perfCounters = @(
                    '\Processor(_Total)\% Processor Time',
                    '\Memory\Available MBytes',
                    '\Memory\Pages/sec',
                    '\PhysicalDisk(_Total)\% Disk Time',
                    '\PhysicalDisk(_Total)\Avg. Disk Queue Length',
                    '\Network Interface(*)\Bytes Total/sec'
                )

                $sampleInterval = 5
                $duration = 300
                $samples = $duration / $sampleInterval

                Write-Color "  [*] Collecting performance data for $duration seconds..." "Cyan"
                Write-Color "  [*] Log file: $logDir\perf_log.blg" "Gray"

                $counters = $perfCounters -join ' '
                logman create counter "MaddixSuite_PerfMon" `
                    -o "$logDir\perf_log.blg" `
                    -cf $null `
                    -c $perfCounters `
                    -si $sampleInterval `
                    -max $samples `
                    -f bincirc `
                    --v

                logman start "MaddixSuite_PerfMon"
                Write-Color "  [+] Performance data collection started for $duration seconds" "Green"
                Write-Color "  [i] Run 'logman stop MaddixSuite_PerfMon' to stop early" "Cyan"

                Start-Sleep -Seconds $duration
                logman stop "MaddixSuite_PerfMon" 2>$null
                logman delete "MaddixSuite_PerfMon" 2>$null
                Write-Color "  [+] Collection complete. Report saved to $logDir" "Green"
            }

            $choice2 = Read-Host "  [?] Show real-time CPU/Memory snapshot? (y/N)"
            if ($choice2 -eq 'y') {
                $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
                $os = Get-CimInstance Win32_OperatingSystem
                $freeMem = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
                $totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
                $usedMem = $totalMem - $freeMem

                Write-Color "  [+] Real-time Snapshot:" "Cyan"
                Write-Color "      CPU Usage:       $($cpu.Average)%" "Gray"
                Write-Color "      Memory:          $usedMem GB / $totalMem GB used" "Gray"
                Write-Color "      Free Memory:     $freeMem GB" "Gray"

                $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
                foreach ($disk in $disks) {
                    $pct = [math]::Round(($disk.Size - $disk.FreeSpace) / $disk.Size * 100, 1)
                    Write-Color "      $($disk.DeviceID):  $pct% used ($([math]::Round($disk.FreeSpace/1GB,1)) GB free)" "Gray"
                }
            }
        } catch {
            Write-Color "  [!] Performance Monitor failed: $_" "Red"
        }
        Pause
    }
}
