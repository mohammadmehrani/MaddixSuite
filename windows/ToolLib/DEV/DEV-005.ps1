Register-Tool @{
    ID          = 'DEV-005'
    Name        = 'Python Setup'
    Category    = 'DEV'
    Description = 'Check/install Python, pip, venv setup'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Check/install Python and pip?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking Python..." "Cyan"
            $py = Get-Command python -ErrorAction SilentlyContinue
            $py3 = Get-Command python3 -ErrorAction SilentlyContinue
            $python = $py -or $py3
            $pyCmd = if ($py) { 'python' } elseif ($py3) { 'python3' } else { $null }

            if ($pyCmd) {
                $ver = & $pyCmd --version 2>$null
                Write-Color "  [+] $ver" "Green"
                $pip = Get-Command pip -ErrorAction SilentlyContinue
                if ($pip) {
                    $pipVer = pip --version
                    Write-Color "  [+] pip detected" "Green"
                } else {
                    Write-Color "  [i] pip not found" "Yellow"
                    $choice = Read-Host "  [?] Install pip? (y/N)"
                    if ($choice -eq 'y') {
                        & $pyCmd -m ensurepip --upgrade
                        Write-Color "  [+] pip installed" "Green"
                    }
                }

                $venvSupport = & $pyCmd -c "import venv; print('ok')" 2>$null
                if ($venvSupport) {
                    Write-Color "  [+] venv module available" "Green"
                } else {
                    Write-Color "  [i] venv module not available" "Yellow"
                }
            } else {
                Write-Color "  [i] Python not installed" "Yellow"
                $choice = Read-Host "  [?] Install Python via winget? (y/N)"
                if ($choice -eq 'y') {
                    winget install Python.Python.3.12 --accept-source-agreements --accept-package-agreements
                    Write-Color "  [+] Python 3.12 installed. Restart terminal." "Green"
                    Pause
                    return
                }
            }

            if ($pyCmd) {
                Write-Color "  [*] Checking installed packages..." "Cyan"
                $pkgs = & $pyCmd -m pip list --format=columns 2>$null
                $pkgCount = ($pkgs | Select-String -Pattern "^\w+" | Measure-Object).Count
                Write-Color "  [+] $pkgCount pip packages installed" "Gray"

                $venvDir = Join-Path $env:USERPROFILE "venvs"
                if (-not (Test-Path $venvDir)) {
                    $createVenv = Read-Host "  [?] Create a default venv at $venvDir? (y/N)"
                    if ($createVenv -eq 'y') {
                        New-Item -ItemType Directory -Path $venvDir -Force | Out-Null
                        & $pyCmd -m venv "$venvDir\default"
                        Write-Color "  [+] Venv created at $venvDir\default" "Green"
                        Write-Color "  [i] Activate with: $venvDir\default\Scripts\Activate.ps1" "Cyan"
                    }
                }
            }
        } catch {
            Write-Color "  [!] Python setup failed: $_" "Red"
        }
        Pause
    }
}
