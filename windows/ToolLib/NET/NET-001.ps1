Register-Tool @{
    ID          = 'NET-001'
    Name        = 'Quick Network Diagnostic'
    Category    = 'NET'
    Description = 'Ping key hosts, check DNS resolution, show network interfaces'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only network check — pings external hosts.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── NETWORK DIAGNOSTIC ───" "Cyan"
        Write-Color "  Interfaces:" "White"
        Get-NetAdapter | Where-Object Status -eq Up | Format-Table Name, InterfaceDescription, LinkSpeed, MacAddress -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
        Write-Color "  IP Configuration:" "White"
        Get-NetIPAddress -AddressFamily IPv4 | Format-Table InterfaceAlias, IPAddress, PrefixLength, DefaultGateway -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
        Write-Color "  DNS Servers:" "White"
        Get-DnsClientServerAddress -AddressFamily IPv4 | Format-Table InterfaceAlias, ServerAddresses -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
        Write-Color "  Connectivity:" "White"
        try {
            $ping = Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet
            Write-Color "    Google DNS: $($ping ? 'OK' : 'FAIL')" ($ping ? "Green" : "Red")
        } catch { Write-Color "    Google DNS: FAIL" "Red" }
        try {
            $ping = Test-Connection -ComputerName 1.1.1.1 -Count 2 -Quiet
            Write-Color "    Cloudflare DNS: $($ping ? 'OK' : 'FAIL')" ($ping ? "Green" : "Red")
        } catch { Write-Color "    Cloudflare DNS: FAIL" "Red" }
        Write-Color "  [+] Quick diagnostic complete." "Green"
        Pause
    }
}
