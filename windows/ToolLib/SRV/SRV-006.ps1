Register-Tool @{
    ID          = 'SRV-006'
    Name        = 'WSUS Config'
    Category    = 'SRV'
    Description = 'Check/configure WSUS for Windows updates'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Check/configure WSUS update settings?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking WSUS / Windows Update configuration..." "Cyan"

            $wuKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
            $useWUServer = $false
            $wsusServer = $null

            if (Test-Path $wuKey) {
                $wsusServer = Get-ItemProperty -Path $wuKey -Name "WUServer" -ErrorAction SilentlyContinue
                $useWSUS = Get-ItemProperty -Path "$wuKey\AU" -Name "UseWUServer" -ErrorAction SilentlyContinue
                $useWUServer = $useWSUS.UseWUServer -eq 1

                if ($wsusServer) {
                    Write-Color "  [+] WSUS configured: $($wsusServer.WUServer)" "Green"
                } else {
                    Write-Color "  [i] Windows Update policy exists but no WSUS server set" "Yellow"
                }
            } else {
                Write-Color "  [i] No WSUS policy configured (using Windows Update directly)" "Yellow"
            }

            $updateService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
            if ($updateService) {
                Write-Color "  [+] Windows Update service: $($updateService.Status)" "Gray"
            }

            Write-Color "  [*] Checking AU settings..." "Cyan"
            $auKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            if (Test-Path $auKey) {
                $auOptions = Get-ItemProperty -Path $auKey -ErrorAction SilentlyContinue
                Write-Color "  [+] AU policy exists" "Gray"

                $optionMap = @{
                    2 = "Notify before download"
                    3 = "Auto download and notify"
                    4 = "Auto download and schedule install"
                    5 = "Allow local admin to choose"
                }
                $opt = $auOptions.AUOptions
                $optDesc = if ($optionMap.ContainsKey($opt)) { $optionMap[$opt] } else { "Unknown ($opt)" }
                Write-Color "      AU Option: $optDesc" "Gray"
            } else {
                Write-Color "  [i] No AU policy configured" "Yellow"
            }

            $choice = Read-Host "  [?] Configure WSUS server? (y/N)"
            if ($choice -eq 'y') {
                $wsusUrl = Read-Host "  [?] WSUS server URL (e.g. http://wsus01:8530)"
                if ($wsusUrl) {
                    $targetGroup = Read-Host "  [?] Target group name (optional)"
                    if (-not $targetGroup) { $targetGroup = "Unsigned" }

                    if (-not (Test-Path $wuKey)) {
                        New-Item -Path $wuKey -Force | Out-Null
                    }
                    if (-not (Test-Path "$wuKey\AU")) {
                        New-Item -Path "$wuKey\AU" -Force | Out-Null
                    }

                    Set-ItemProperty -Path $wuKey -Name "WUServer" -Value $wsusUrl -Type String
                    Set-ItemProperty -Path $wuKey -Name "WUStatusServer" -Value $wsusUrl -Type String
                    Set-ItemProperty -Path "$wuKey\AU" -Name "UseWUServer" -Value 1 -Type DWord
                    Set-ItemProperty -Path "$wuKey\AU" -Name "AUOptions" -Value 4 -Type DWord
                    Set-ItemProperty -Path "$wuKey\AU" -Name "TargetGroupEnabled" -Value 1 -Type DWord
                    Set-ItemProperty -Path "$wuKey\AU" -Name "TargetGroup" -Value $targetGroup -Type String

                    Write-Color "  [+] WSUS configured: $wsusUrl (Group: $targetGroup)" "Green"

                    Write-Color "  [*] Restarting Windows Update service..." "Cyan"
                    Restart-Service -Name wuauserv -Force
                    Write-Color "  [+] Service restarted" "Green"

                    Write-Color "  [*] Forcing detection..." "Cyan"
                    wuauclt /detectnow 2>$null
                    Write-Color "  [+] Detection initiated" "Green"
                }
            }

            $choice2 = Read-Host "  [?] Reset to use Microsoft Update directly? (y/N)"
            if ($choice2 -eq 'y') {
                if (Test-Path $wuKey) {
                    Remove-Item -Path $wuKey -Recurse -Force -ErrorAction SilentlyContinue
                }
                Restart-Service -Name wuauserv -Force
                Write-Color "  [+] Reset to direct Windows Update" "Green"
            }
        } catch {
            Write-Color "  [!] WSUS config failed: $_" "Red"
        }
        Pause
    }
}
