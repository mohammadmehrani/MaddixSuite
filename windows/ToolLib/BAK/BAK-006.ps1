Register-Tool @{
    ID          = 'BAK-006'
    Name        = 'Cloud Upload Helper'
    Category    = 'BAK'
    Description = 'Upload backup files (show curl/azcopy commands)'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Show cloud upload commands for backup files?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $backupDirs = @()
            $backupDirs += Get-ChildItem -Path "C:\SystemStateBackup_*" -Directory -ErrorAction SilentlyContinue
            $backupDirs += Get-ChildItem -Path "C:\RegistryBackup_*" -Directory -ErrorAction SilentlyContinue
            $backupDirs += Get-ChildItem -Path "C:\UserDataBackup_*" -Directory -ErrorAction SilentlyContinue

            if ($backupDirs.Count -eq 0) {
                Write-Color "  [!] No backup directories found" "Yellow"
                Write-Color "  [i] Run a backup tool first (e.g. BAK-001, BAK-002, BAK-003)" "Cyan"
                Pause
                return
            }

            Write-Color "  [+] Available backup directories:" "Cyan"
            for ($i = 0; $i -lt $backupDirs.Count; $i++) {
                Write-Color "      [$i] $($backupDirs[$i].FullName)" "Gray"
            }

            $sel = Read-Host "  [?] Select index to upload (or 'all')"
            $targets = @()
            if ($sel -eq 'all') {
                $targets = $backupDirs
            } else {
                $idx = [int]$sel
                if ($idx -ge 0 -and $idx -lt $backupDirs.Count) {
                    $targets = @($backupDirs[$idx])
                } else {
                    Write-Color "  [!] Invalid selection" "Red"
                    Pause
                    return
                }
            }

            Write-Color "  `n  [+] Upload commands (AzCopy / curl):" "Cyan"
            Write-Color "  "  ""

            foreach ($t in $targets) {
                $zipName = "$($t.Name).zip"
                Write-Color "  -- $($t.Name) --" "Yellow"
                Write-Color "  `$zip = `"$env:TEMP\$zipName`"" "White"
                Write-Color "  Compress-Archive -Path `"$($t.FullName)`" -DestinationPath `$zip" "White"
                Write-Color "  # AzCopy:" "Gray"
                Write-Color "  azcopy copy `$zip `"https://<storage>.blob.core.windows.net/<container>/$zipName`"" "White"
                Write-Color "  # cURL (presigned URL):" "Gray"
                Write-Color "  curl -T `$zip `"<presigned-url>`"" "White"
                Write-Color "  " ""
            }

            Write-Color "  [i] Replace <...> placeholders with your cloud provider details" "Gray"
        } catch {
            Write-Color "  [!] Failed: $_" "Red"
        }
        Pause
    }
}
