Register-Tool @{
    ID          = 'AD-018'
    Name        = 'Certificate Services (AD CS)'
    Category    = 'AD'
    Description = 'Install Active Directory Certificate Services role'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Install AD Certificate Services role with management tools'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "`n  ─── CERTIFICATE SERVICES ───" "Cyan"
            $adcs = Get-WindowsFeature AD-Certificate -ErrorAction SilentlyContinue
            if (-not $adcs.Installed) {
                Write-Color "  AD CS is not installed." "Yellow"
                $install = Read-Host "  Install AD Certificate Services? (Y/N)"
                if ($install -match '^[Yy]') {
                    Install-WindowsFeature AD-Certificate -IncludeManagementTools | Out-Null
                    Write-Color "  [+] AD CS installed. Configure via: certsrv.msc" "Green"
                }
            } else {
                Write-Color "  AD CS is already installed." "Green"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
