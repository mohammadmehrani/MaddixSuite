Register-Tool @{
    ID          = 'BAK-008'
    Name        = 'Restore from Backup'
    Category    = 'BAK'
    Description = 'Interactive file/folder restore from backup'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Start interactive restore from backup?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $backupDirs = @()
            $backupDirs += Get-ChildItem -Path "C:\UserDataBackup_*" -Directory -ErrorAction SilentlyContinue
            $backupDirs += Get-ChildItem -Path "C:\SystemStateBackup_*" -Directory -ErrorAction SilentlyContinue
            $backupDirs += Get-ChildItem -Path "C:\RegistryBackup_*" -Directory -ErrorAction SilentlyContinue

            if ($backupDirs.Count -eq 0) {
                Write-Color "  [!] No backup directories found" "Yellow"
                Pause
                return
            }

            Write-Color "  [+] Available backups:" "Cyan"
            for ($i = 0; $i -lt $backupDirs.Count; $i++) {
                Write-Color "      [$i] $($backupDirs[$i].Name) ($($backupDirs[$i].LastWriteTime.ToString('yyyy-MM-dd')))" "Gray"
            }

            $sel = Read-Host "  [?] Select backup index to restore from"
            $idx = [int]$sel
            if ($idx -lt 0 -or $idx -ge $backupDirs.Count) {
                Write-Color "  [!] Invalid selection" "Red"
                Pause
                return
            }

            $source = $backupDirs[$idx]
            Write-Color "  [+] Selected: $($source.FullName)" "Green"

            $userProfile = [Environment]::GetFolderPath('UserProfile')
            $restoreTargets = @(
                @{Name='Documents'; RelPath='Documents'},
                @{Name='Desktop'; RelPath='Desktop'},
                @{Name='Pictures'; RelPath='Pictures'}
            )

            $subDirs = Get-ChildItem $source.FullName -Directory -ErrorAction SilentlyContinue
            Write-Color "  [+] Sub-folders in backup:" "Cyan"
            for ($i = 0; $i -lt $subDirs.Count; $i++) {
                $sub = $subDirs[$i]
                $size = (Get-ChildItem $sub.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $sizeStr = if ($size -gt 1MB) { "{0:N2} MB" -f ($size/1MB) } else { "{0:N2} KB" -f ($size/1KB) }
                Write-Color "      [$i] $($sub.Name) ($sizeStr)" "Gray"
            }

            $subSel = Read-Host "  [?] Select sub-folder index to restore (or 'all')"
            $itemsToRestore = @()
            if ($subSel -eq 'all') {
                $itemsToRestore = $subDirs
            } else {
                $subIdx = [int]$subSel
                if ($subIdx -ge 0 -and $subIdx -lt $subDirs.Count) {
                    $itemsToRestore = @($subDirs[$subIdx])
                } else {
                    Write-Color "  [!] Invalid selection" "Red"
                    Pause
                    return
                }
            }

            $destBase = $userProfile
            foreach ($item in $itemsToRestore) {
                $destPath = Join-Path $destBase $item.Name
                Write-Color "  [+] Restoring $($item.Name) -> $destPath" "Cyan"
                robocopy $item.FullName $destPath /E /R:1 /W:1 /NP /NDL | Out-Null
                Write-Color "      -> Done" "Green"
            }

            Write-Color "  [+] Restore complete" "Green"
        } catch {
            Write-Color "  [!] Restore failed: $_" "Red"
        }
        Pause
    }
}
