Register-Tool @{
    ID          = 'DEV-004'
    Name        = 'Node.js Install'
    Category    = 'DEV'
    Description = 'Install Node.js via winget or nvm-windows'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Install Node.js (winget) or nvm-windows?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $node = Get-Command node -ErrorAction SilentlyContinue
            $npm = Get-Command npm -ErrorAction SilentlyContinue
            $nvm = Get-Command nvm -ErrorAction SilentlyContinue

            Write-Color "  [*] Checking Node.js environment..." "Cyan"

            if ($node) {
                $nodeVer = node --version
                $npmVer = npm --version
                Write-Color "  [+] Node.js $nodeVer detected" "Green"
                Write-Color "  [+] npm $npmVer detected" "Green"
            } else {
                Write-Color "  [i] Node.js not found" "Yellow"
            }

            if ($nvm) {
                $nvmList = nvm list 2>$null
                Write-Color "  [+] nvm-windows detected" "Green"
                Write-Color "  [+] Installed versions:" "Gray"
                $nvmList | ForEach-Object { Write-Host "      $_" }
            } else {
                Write-Color "  [i] nvm-windows not found" "Yellow"
            }

            if (-not $node -and -not $nvm) {
                Write-Color "  [?] Choose installation method:" "Cyan"
                Write-Color "      [1] nvm-windows (recommended - manage multiple versions)" "Gray"
                Write-Color "      [2] Node.js via winget (latest LTS)" "Gray"
                $method = Read-Host "  [?] Select (1 or 2)"

                if ($method -eq '1') {
                    Write-Color "  [*] Installing nvm-windows..." "Cyan"
                    winget install CoreyButler.NVMforWindows --accept-source-agreements --accept-package-agreements
                    Write-Color "  [+] nvm installed. Restart terminal, then run: nvm install lts" "Green"
                } elseif ($method -eq '2') {
                    Write-Color "  [*] Installing Node.js LTS via winget..." "Cyan"
                    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
                    Write-Color "  [+] Node.js LTS installed. Restart terminal." "Green"
                }
            } elseif (-not $node -and $nvm) {
                Write-Color "  [*] Installing latest LTS via nvm..." "Cyan"
                nvm install lts
                nvm use lts
                Write-Color "  [+] Node.js LTS installed via nvm" "Green"
            }

            $globalPackages = npm list -g --depth=0 2>$null
            Write-Color "  [+] Global npm packages:" "Gray"
            $globalPackages | Select-String -Pattern "^[^`"]" | ForEach-Object {
                Write-Host "      $_".Trim()
            }
        } catch {
            Write-Color "  [!] Node.js setup failed: $_" "Red"
        }
        Pause
    }
}
