Register-Tool @{
    ID          = 'SYS-006'
    Name        = 'Disk Health Check (SMART)'
    Category    = 'SYS'
    Description = 'Check disk SMART status, health, temperature, and predicted failures'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only. Queries SMART data from all physical drives.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        $drives = Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue
        if (-not $drives) {
            $drives = Get-PhysicalDisk -ErrorAction SilentlyContinue
            if ($drives) {
                foreach ($d in $drives) {
                    $health = Get-PhysicalDisk -UniqueId $d.UniqueId | Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus, Size
                    Write-Color "  $($health.FriendlyName) [$($health.MediaType)]" "White"
                    Write-Color "    Health: $($health.HealthStatus) | Status: $($health.OperationalStatus)" "Gray"
                    Write-Color "    Size: $([math]::Round($health.Size/1TB,2)) TB" "Gray"
                }
            } else {
                $disks = Get-CimInstance Win32_DiskDrive
                foreach ($d in $disks) {
                    Write-Color "  $($d.Model) ($($d.Size/1GB -as [int]) GB)" "White"
                    Write-Color "    Status: $($d.Status)" "Gray"
                }
            }
        } else {
            foreach ($d in $drives) {
                Write-Color "  Drive: $($d.InstanceName)" "White"
                Write-Color "    Predict Failure: $($d.PredictFailure)" "Green"
                if ($d.PredictFailure -and $d.PredictFailure -eq $true) {
                    Write-Color "    ⚠ FAILURE PREDICTED - BACKUP IMMEDIATELY!" "Red"
                }
            }
        }
        Write-Color "  [+] Disk health check complete." "Green"
        Write-Color "  Run 'wmic diskdrive get status' for detailed info." "Gray"
    }
}
