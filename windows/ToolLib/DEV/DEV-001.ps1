Register-Tool @{
    ID          = 'DEV-001'
    Name        = 'Docker Desktop Install'
    Category    = 'DEV'
    Description = 'Check/install Docker Desktop + WSL2'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Install or check Docker Desktop and WSL2?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking Docker Desktop..." "Cyan"
            $docker = Get-Command docker -ErrorAction SilentlyContinue
            if ($docker) {
                $ver = docker version --format '{{.Client.Version}}' 2>$null
                Write-Color "  [+] Docker Desktop $ver is installed" "Green"
            } else {
                Write-Color "  [i] Docker Desktop not found" "Yellow"
                $choice = Read-Host "  [?] Install Docker Desktop via winget? (y/N)"
                if ($choice -eq 'y') {
                    Write-Color "  [*] Installing Docker Desktop..." "Cyan"
                    winget install Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
                    Write-Color "  [+] Docker Desktop installed - please restart" "Green"
                }
            }

            Write-Color "  [*] Checking WSL..." "Cyan"
            $wsl = Get-Command wsl -ErrorAction SilentlyContinue
            if ($wsl) {
                $wslVer = wsl --status 2>$null
                Write-Color "  [+] WSL is installed" "Green"
            } else {
                Write-Color "  [i] WSL not installed" "Yellow"
                $choice2 = Read-Host "  [?] Install WSL? (y/N)"
                if ($choice2 -eq 'y') {
                    wsl --install
                    Write-Color "  [+] WSL installed - please reboot" "Green"
                }
            }

            if ($docker -and $wsl) {
                $compose = docker compose version 2>$null
                if ($compose) {
                    Write-Color "  [+] Docker Compose available" "Green"
                }
                Write-Color "  [+] Docker + WSL2 ready for development" "Green"
            }
        } catch {
            Write-Color "  [!] Docker/WSL check failed: $_" "Red"
        }
        Pause
    }
}
