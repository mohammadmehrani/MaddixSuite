Register-Tool @{
    ID          = 'BAK-007'
    Name        = 'Backup Report'
    Category    = 'BAK'
    Description = 'Show last backup status, sizes, dates'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Show backup report?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $backupPatterns = @(
                @{Path="C:\SystemStateBackup_*"; Label="System State Backup"},
                @{Path="C:\RegistryBackup_*"; Label="Registry Backup"},
                @{Path="C:\UserDataBackup_*"; Label="User Data Backup"}
            )

            $report = @()
            foreach ($pattern in $backupPatterns) {
                $dirs = Get-ChildItem -Path $pattern.Path -Directory -ErrorAction SilentlyContinue `
                    | Sort-Object LastWriteTime -Descending
                $latest = $dirs | Select-Object -First 1

                if ($latest) {
                    $files = Get-ChildItem $latest.FullName -Recurse -File -ErrorAction SilentlyContinue
                    $fileCount = ($files | Measure-Object).Count
                    $sizeBytes = ($files | Measure-Object -Property Length -Sum).Sum
                    $size = switch ($sizeBytes) {
                        {$_ -gt 1GB} { "{0:N2} GB" -f ($_ / 1GB); break }
                        {$_ -gt 1MB} { "{0:N2} MB" -f ($_ / 1MB); break }
                        default { "{0:N2} KB" -f ($_ / 1KB) }
                    }
                    $allBackups = ($dirs | Measure-Object).Count

                    $report += [PSCustomObject]@{
                        Type = $pattern.Label
                        LatestBackup = $latest.Name
                        Date = $latest.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
                        Files = $fileCount
                        Size = $size
                        TotalBackups = $allBackups
                    }
                } else {
                    $report += [PSCustomObject]@{
                        Type = $pattern.Label
                        LatestBackup = "N/A"
                        Date = "Never"
                        Files = 0
                        Size = "0 B"
                        TotalBackups = 0
                    }
                }
            }

            Write-Color "  [+] Backup Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" "Cyan"
            Write-Color "  " ""
            $report | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ }

            $scheduledTask = Get-ScheduledTask -TaskName "MaddixSuite Daily Backup" -ErrorAction SilentlyContinue
            if ($scheduledTask) {
                $lastRun = $scheduledTask.LastRunTime
                $lastResult = $scheduledTask.LastTaskResult
                $status = if ($lastResult -eq 0) { "Success" } else { "Failed ($lastResult)" }
                Write-Color "  [+] Scheduled Task: MaddixSuite Daily Backup" "Cyan"
                Write-Color "      Last Run: $(if ($lastRun -eq '12/30/1899') { 'Never' } else { $lastRun.ToString('yyyy-MM-dd HH:mm') })" "Gray"
                Write-Color "      Status: $status" "Gray"
            } else {
                Write-Color "  [i] No scheduled backup task configured" "Yellow"
            }
        } catch {
            Write-Color "  [!] Report generation failed: $_" "Red"
        }
        Pause
    }
}
