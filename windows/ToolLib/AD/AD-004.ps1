Register-Tool @{
    ID          = 'AD-004'
    Name        = 'Add Domain Controller'
    Category    = 'AD'
    Description = 'Add this server as an additional Domain Controller to an existing domain'
    DangerLevel = 'Dangerous'
    ConfirmMessage = 'Promote this server to a Domain Controller in an existing domain'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $dom = Read-Host "  Domain name"
            $pass = Read-Host "  DSRM Password" -AsSecureString
            Write-Color "  Adding DC to $dom. Provide domain admin credentials..." "Cyan"
            Install-ADDSDomainController -DomainName $dom -SafeModeAdministratorPassword $pass -Credential (Get-Credential) -Force
            Write-Color "  [+] DC promotion complete." "Green"
        } catch {
            Write-Color "  [!] Error adding DC: $_" "Red"
        }
        Pause
    }
}
