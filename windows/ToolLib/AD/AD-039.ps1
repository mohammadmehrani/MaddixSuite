Register-Tool @{
    ID          = 'AD-039'
    Name        = 'AD Federation Services (AD FS)'
    Category    = 'AD'
    Description = 'Install AD FS Federation role with management tools'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Check/install AD FS Federation role?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking AD FS status..." "Cyan"
            $adfs = Get-WindowsFeature -Name ADFS-Federation -ErrorAction SilentlyContinue

            if ($adfs -and $adfs.Installed) {
                Write-Color "  [+] AD FS is installed" "Green"
                $svc = Get-Service -Name adfssrv -ErrorAction SilentlyContinue
                if ($svc) {
                    Write-Color "  [i] AD FS Service: $($svc.Status)" "Gray"
                }
            } else {
                Write-Color "  [i] AD FS is not installed" "Yellow"
                $choice = Read-Host "  [?] Install AD FS Federation role? (y/N)"
                if ($choice -eq 'y') {
                    Write-Color "  [*] Installing AD FS Federation..." "Cyan"
                    Install-WindowsFeature -Name ADFS-Federation -IncludeManagementTools
                    Write-Color "  [+] AD FS installed" "Green"
                    Write-Color "  [i] Configure via: fsconfig.exe or AD FS Management console" "Gray"
                }
            }
        } catch {
            Write-Color "  [!] AD FS operation failed: $_" "Red"
        }
        Pause
    }
}
