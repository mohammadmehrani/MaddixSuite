Register-Tool @{
    ID          = 'SRV-001'
    Name        = 'Hyper-V Manager'
    Category    = 'SRV'
    Description = 'Check/install Hyper-V role, list VMs'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Check/install Hyper-V role and list VMs?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking Hyper-V status..." "Cyan"
            $hyperv = Get-WindowsFeature -Name Hyper-V -ErrorAction SilentlyContinue

            if (-not $hyperv) {
                Write-Color "  [!] Unable to check Hyper-V feature (non-Server OS?)" "Yellow"
                $hyperv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -ErrorAction SilentlyContinue
            }

            if ($hyperv -and $hyperv.Installed) {
                Write-Color "  [+] Hyper-V is installed" "Green"
            } else {
                Write-Color "  [i] Hyper-V is not installed" "Yellow"
                $choice = Read-Host "  [?] Install Hyper-V? (y/N)"
                if ($choice -eq 'y') {
                    Write-Color "  [*] Installing Hyper-V role..." "Cyan"
                    if ($hyperv -is [System.Management.Automation.PSObject] -and $hyperv.PSObject.TypeNames -match "Feature") {
                        Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
                    } else {
                        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
                    }
                    Write-Color "  [+] Hyper-V installed. Restart may be required." "Green"
                }
            }

            $vmModule = Get-Module -ListAvailable Hyper-V -ErrorAction SilentlyContinue
            if ($vmModule) {
                $vms = Get-VM -ErrorAction SilentlyContinue
                if ($vms) {
                    Write-Color "  [+] Virtual Machines ($($vms.Count)):" "Cyan"
                    $vms | Select-Object Name, State, @{N='RAM(MB)';E={[math]::Round($_.MemoryStartup/1MB)}}, ProcessorCount, Status |
                        Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
                } else {
                    Write-Color "  [i] No VMs configured" "Gray"
                }

                $switches = Get-VMSwitch -ErrorAction SilentlyContinue
                if ($switches) {
                    Write-Color "  [+] Virtual Switches:" "Cyan"
                    $switches | Select-Object Name, SwitchType | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
                }
            } else {
                Write-Color "  [i] Hyper-V management tools not available" "Yellow"
            }
        } catch {
            Write-Color "  [!] Hyper-V check failed: $_" "Red"
        }
        Pause
    }
}
