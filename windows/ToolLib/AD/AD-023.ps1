Register-Tool @{
    ID          = 'AD-023'
    Name        = 'AD Restore from Backup'
    Category    = 'AD'
    Description = 'Restore AD from System State backup using wbadmin'
    DangerLevel = 'Dangerous'
    ConfirmMessage = 'Restore AD from System State backup? Requires DSRM boot mode.'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] AD Restore via WBAdmin" "Cyan"
            Write-Color "  [!] Restore requires Directory Services Restore Mode (DSRM)" "Yellow"
            Write-Color "  [!] Reboot into DSRM: bcdedit /set {default} safeboot dsrepair" "Yellow"
            $choice = Read-Host "  [?] Show available backups? (y/N)"
            if ($choice -eq 'y') {
                Write-Color "  [*] Listing available backups..." "Cyan"
                wbadmin get versions
                $versionId = Read-Host "  Version ID to restore"
                if ($versionId) {
                    $authChoice = Read-Host "  [?] Authoritative restore (authsysvol)? This is destructive. (y/N)"
                    if ($authChoice -eq 'y') {
                        Write-Color "  [*] Starting System State recovery..." "Cyan"
                        wbadmin start systemstaterecovery -version:$versionId -authsysvol -quiet
                        Write-Color "  [+] AD Restore initiated" "Green"
                    }
                }
            }
        } catch {
            Write-Color "  [!] Restore operation failed: $_" "Red"
        }
        Pause
    }
}
