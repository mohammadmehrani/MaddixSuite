Register-Tool @{
    ID          = 'AD-026'
    Name        = 'DHCP Manager'
    Category    = 'AD'
    Description = 'Install DHCP Server role and configure scopes'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Check/install DHCP Server role?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking DHCP Server status..." "Cyan"
            $dhcp = Get-WindowsFeature -Name DHCP -ErrorAction SilentlyContinue

            if (-not $dhcp -or -not $dhcp.Installed) {
                Write-Color "  [i] DHCP Server is not installed" "Yellow"
                $choice = Read-Host "  [?] Install DHCP Server? (y/N)"
                if ($choice -eq 'y') {
                    Write-Color "  [*] Installing DHCP Server..." "Cyan"
                    Install-WindowsFeature -Name DHCP -IncludeManagementTools
                    Write-Color "  [+] DHCP Server installed" "Green"
                    Write-Color "  [i] Run post-install: Add-DhcpServerSecurityGroup" "Gray"
                }
            } else {
                Write-Color "  [+] DHCP Server is installed" "Green"
                $scopeChoice = Read-Host "  [?] Configure a new DHCP scope? (y/N)"
                if ($scopeChoice -eq 'y') {
                    $scopeName = Read-Host "  Scope name"
                    $startIp = Read-Host "  Start IP range"
                    $endIp = Read-Host "  End IP range"
                    $subnetMask = Read-Host "  Subnet mask (e.g., 255.255.255.0)"
                    $defaultGateway = Read-Host "  Default gateway"
                    if ($scopeName -and $startIp -and $endIp -and $subnetMask) {
                        Add-DhcpServerv4Scope -Name $scopeName -StartRange $startIp -EndRange $endIp -SubnetMask $subnetMask
                        if ($defaultGateway) {
                            Set-DhcpServerv4OptionValue -OptionId 3 -Value $defaultGateway
                        }
                        Write-Color "  [+] Scope '$scopeName' created" "Green"
                    }
                }
            }

            $scopes = Get-DhcpServerv4Scope -ErrorAction SilentlyContinue
            if ($scopes) {
                Write-Color "  [+] DHCP Scopes:" "Cyan"
                $scopes | Format-Table ScopeId, Name, SubnetMask, State, StartRange, EndRange -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
            }

            Write-Color "  [i] Manage DHCP: dhcpmgmt.msc" "Gray"
        } catch {
            Write-Color "  [!] DHCP check failed: $_" "Red"
        }
        Pause
    }
}
