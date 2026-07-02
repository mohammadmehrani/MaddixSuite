Register-Tool @{
    ID          = 'AD-003'
    Name        = 'Create New Domain'
    Category    = 'AD'
    Description = 'Create a new Active Directory domain in a new forest'
    DangerLevel = 'Dangerous'
    ConfirmMessage = 'Create a new AD forest and domain. This will promote this server to a Domain Controller and reboot.'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $cs = Get-CimInstance Win32_ComputerSystem
            $adRole = (Get-WindowsFeature AD-Domain-Services -ErrorAction SilentlyContinue).Installed
            $adDomain = if ($adRole) { try { (Get-ADDomain -ErrorAction Stop).DNSRoot } catch { $null } } else { $null }
            if ($adDomain) { Write-Color "  [!] Already in a domain: $adDomain" "Red"; Pause; return }

            if (-not $adRole) {
                Write-Color "  Installing AD DS role first..." "Cyan"
                Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools | Out-Null
                Write-Color "  [+] AD DS installed." "Green"
            }

            $dom = Read-Host "  Domain name (e.g., maddix.local)"
            $pass = Read-Host "  DSRM Password" -AsSecureString
            $mode = Read-Host "  Forest mode (Default: WinThreshold)"
            if (-not $mode) { $mode = "WinThreshold" }

            Write-Color "  Creating domain $dom. This will reboot..." "Cyan"
            Install-ADDSForest -DomainName $dom -SafeModeAdministratorPassword $pass -ForestMode $mode -DomainMode $mode -Force
            Write-Color "  [+] Domain created. Rebooting..." "Green"
        } catch {
            Write-Color "  [!] Error creating domain: $_" "Red"
        }
        Pause
    }
}
