Register-Tool @{
    ID          = 'SRV-003'
    Name        = 'Windows Features Manager'
    Category    = 'SRV'
    Description = 'List/install server features'
    DangerLevel = 'Safe'
    ConfirmMessage = 'List available Windows Server features?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Reading Windows Server features..." "Cyan"
            $features = Get-WindowsFeature -ErrorAction SilentlyContinue

            if (-not $features) {
                Write-Color "  [!] Not a Windows Server OS or RSAT not available" "Yellow"
                Write-Color "  [i] Trying Windows Optional Features instead..." "Cyan"
                $optFeatures = Get-WindowsOptionalFeature -Online -ErrorAction SilentlyContinue
                if ($optFeatures) {
                    Write-Color "  [+] Optional Features ($($optFeatures.Count)):" "Cyan"
                    $optFeatures | Where-Object { $_.State -eq 'Enabled' } |
                        Select-Object FeatureName, State | Format-Table -AutoSize |
                        Out-String | ForEach-Object { Write-Host $_ }
                }
                Pause
                return
            }

            $installed = $features | Where-Object { $_.Installed }
            $available = $features | Where-Object { -not $_.Installed }

            Write-Color "  [+] Installed features: $($installed.Count)" "Green"
            Write-Color "  [+] Available features: $($available.Count)" "Cyan"

            Write-Color "  [*] Installed features summary:" "Cyan"
            $installed | Group-Object -Property Category | Sort-Object Name |
                ForEach-Object {
                    Write-Color "      [$($_.Name)] $($_.Count) features" "Gray"
                }

            $featureRequest = Read-Host "  [?] Search for a feature to install (or Enter to skip)"
            if ($featureRequest) {
                $matches = $available | Where-Object { $_.Name -like "*$featureRequest*" -or $_.DisplayName -like "*$featureRequest*" }
                if ($matches) {
                    Write-Color "  [+] Matching features:" "Cyan"
                    $matches | Select-Object Name, DisplayName, Category |
                        Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ }

                    $installFeature = Read-Host "  [?] Enter feature Name to install (or Enter to skip)"
                    if ($installFeature) {
                        $confirm = Read-Host "  [?] Install '$installFeature'? (y/N)"
                        if ($confirm -eq 'y') {
                            Install-WindowsFeature -Name $installFeature -IncludeManagementTools
                            Write-Color "  [+] Feature install initiated" "Green"
                        }
                    }
                } else {
                    Write-Color "  [i] No matching features found" "Yellow"
                }
            }
        } catch {
            Write-Color "  [!] Feature manager failed: $_" "Red"
        }
        Pause
    }
}
