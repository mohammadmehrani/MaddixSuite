Register-Tool @{
    ID          = 'AD-025'
    Name        = 'DNS Manager'
    Category    = 'AD'
    Description = 'Install DNS, show zones, forwarders, configure'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Check/install DNS Server role and show zones?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking DNS Server status..." "Cyan"
            $dns = Get-WindowsFeature -Name DNS -ErrorAction SilentlyContinue

            if (-not $dns -or -not $dns.Installed) {
                Write-Color "  [i] DNS Server is not installed" "Yellow"
                $choice = Read-Host "  [?] Install DNS Server? (y/N)"
                if ($choice -eq 'y') {
                    Write-Color "  [*] Installing DNS Server..." "Cyan"
                    Install-WindowsFeature -Name DNS -IncludeManagementTools
                    Write-Color "  [+] DNS Server installed" "Green"
                }
            } else {
                Write-Color "  [+] DNS Server is installed" "Green"
            }

            $zones = Get-DnsServerZone -ErrorAction SilentlyContinue
            if ($zones) {
                Write-Color "  [+] DNS Zones:" "Cyan"
                $zones | Format-Table ZoneName, ZoneType, IsAutoCreated -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
            }

            $fwd = Get-DnsServerForwarder -ErrorAction SilentlyContinue
            if ($fwd -and $fwd.IPAddress) {
                Write-Color "  [+] Forwarders: $($fwd.IPAddress -join ', ')" "Gray"
            } else {
                Write-Color "  [i] No forwarders configured" "Gray"
            }

            Write-Color "  [i] Manage DNS: dnsmgmt.msc" "Gray"
        } catch {
            Write-Color "  [!] DNS check failed: $_" "Red"
        }
        Pause
    }
}
