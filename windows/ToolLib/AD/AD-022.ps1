Register-Tool @{
    ID          = 'AD-022'
    Name        = 'AD Backup (WBAdmin)'
    Category    = 'AD'
    Description = 'Start a System State backup using wbadmin'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Start a System State backup (includes AD) using wbadmin?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] AD Backup via WBAdmin" "Cyan"
            $backupPath = Read-Host "  Backup destination path (e.g., D:\ADBackup)"
            if ($backupPath) {
                $null = New-Item -ItemType Directory -Path $backupPath -Force -ErrorAction SilentlyContinue
                $choice = Read-Host "  [?] Start System State backup (includes AD)? (y/N)"
                if ($choice -eq 'y') {
                    Write-Color "  [*] Starting System State backup to $backupPath ..." "Cyan"
                    wbadmin start systemstatebackup -backuptarget:$backupPath -quiet
                    Write-Color "  [+] System State backup initiated" "Green"
                }
            }
        } catch {
            Write-Color "  [!] Backup failed: $_" "Red"
        }
        Pause
    }
}
