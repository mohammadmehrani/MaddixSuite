Register-Tool @{
    ID          = 'AD-012'
    Name        = 'GPO Restore'
    Category    = 'AD'
    Description = 'Restore all GPOs from a backup folder'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Restore all GPOs from a specified backup path'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $d = Read-Host "  Backup path"
            if (-not (Test-Path $d)) { Write-Color "  Path not found." "Red"; Pause; return }
            Write-Color "  Restoring GPOs from $d..." "Cyan"
            Restore-GPO -All -Path $d
            Write-Color "  [+] GPOs restored." "Green"
        } catch {
            Write-Color "  [!] Error restoring GPOs: $_" "Red"
        }
        Pause
    }
}
