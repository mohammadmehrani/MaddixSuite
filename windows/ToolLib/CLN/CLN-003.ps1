Register-Tool @{
    ID          = 'CLN-003'
    Name        = 'Log Files Cleaner'
    Category    = 'CLN'
    Description = 'Clean Windows logs, setup logs'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Clean Windows log files'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $logPaths = @(
                "$env:WINDIR\Logs",
                "$env:WINDIR\Panther",
                "$env:WINDIR\SoftwareDistribution",
                "$env:WINDIR\Temp",
                "$env:WINDIR\System32\LogFiles"
            )
            $totalSize = 0; $totalFiles = 0
            foreach ($path in $logPaths) {
                if (Test-Path $path) {
                    $logs = Get-ChildItem -Path $path -Recurse -Force -Include '*.log', '*.etl', '*.log1', '*.log2', '*.blf', '*.regtrans-ms' -ErrorAction SilentlyContinue
                    $logFiles = $logs | Where-Object { -not $_.PSIsContainer }
                    $count = $logFiles.Count
                    $size = ($logFiles | Measure-Object -Property Length -Sum).Sum
                    if ($count -gt 0) {
                        Write-Color "    $path : $count files, $([math]::Round($size/1MB,2)) MB" "Cyan"
                        $logFiles | Remove-Item -Force -ErrorAction SilentlyContinue
                        $totalSize += $size
                        $totalFiles += $count
                    }
                }
            }

            Write-Color "  [+] Event Logs:" "Yellow"
            $logNames = @('Application', 'System', 'Security', 'Setup', 'PowerShell', 'Windows PowerShell')
            foreach ($logName in $logNames) {
                try {
                    $log = Get-WmiObject -Class Win32_NTEventlogFile -Filter "LogFileName='$logName'" -ErrorAction SilentlyContinue
                    if ($log -and $log.FileSize) {
                        Write-Color "    $logName : $([math]::Round($log.FileSize/1KB,0)) KB" "Cyan"
                        $log.ClearLog()
                        Write-Color "      -> Cleared" "Green"
                    }
                } catch {}
            }
            Write-Color "  [+] Total: $totalFiles log files, $([math]::Round($totalSize/1MB,2)) MB" "Green"
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
