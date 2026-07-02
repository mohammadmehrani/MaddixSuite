Register-Tool @{
    ID          = 'AD-016'
    Name        = 'AD Recycle Bin'
    Category    = 'AD'
    Description = 'Enable AD Recycle Bin, list and restore deleted objects'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Check AD Recycle Bin status, optionally enable it and restore deleted objects'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "`n  ─── AD RECYCLE BIN ───" "Cyan"
            $fb = (Get-ADOptionalFeature -Filter "Name -like '*Recycle*'").EnabledScopes
            if ($fb) {
                Write-Color "  Recycle Bin: ENABLED" "Green"
            } else {
                Write-Color "  Recycle Bin: DISABLED" "Yellow"
                $enable = Read-Host "  Enable AD Recycle Bin? This cannot be undone. (Y/N)"
                if ($enable -match '^[Yy]') {
                    Enable-ADOptionalFeature -Identity "Recycle Bin Feature" -Scope ForestOrConfigurationSet -Target (Get-ADForest).Name -Server (Get-ADDomainController).HostName
                    Write-Color "  [+] Recycle Bin enabled" "Green"
                }
            }

            $restore = Read-Host "`n  List and restore deleted objects? (Y/N)"
            if ($restore -match '^[Yy]') {
                $del = Get-ADObject -Filter 'isDeleted -eq $true' -IncludeDeletedObjects -Properties LastKnownParent
                $del | Format-Table Name, Deleted, LastKnownParent -AutoSize
                $r = Read-Host "  DN to restore (or Enter to skip)"
                if ($r) {
                    Restore-ADObject -Identity $r
                    Write-Color "  [+] Restored $r" "Green"
                }
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
