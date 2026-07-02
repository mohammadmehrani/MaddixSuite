Register-Tool @{
    ID          = 'SRV-007'
    Name        = 'Remote Desktop Config'
    Category    = 'SRV'
    Description = 'Enable/configure RDP, firewall rules'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Configure Remote Desktop settings?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking Remote Desktop status..." "Cyan"

            $rdpReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
                -Name "fDenyTSConnections" -ErrorAction SilentlyContinue

            if ($rdpReg) {
                $rdpEnabled = $rdpReg.fDenyTSConnections -eq 0
                if ($rdpEnabled) {
                    Write-Color "  [+] Remote Desktop is enabled" "Green"
                } else {
                    Write-Color "  [i] Remote Desktop is disabled" "Yellow"
                }
            } else {
                Write-Color "  [i] Remote Desktop registry key not found" "Yellow"
            }

            $rdpService = Get-Service -Name TermService -ErrorAction SilentlyContinue
            if ($rdpService) {
                Write-Color "  [+] Terminal Services: $($rdpService.Status) (Startup: $($rdpService.StartType))" "Gray"
            }

            $rdpPort = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
                -Name "PortNumber" -ErrorAction SilentlyContinue).PortNumber
            if ($rdpPort) {
                Write-Color "  [+] RDP Port: $rdpPort" "Gray"
            }

            $firewallRule = Get-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
            if ($firewallRule) {
                $rdpFwEnabled = ($firewallRule | Where-Object { $_.Enabled -eq 'True' } | Measure-Object).Count
                Write-Color "  [+] Firewall rules for Remote Desktop: $rdpFwEnabled enabled" "Gray"
            } else {
                Write-Color "  [i] No Remote Desktop firewall rules found" "Yellow"
            }

            $sessions = quser 2>$null
            if ($sessions) {
                Write-Color "  [+] Active RDP sessions:" "Cyan"
                $sessions | ForEach-Object { Write-Host "      $_" }
            } else {
                Write-Color "  [i] No active RDP sessions" "Gray"
            }

            $choice = Read-Host "  [?] Enable Remote Desktop? (y/N)"
            if ($choice -eq 'y') {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
                    -Name "fDenyTSConnections" -Value 0
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
                    -Name "fAllowToGetHelp" -Value 1
                Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
                Set-Service -Name TermService -StartupType Automatic
                Start-Service -Name TermService -ErrorAction SilentlyContinue
                Write-Color "  [+] Remote Desktop enabled" "Green"
            }

            $choice2 = Read-Host "  [?] Change RDP port? (default 3389) (y/N)"
            if ($choice2 -eq 'y') {
                $newPort = Read-Host "  [?] Enter new port number"
                if ($newPort -match '^\d+$' -and [int]$newPort -gt 1024 -and [int]$newPort -le 65535) {
                    $port = [int]$newPort
                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
                        -Name "PortNumber" -Value $port

                    New-NetFirewallRule -DisplayName "RDP Custom Port $port" `
                        -Direction Inbound -Protocol TCP -LocalPort $port -Action Allow | Out-Null

                    Write-Color "  [+] RDP port changed to $port (firewall rule added)" "Green"
                    Write-Color "  [i] Restart the service or server for changes to take effect" "Yellow"
                } else {
                    Write-Color "  [!] Invalid port number (use 1025-65535)" "Red"
                }
            }

            $choice3 = Read-Host "  [?] Show RDP security configuration? (y/N)"
            if ($choice3 -eq 'y') {
                Write-Color "  [+] RDP Security Settings:" "Cyan"
                $nla = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
                    -Name "UserAuthentication" -ErrorAction SilentlyContinue
                Write-Color "      NLA Required: $(if ($nla.UserAuthentication -eq 1) { 'Yes' } else { 'No' })" "Gray"

                $ssl = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
                    -Name "SSLCertificateSHA1Hash" -ErrorAction SilentlyContinue
                Write-Color "      SSL Certificate: $(if ($ssl) { $ssl.SSLCertificateSHA1Hash } else { 'Default (self-signed)' })" "Gray"
            }
        } catch {
            Write-Color "  [!] RDP config failed: $_" "Red"
        }
        Pause
    }
}
