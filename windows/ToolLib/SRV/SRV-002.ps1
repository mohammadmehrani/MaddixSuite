Register-Tool @{
    ID          = 'SRV-002'
    Name        = 'IIS Setup'
    Category    = 'SRV'
    Description = 'Install IIS web server with management tools'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Install IIS web server with management tools?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking IIS status..." "Cyan"
            $iis = Get-WindowsFeature -Name Web-Server -ErrorAction SilentlyContinue

            if (-not $iis) {
                Write-Color "  [!] Unable to check IIS feature" "Yellow"
                $iisCheck = Get-Service W3SVC -ErrorAction SilentlyContinue
                if ($iisCheck) {
                    Write-Color "  [+] IIS is already installed (W3SVC running)" "Green"
                    $iis = @{Installed = $true}
                }
            }

            if ($iis -and $iis.Installed) {
                Write-Color "  [+] IIS is already installed" "Green"
            } else {
                Write-Color "  [i] IIS is not installed" "Yellow"
                $choice = Read-Host "  [?] Install IIS with management tools? (y/N)"
                if ($choice -eq 'y') {
                    Write-Color "  [*] Installing IIS and management tools..." "Cyan"
                    Install-WindowsFeature -Name Web-Server, Web-Mgmt-Console, Web-Mgmt-Service,
                        Web-WebSockets, Web-Asp-Net45, Web-Stat-Compression, Web-Dyn-Compression,
                        Web-Basic-Auth, Web-Windows-Auth, Web-Net-Ext45 -IncludeManagementTools
                    Write-Color "  [+] IIS installed successfully" "Green"
                }
            }

            if ((Get-Service W3SVC -ErrorAction SilentlyContinue) -or ($iis -and $iis.Installed)) {
                $sites = Get-IISSite -ErrorAction SilentlyContinue
                if ($sites) {
                    Write-Color "  [+] IIS Sites:" "Cyan"
                    $sites | Select-Object Name, State, @{N='Bindings';E={$_.Bindings.Collection.Protocol -join ', '}} |
                        Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
                }

                $appPools = Get-IISAppPool -ErrorAction SilentlyContinue
                if ($appPools) {
                    $poolCount = ($appPools | Measure-Object).Count
                    $runningCount = ($appPools | Where-Object { $_.State -eq 'Started' } | Measure-Object).Count
                    Write-Color "  [+] App Pools: $poolCount ($runningCount running)" "Gray"
                }

                $defaultPath = "C:\inetpub\wwwroot"
                if (Test-Path $defaultPath) {
                    Write-Color "  [+] Default web root: $defaultPath" "Gray"
                }
            }
        } catch {
            Write-Color "  [!] IIS setup failed: $_" "Red"
        }
        Pause
    }
}
