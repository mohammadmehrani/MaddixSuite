Register-Tool @{
    ID          = 'AD-002'
    Name        = 'Install AD Domain Services'
    Category    = 'AD'
    Description = 'Install AD Domain Services role and management tools'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Install AD Domain Services role with management tools on this server'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  Installing AD DS + Management Tools..." "Cyan"
            Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools | Out-Null
            Write-Color "  [+] AD DS installed." "Green"
            $reboot = Read-Host "  Reboot now? (Y/N)"
            if ($reboot -match '^[Yy]') { Restart-Computer -Force }
        } catch {
            Write-Color "  [!] Error installing AD DS: $_" "Red"
        }
        Pause
    }
}
