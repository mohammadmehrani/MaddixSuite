Register-Tool @{
    ID          = 'BAK-003'
    Name        = 'Documents Backup'
    Category    = 'BAK'
    Description = 'Robocopy Documents, Desktop, Pictures to backup dir'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Start backup of user profile folders (Documents, Desktop, Pictures)?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $backupRoot = "C:\UserDataBackup_$(Get-Date -Format 'yyyyMMdd')"
            $userProfile = [Environment]::GetFolderPath('UserProfile')
            New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

            $folders = @(
                @{Name='Documents'; Source="$userProfile\Documents"},
                @{Name='Desktop'; Source="$userProfile\Desktop"},
                @{Name='Pictures'; Source="$userProfile\Pictures"},
                @{Name='Downloads'; Source="$userProfile\Downloads"},
                @{Name='Favorites'; Source="$userProfile\Favorites"},
                @{Name='Videos'; Source="$userProfile\Videos"},
                @{Name='Music'; Source="$userProfile\Music"}
            )

            $logFile = Join-Path $backupRoot "robocopy.log"
            $totalCopied = 0

            foreach ($folder in $folders) {
                $target = Join-Path $backupRoot $folder.Name
                if (Test-Path $folder.Source) {
                    Write-Color "  [+] Copying $($folder.Name)..." "Cyan"
                    $result = robocopy $folder.Source $target /E /R:0 /W:0 /NP /NDL /NFL /LOG+:$logFile
                    $exitCode = [int]$result.ExitCode
                    if ($exitCode -le 7) {
                        Write-Color "      -> $($folder.Name) done (exit: $exitCode)" "Green"
                    } else {
                        Write-Color "      -> $($folder.Name) had errors (exit: $exitCode)" "Yellow"
                    }
                } else {
                    Write-Color "  [!] $($folder.Name) folder not found, skipping" "Yellow"
                }
            }

            $size = (Get-ChildItem $backupRoot -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $sizeMB = [math]::Round($size / 1MB, 2)
            Write-Color "  [+] Backup complete: $backupRoot ($sizeMB MB)" "Green"
        } catch {
            Write-Color "  [!] Backup failed: $_" "Red"
        }
        Pause
    }
}
