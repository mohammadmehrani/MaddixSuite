Register-Tool @{
    ID          = 'DEV-006'
    Name        = 'VS Code Install'
    Category    = 'DEV'
    Description = 'Install VS Code + recommended extensions'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Install VS Code and recommended extensions?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $code = Get-Command code -ErrorAction SilentlyContinue

            if (-not $code) {
                Write-Color "  [i] VS Code not installed" "Yellow"
                $choice = Read-Host "  [?] Install VS Code via winget? (y/N)"
                if ($choice -eq 'y') {
                    Write-Color "  [*] Installing VS Code..." "Cyan"
                    winget install Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements
                    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ";" + [Environment]::GetEnvironmentVariable('Path', 'User')
                    $code = Get-Command code -ErrorAction SilentlyContinue
                    Write-Color "  [+] VS Code installed" "Green"
                } else {
                    Pause
                    return
                }
            } else {
                Write-Color "  [+] VS Code is installed" "Green"
            }

            if (-not $code) {
                Write-Color "  [!] code command not found in PATH" "Red"
                Pause
                return
            }

            $recommendedExtensions = @(
                'ms-python.python',
                'ms-vscode.powershell',
                'dbaeumer.vscode-eslint',
                'esbenp.prettier-vscode',
                'ms-azuretools.vscode-docker',
                'github.copilot',
                'github.copilot-chat',
                'eamodio.gitlens',
                'ms-vscode-remote.remote-wsl',
                'editorconfig.editorconfig',
                'christian-kohler.path-intelligence',
                'streetsidesoftware.code-spell-checker',
                'ms-vscode.vscode-typescript-next',
                'bradlc.vscode-tailwindcss'
            )

            Write-Color "  [*] Checking installed extensions..." "Cyan"
            $installed = code --list-extensions 2>$null
            $toInstall = @()

            foreach ($ext in $recommendedExtensions) {
                if ($installed -contains $ext) {
                    Write-Color "  [+] $ext already installed" "Gray"
                } else {
                    $toInstall += $ext
                }
            }

            if ($toInstall.Count -gt 0) {
                Write-Color "  [*] Installing $($toInstall.Count) extensions..." "Cyan"
                foreach ($ext in $toInstall) {
                    Write-Color "      Installing $ext..." "Gray"
                    code --install-extension $ext --force 2>$null
                }
                Write-Color "  [+] Extensions installed" "Green"
            } else {
                Write-Color "  [+] All recommended extensions already installed" "Green"
            }
        } catch {
            Write-Color "  [!] VS Code setup failed: $_" "Red"
        }
        Pause
    }
}
