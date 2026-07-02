Register-Tool @{
    ID          = 'AD-019'
    Name        = 'File Server Setup'
    Category    = 'AD'
    Description = 'Install File Server role and create an SMB share'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Install File Server role and create a new SMB share'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "`n  ─── FILE SERVER SETUP ───" "Cyan"
            $fs = Get-WindowsFeature FS-FileServer -ErrorAction SilentlyContinue
            if (-not $fs.Installed) {
                $install = Read-Host "  Install File Server role? (Y/N)"
                if ($install -match '^[Yy]') {
                    Install-WindowsFeature FS-FileServer -IncludeManagementTools | Out-Null
                    Write-Color "  [+] File Server role installed." "Green"
                }
            } else {
                Write-Color "  File Server role is already installed." "Green"
            }

            $sharePath = Read-Host "  Share path (e.g., C:\Shares)"
            if ($sharePath) {
                New-Item -ItemType Directory -Path $sharePath -Force | Out-Null
                $shareName = Read-Host "  Share name"
                $desc = Read-Host "  Description"
                New-SmbShare -Name $shareName -Path $sharePath -Description $desc -FullAccess "Everyone"
                Write-Color "  [+] SMB Share created: \\$env:COMPUTERNAME\$shareName" "Green"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
