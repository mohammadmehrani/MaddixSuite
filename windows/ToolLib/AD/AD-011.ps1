Register-Tool @{
    ID          = 'AD-011'
    Name        = 'GPO Backup'
    Category    = 'AD'
    Description = 'Backup all Group Policy Objects to a timestamped folder'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Backup all GPOs to a timestamped folder on the desktop'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $backupPath = "$env:USERPROFILE\Desktop\MaddixSuite\GPO_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
            Write-Color "  Backing up all GPOs..." "Cyan"
            Backup-GPO -All -Path $backupPath
            Write-Color "  [+] GPOs backed up to $backupPath" "Green"
        } catch {
            Write-Color "  [!] Error backing up GPOs: $_" "Red"
        }
        Pause
    }
}
