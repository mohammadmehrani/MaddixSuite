Register-Tool @{
    ID          = 'OPT-003'
    Name        = 'Disk Optimizer'
    Category    = 'OPT'
    Description = 'TRIM for SSD, defrag schedule, prefetch'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Apply disk performance optimizations'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Disk Optimization:" "Green"

            Write-Color "`n  [*] Drive Analysis:" "Yellow"
            $drives = Get-PhysicalDisk -ErrorAction SilentlyContinue
            if (-not $drives) { $drives = Get-CimInstance -ClassName Win32_DiskDrive }
            foreach ($drive in $drives) {
                $mediaType = if ($drive.MediaType) { $drive.MediaType } elseif ($drive.FriendlyName) { $drive.FriendlyName } else { 'Unknown' }
                $model = if ($drive.FriendlyName) { $drive.FriendlyName } elseif ($drive.Model) { $drive.Model } else { 'Unknown' }
                Write-Color "    $model ($mediaType)" "Cyan"
            }

            Write-Color "`n  [*] TRIM Status (SSD):" "Yellow"
            $ssds = Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -eq 4 -or $_.MediaType -eq 3 }
            if ($ssds) {
                foreach ($ssd in $ssds) {
                    $trimStatus = Get-CimInstance -Namespace root\microsoft\windows\storage -ClassName MSFT_PhysicalDisk |
                        Where-Object { $_.FriendlyName -eq $ssd.FriendlyName } |
                        Select-Object -ExpandProperty IsTrimEnabled -ErrorAction SilentlyContinue
                    Write-Color "    $($ssd.FriendlyName) : TRIM = $(if($trimStatus -eq $true){'Enabled'}else{'Disabled/Unknown'})" "Cyan"
                }

                Write-Color "`n  [*] Running manual TRIM..." "Yellow"
                Optimize-Volume -DriveLetter C -ReTrim -Verbose -ErrorAction SilentlyContinue
                Write-Color "  [+] TRIM completed" "Green"
            } else {
                Write-Color "    No SSD detected or information unavailable" "Yellow"
            }

            Write-Color "`n  [*] Defragmentation Schedule:" "Yellow"
            $sched = Get-ScheduledTask -TaskName 'Microsoft\Windows\Defrag\ScheduledDefrag' -ErrorAction SilentlyContinue
            if ($sched) {
                Write-Color "    Status: $($sched.State)" "Cyan"
                $disable = Read-Host "  [+] Disable defrag schedule (good for SSD)? (y/N)"
                if ($disable -eq 'y') {
                    Disable-ScheduledTask -TaskName 'Microsoft\Windows\Defrag\ScheduledDefrag' -ErrorAction SilentlyContinue
                    Write-Color "  [+] Defrag schedule disabled" "Green"
                }
            }

            Write-Color "`n  [*] DisableLastAccess (NTFS):" "Yellow"
            $fsutil = fsutil behavior query disablelastaccess 2>$null
            Write-Color "    $fsutil" "Cyan"
            $setLast = Read-Host "  [+] Disable NTFS last access timestamp (1 = disabled)? (y/N)"
            if ($setLast -eq 'y') { fsutil behavior set disablelastaccess 1 | Out-Null; Write-Color "  [+] Last access disabled" "Green" }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
