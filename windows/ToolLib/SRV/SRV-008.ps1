Register-Tool @{
    ID          = 'SRV-008'
    Name        = 'Windows Backup Server'
    Category    = 'SRV'
    Description = 'Configure Windows Server Backup'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Configure Windows Server Backup?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking Windows Server Backup..." "Cyan"

            $wbModule = Get-Module -ListAvailable WindowsServerBackup -ErrorAction SilentlyContinue
            $wbFeature = Get-WindowsFeature -Name Windows-Server-Backup -ErrorAction SilentlyContinue

            if (-not $wbFeature -or -not $wbFeature.Installed) {
                Write-Color "  [i] Windows Server Backup feature not installed" "Yellow"
                $choice = Read-Host "  [?] Install Windows Server Backup? (y/N)"
                if ($choice -eq 'y') {
                    Install-WindowsFeature -Name Windows-Server-Backup -IncludeManagementTools
                    Import-Module WindowsServerBackup -ErrorAction SilentlyContinue
                    Write-Color "  [+] Windows Server Backup installed" "Green"
                }
            } else {
                Write-Color "  [+] Windows Server Backup is installed" "Green"
                Import-Module WindowsServerBackup -ErrorAction SilentlyContinue
            }

            $wbCmd = Get-Command Get-WBBackupSet -ErrorAction SilentlyContinue
            if ($wbCmd) {
                try {
                    $backups = Get-WBBackupSet -ErrorAction SilentlyContinue
                    if ($backups) {
                        Write-Color "  [+] Existing backups:" "Cyan"
                        $backups | Select-Object BackupSetId, VersionId,
                            @{N='StartTime';E={$_.BackupTime.StartTime}},
                            @{N='EndTime';E={$_.BackupTime.EndTime}} |
                            Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
                    } else {
                        Write-Color "  [i] No backups found" "Yellow"
                    }

                    $policy = Get-WBPolicy -ErrorAction SilentlyContinue
                    if ($policy) {
                        Write-Color "  [+] Backup policy exists" "Green"
                        $policy | Format-List -Property * | Out-String | ForEach-Object { Write-Host $_ }
                    } else {
                        Write-Color "  [i] No backup policy configured" "Yellow"
                    }
                } catch {
                    Write-Color "  [i] Backup cmdlets require elevated privileges" "Yellow"
                }
            }

            $choice2 = Read-Host "  [?] Create a scheduled system state backup? (y/N)"
            if ($choice2 -eq 'y' -and $wbCmd) {
                $destDrive = Read-Host "  [?] Destination drive letter (e.g. D:)"
                if ($destDrive) {
                    try {
                        $policy = New-WBPolicy

                        $systemState = Get-WBVolume -All | Where-Object { $_.SystemState -eq $true }
                        if ($systemState) {
                            Add-WBSystemState -Policy $policy
                            Write-Color "  [+] System state added to policy" "Green"
                        }

                        $criticalVolumes = Get-WBCriticalVolume
                        foreach ($vol in $criticalVolumes) {
                            Add-WBVolume -Policy $policy -Volume $vol
                        }
                        Write-Color "  [+] Critical volumes added to policy" "Green"

                        $backupLocation = New-WBBackupTarget -VolumePath $destDrive
                        Add-WBBackupTarget -Policy $policy -Target $backupLocation

                        $schedule = New-WBSchedule -Daily -Time "22:00"
                        Set-WBSchedule -Policy $policy -Schedule $schedule

                        Set-WBPolicy -Policy $policy -Force
                        Write-Color "  [+] Backup policy created" "Green"
                        Write-Color "  [i] Daily backup scheduled at 22:00 to $destDrive" "Cyan"
                    } catch {
                        Write-Color "  [!] Policy creation failed: $_" "Red"
                    }
                }
            }

            $choice3 = Read-Host "  [?] Start a one-time backup now? (y/N)"
            if ($choice3 -eq 'y' -and $wbCmd) {
                try {
                    $policy = Get-WBPolicy -ErrorAction SilentlyContinue
                    if ($policy) {
                        Write-Color "  [*] Starting backup..." "Cyan"
                        Start-WBBackup -Policy $policy
                        Write-Color "  [+] Backup started" "Green"
                    } else {
                        Write-Color "  [!] No policy exists. Create one first." "Yellow"
                    }
                } catch {
                    Write-Color "  [!] Backup failed: $_" "Red"
                }
            }
        } catch {
            Write-Color "  [!] Windows Backup setup failed: $_" "Red"
        }
        Pause
    }
}
