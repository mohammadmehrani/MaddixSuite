Register-Tool @{
    ID          = 'AD-028'
    Name        = 'Read-Only Domain Controller'
    Category    = 'AD'
    Description = 'Pre-create RODC account with Add-ADDomainController -ReadOnly'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Pre-create a Read-Only Domain Controller account?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Read-Only Domain Controller Setup" "Cyan"
            $domain = (Get-ADDomain -ErrorAction SilentlyContinue).DNSRoot
            if (-not $domain) { throw "Not connected to an AD domain" }

            $rodcName = Read-Host "  RODC Computer Name"
            $siteName = Read-Host "  Site Name (Default: Default-First-Site-Name)"
            if (-not $siteName) { $siteName = "Default-First-Site-Name" }

            $choice = Read-Host "  [?] Pre-create RODC account for $rodcName? (y/N)"
            if ($choice -eq 'y') {
                Write-Color "  [*] Pre-creating RODC account..." "Cyan"
                Add-ADDomainController -DomainName $domain -SiteName $siteName -ReadOnly -Name $rodcName -AllowPasswordReplicationAccount @("Administrators")
                Write-Color "  [+] RODC account pre-created successfully" "Green"
                Write-Color "  [i] Run DCPROMO /Install on server: $rodcName" "Gray"
            }
        } catch {
            Write-Color "  [!] RODC setup failed: $_" "Red"
        }
        Pause
    }
}
