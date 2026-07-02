Register-Tool @{
    ID          = 'BAK-005'
    Name        = 'Backup Integrity Check'
    Category    = 'BAK'
    Description = 'Verify existing backup files are not corrupted'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Run integrity check on backup directories?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $backupDirs = @(
                @{Path="C:\SystemStateBackup_*"; Label="System State"},
                @{Path="C:\RegistryBackup_*"; Label="Registry"},
                @{Path="C:\UserDataBackup_*"; Label="User Data"}
            )

            $issues = @()
            $totalFiles = 0
            $totalSize = 0

            foreach ($entry in $backupDirs) {
                $dirs = Get-ChildItem -Path $entry.Path -Directory -ErrorAction SilentlyContinue
                foreach ($dir in $dirs) {
                    Write-Color "  [*] Checking $($entry.Label): $($dir.Name)" "Cyan"
                    $files = Get-ChildItem $dir.FullName -Recurse -File -ErrorAction SilentlyContinue
                    $fileCount = ($files | Measure-Object).Count
                    $totalFiles += $fileCount

                    foreach ($file in $files) {
                        $totalSize += $file.Length
                        if ($file.Length -eq 0 -and $file.Extension -ne '.log') {
                            $issues += "Empty file: $($file.FullName)"
                        }
                    }

                    $dirsCount = (Get-ChildItem $dir.FullName -Directory -ErrorAction SilentlyContinue | Measure-Object).Count
                    Write-Color "      Files: $fileCount, Folders: $dirsCount" "Gray"
                }
            }

            $sizeGB = [math]::Round($totalSize / 1GB, 2)
            Write-Color "  [+] Scanned $totalFiles files ($sizeGB GB)" "Green"

            if ($issues.Count -gt 0) {
                Write-Color "  [!] Found $($issues.Count) potential issues:" "Yellow"
                $issues | ForEach-Object { Write-Color "      - $_" "Yellow" }
            } else {
                Write-Color "  [+] All backup files appear intact (no empty files found)" "Green"
            }
        } catch {
            Write-Color "  [!] Integrity check failed: $_" "Red"
        }
        Pause
    }
}
