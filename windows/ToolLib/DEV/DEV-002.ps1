Register-Tool @{
    ID          = 'DEV-002'
    Name        = 'WSL2 Setup'
    Category    = 'DEV'
    Description = 'Check/install WSL2, set default version'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Set up WSL2 with default version 2?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking WSL status..." "Cyan"
            $wsl = Get-Command wsl -ErrorAction SilentlyContinue
            if (-not $wsl) {
                Write-Color "  [i] WSL not installed" "Yellow"
                $choice = Read-Host "  [?] Install WSL? (y/N)"
                if ($choice -eq 'y') {
                    Write-Color "  [*] Installing WSL..." "Cyan"
                    wsl --install
                    Write-Color "  [+] WSL installed. Please reboot and re-run this tool" "Green"
                    Pause
                    return
                }
                Pause
                return
            }

            Write-Color "  [*] Checking WSL version..." "Cyan"
            $wslList = wsl -l -v 2>$null
            Write-Color "  [+] Current WSL state:" "Gray"
            $wslList | ForEach-Object { Write-Host "      $_" }

            Write-Color "  [*] Setting WSL 2 as default..." "Cyan"
            wsl --set-default-version 2
            Write-Color "  [+] Default WSL version set to 2" "Green"

            $distros = wsl -l --quiet 2>$null
            if ($distros) {
                foreach ($distro in $distros) {
                    if ($distro.Trim() -ne '') {
                        Write-Color "  [*] Setting $($distro.Trim()) to WSL 2..." "Gray"
                        wsl --set-version $distro.Trim() 2 2>$null
                    }
                }
                Write-Color "  [+] All distros set to WSL 2" "Green"
            } else {
                Write-Color "  [i] No WSL distros installed" "Yellow"
                $choice2 = Read-Host "  [?] Install Ubuntu? (y/N)"
                if ($choice2 -eq 'y') {
                    wsl --install -d Ubuntu
                    Write-Color "  [+] Ubuntu installation started" "Green"
                }
            }

            wsl --status 2>$null
        } catch {
            Write-Color "  [!] WSL setup failed: $_" "Red"
        }
        Pause
    }
}
