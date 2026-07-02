Register-Tool @{
    ID          = 'DEV-010'
    Name        = 'Chocolatey Package Manager'
    Category    = 'DEV'
    Description = 'Install Chocolatey, list installed packages'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Install or check Chocolatey package manager?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $choco = Get-Command choco -ErrorAction SilentlyContinue

            if (-not $choco) {
                Write-Color "  [i] Chocolatey not installed" "Yellow"
                $choice = Read-Host "  [?] Install Chocolatey? (y/N)"
                if ($choice -eq 'y') {
                    Write-Color "  [*] Installing Chocolatey..." "Cyan"
                    Set-ExecutionPolicy Bypass -Scope Process -Force
                    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                    Write-Color "  [+] Chocolatey installed. Restart terminal if needed." "Green"
                    $choco = Get-Command choco -ErrorAction SilentlyContinue
                }
            } else {
                Write-Color "  [+] Chocolatey is installed" "Green"
            }

            if ($choco) {
                $ver = choco --version
                Write-Color "  [+] Version: $ver" "Gray"

                $choice2 = Read-Host "  [?] List installed Chocolatey packages? (y/N)"
                if ($choice2 -eq 'y') {
                    $packages = choco list --local-only 2>$null
                    if ($packages) {
                        $pkgLines = $packages | Select-String -Pattern "\S+\s+\S+"
                        if ($pkgLines) {
                            Write-Color "  [+] Installed packages:" "Cyan"
                            $pkgLines | ForEach-Object {
                                Write-Host "      $_".Trim()
                            }
                            Write-Color "  [+] Total: $($pkgLines.Count)" "Green"
                        } else {
                            Write-Color "  [i] No Chocolatey packages installed locally" "Gray"
                        }
                    }
                }

                $choice3 = Read-Host "  [?] Upgrade all outdated packages? (y/N)"
                if ($choice3 -eq 'y') {
                    Write-Color "  [*] Checking for outdated packages..." "Cyan"
                    choco outdated
                    $confirm = Read-Host "  [?] Proceed with upgrade all? (y/N)"
                    if ($confirm -eq 'y') {
                        choco upgrade all -y
                        Write-Color "  [+] Upgrade complete" "Green"
                    }
                }
            }
        } catch {
            Write-Color "  [!] Chocolatey setup failed: $_" "Red"
        }
        Pause
    }
}
