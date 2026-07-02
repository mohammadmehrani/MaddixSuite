Register-Tool @{
    ID          = 'DEV-008'
    Name        = 'PowerShell 7 Install'
    Category    = 'DEV'
    Description = 'Install/update PowerShell 7'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Install or update to PowerShell 7?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking PowerShell version..." "Cyan"
            $ps7 = Get-Command pwsh -ErrorAction SilentlyContinue

            if ($ps7) {
                $ver = & pwsh --version 2>$null
                Write-Color "  [+] $ver already installed" "Green"
                $update = Read-Host "  [?] Check for updates? (y/N)"
                if ($update -eq 'y') {
                    Write-Color "  [*] Checking latest version..." "Cyan"
                    winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements
                    Write-Color "  [+] Update check complete" "Green"
                }
            } else {
                Write-Color "  [i] PowerShell 7 not installed" "Yellow"
                $choice = Read-Host "  [?] Install PowerShell 7 via winget? (y/N)"
                if ($choice -eq 'y') {
                    Write-Color "  [*] Installing PowerShell 7..." "Cyan"
                    winget install Microsoft.PowerShell --accept-source-agreements --accept-package-agreements
                    Write-Color "  [+] PowerShell 7 installed" "Green"
                    Write-Color "  [i] Launch with: pwsh" "Cyan"
                } else {
                    Write-Color "  [i] Alternative: Download from https://github.com/PowerShell/PowerShell/releases" "Gray"
                }
            }

            if ($ps7 -or (Get-Command pwsh -ErrorAction SilentlyContinue)) {
                $ps7Ver = & pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
                $ps5Ver = $PSVersionTable.PSVersion.ToString()
                Write-Color "  [+] PowerShell 5.1: $ps5Ver" "Gray"
                Write-Color "  [+] PowerShell 7: $ps7Ver" "Gray"
                Write-Color "  [i] Core CLR: $([System.Environment]::Version)" "Gray"
            }
        } catch {
            Write-Color "  [!] PowerShell 7 setup failed: $_" "Red"
        }
        Pause
    }
}
