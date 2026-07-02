Register-Tool @{
    ID          = 'DEV-003'
    Name        = 'Git Setup'
    Category    = 'DEV'
    Description = 'Install git, configure user.name and user.email'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Install/configure Git with user.name and user.email?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $git = Get-Command git -ErrorAction SilentlyContinue
            if (-not $git) {
                Write-Color "  [i] Git not installed" "Yellow"
                $choice = Read-Host "  [?] Install Git via winget? (y/N)"
                if ($choice -eq 'y') {
                    Write-Color "  [*] Installing Git..." "Cyan"
                    winget install Git.Git --accept-source-agreements --accept-package-agreements
                    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ";" + [Environment]::GetEnvironmentVariable('Path', 'User')
                    Write-Color "  [+] Git installed. If not found, restart terminal" "Green"
                } else {
                    Pause
                    return
                }
            }

            $currentName = git config --global user.name 2>$null
            $currentEmail = git config --global user.email 2>$null

            Write-Color "  [+] Current Git config:" "Cyan"
            Write-Color "      user.name  = $(if ($currentName) { $currentName } else { '(not set)' })" "Gray"
            Write-Color "      user.email = $(if ($currentEmail) { $currentEmail } else { '(not set)' })" "Gray"

            if (-not $currentName) {
                $name = Read-Host "  [?] Enter Git user.name"
                if ($name) { git config --global user.name $name }
            }
            if (-not $currentEmail) {
                $email = Read-Host "  [?] Enter Git user.email"
                if ($email) { git config --global user.email $email }
            }

            git config --global init.defaultBranch main
            git config --global core.autocrlf input
            git config --global core.safecrlf warn
            git config --global pull.rebase true
            Write-Color "  [+] Git configured with best practices" "Green"

            $finalName = git config --global user.name
            $finalEmail = git config --global user.email
            Write-Color "  [+] Git ready: $finalName <$finalEmail>" "Green"

            $gitVer = git --version
            Write-Color "  [+] $gitVer" "Gray"
        } catch {
            Write-Color "  [!] Git setup failed: $_" "Red"
        }
        Pause
    }
}
