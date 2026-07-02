Register-Tool @{
    ID          = 'AD-005'
    Name        = 'Demote Domain Controller'
    Category    = 'AD'
    Description = 'Demote this Domain Controller and remove AD from this server'
    DangerLevel = 'Dangerous'
    ConfirmMessage = 'DEMOTE this domain controller. Active Directory will be removed from this server.'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  ⚠ This will remove AD from this server!" "Yellow"
            $confirm = Read-Host "  Type YES to confirm"
            if ($confirm -ne "YES") { Write-Color "  Cancelled." "Gray"; Pause; return }

            $localPass = Read-Host "  Local administrator password" -AsSecureString
            Uninstall-ADDSDomainController -LocalAdministratorPassword $localPass -Force
            Write-Color "  [+] Demotion complete. Reboot needed." "Green"
        } catch {
            Write-Color "  [!] Error demoting DC: $_" "Red"
        }
        Pause
    }
}
