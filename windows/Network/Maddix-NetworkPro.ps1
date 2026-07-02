# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
<#
.SYNOPSIS
    Maddix-NetworkPro - Advanced Windows Network Toolkit
.DESCRIPTION
    Comprehensive network utility by Mohammad Mehrani (Maddix) featuring:
    Network diagnostics, WiFi management, DNS changer, speed test simulation,
    bandwidth monitor, connection analyzer, and network repair tools.
.NOTES
    Version: 1.0
    Author: Mohammad Mehrani (Maddix)
    Part of MaddixSuite: https://github.com/mohammadmehrani/MaddixSuite
    One-liner: irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Network/Maddix-NetworkPro.ps1 | iex
#>

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: Administrator privileges required." -ForegroundColor Red
    Pause; Exit
}

function Show-Banner {
    Clear-Host
    Write-Host "████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host "  ███╗   ███╗ █████╗ ██████╗ ██████╗ ██╗██╗  ██╗" -ForegroundColor Cyan
    Write-Host "  ████╗ ████║██╔══██╗██╔══██╗██╔══██╗██║╚██╗██╔╝" -ForegroundColor Cyan
    Write-Host "  ██╔████╔██║███████║██║  ██║██║  ██║██║ ╚███╔╝ " -ForegroundColor Cyan
    Write-Host "  ██║╚██╔╝██║██╔══██║██║  ██║██║  ██║██║ ██╔██╗ " -ForegroundColor Cyan
    Write-Host "  ██║ ╚═╝ ██║██║  ██║██████╔╝██████╔╝██║██╔╝ ██╗" -ForegroundColor Cyan
    Write-Host "  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═╝" -ForegroundColor Cyan
    Write-Host "████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host "  Maddix-NetworkPro v1.0 · Network Diagnostics & Tools" -ForegroundColor Cyan
    Write-Host "  Created by Mohammad Mehrani (Maddix)" -ForegroundColor Cyan
    Write-Host "████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host ""
}

function Diagnostic-Quick {
    Write-Host "`n=== QUICK NETWORK DIAGNOSTIC ===" -ForegroundColor Cyan
    $targets = @("8.8.8.8", "1.1.1.1", "google.com", "github.com", "cloudflare.com")
    
    Write-Host "Ping Test:" -ForegroundColor Yellow
    foreach ($t in $targets) {
        $ping = Test-Connection -ComputerName $t -Count 1 -Quiet -ErrorAction SilentlyContinue
        $icon = if ($ping) { "✓" } else { "✗" }
        $color = if ($ping) { "Green" } else { "Red" }
        $ms = if ($ping) { ((Test-Connection $t -Count 1 -ErrorAction SilentlyContinue).ResponseTime) } else { 0 }
        Write-Host "  $icon $t`t$ms ms" -ForegroundColor $color
    }
    
    Write-Host "`nDNS Resolution:" -ForegroundColor Yellow
    $dnsServers = @("8.8.8.8", "1.1.1.1", "208.67.222.222")
    foreach ($d in $dnsServers) {
        $test = Resolve-DnsName -Name "google.com" -Server $d -QuickTimeout -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($test) { Write-Host "  ✓ DNS $d responds" -ForegroundColor Green }
        else { Write-Host "  ✗ DNS $d timeout" -ForegroundColor Red }
    }
    
    Write-Host "`nConnection Info:" -ForegroundColor Yellow
    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" }
    foreach ($a in $adapters) {
        $ip = Get-NetIPAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        $gw = Get-NetRoute -InterfaceIndex $a.ifIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
        Write-Host "  $($a.Name): IP=$($ip.IPAddress) GW=$($gw.NextHop)" -ForegroundColor Gray
    }
    
    Write-Host "`nInternet Speed (rough estimate via ping latency):" -ForegroundColor Yellow
    $avg = 0; $count = 0
    foreach ($t in $targets) {
        $r = Test-Connection $t -Count 1 -ErrorAction SilentlyContinue
        if ($r) { $avg += $r.ResponseTime; $count++ }
    }
    if ($count -gt 0) {
        $ms = [math]::Round($avg/$count, 1)
        Write-Host "  Average latency: $ms ms" -ForegroundColor $(if ($ms -lt 50) { "Green" } elseif ($ms -lt 100) { "Yellow" } else { "Red" })
    }
    
    $result = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Quick Diag" | Out-File "$env:USERPROFILE\Desktop\MaddixSuite\Network\quickdiag.log" -Append
    Pause
}

function Diagnostic-Advanced {
    Write-Host "`n=== ADVANCED NETWORK ANALYSIS ===" -ForegroundColor Cyan
    
    Write-Host "Traceroute to 8.8.8.8:" -ForegroundColor Yellow
    tracert -h 20 8.8.8.8
    Write-Host ""
    
    Write-Host "PathPing (latency + packet loss):" -ForegroundColor Yellow
    pathping -n -q 5 -h 10 8.8.8.8
    Write-Host ""
    
    Write-Host "TCP Connections (active):" -ForegroundColor Yellow
    $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue | Where-Object { $_.State -eq "Established" } | Group-Object -Property RemoteAddress | Sort-Object Count -Descending | Select-Object -First 15
    if ($connections) {
        $connections | Format-Table Name, Count -AutoSize
    }
    
    Write-Host "Bandwidth usage per adapter (last 1 sec):" -ForegroundColor Yellow
    try {
        $counters = Get-Counter "\Network Interface(*)\Bytes Total/sec" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty CounterSamples
        if ($counters) {
            $counters | Where-Object { $_.Path -notmatch "_Total" } | ForEach-Object {
                $mbps = [math]::Round($_.CookedValue * 8 / 1MB, 2)
                Write-Host "  $($_.InstanceName): $mbps Mbps" -ForegroundColor Gray
            }
        }
    } catch {}
    
    Pause
}

function WiFi-Manager {
    Write-Host "`n=== WiFi MANAGER ===" -ForegroundColor Cyan
    
    Write-Host "Available Networks:" -ForegroundColor Yellow
    try {
        $netsh = netsh wlan show networks mode=bssid
        Write-Host $netsh
    } catch {}
    
    Write-Host "`nSaved Profiles:" -ForegroundColor Yellow
    $profiles = netsh wlan show profiles | Select-String -Pattern "All User Profile" | ForEach-Object { $_ -replace '.*:\s+', '' }
    if ($profiles) {
        $profiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    }
    
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  1. Show current connection details"
    Write-Host "  2. Export all WiFi profiles (with passwords)"
    Write-Host "  3. Forget a WiFi network"
    Write-Host "  4. Generate WiFi QR code command"
    $wc = Read-Host "Select (1-4)"
    
    switch ($wc) {
        "1" { netsh wlan show interfaces }
        "2" {
            $wifiDir = "$env:USERPROFILE\Desktop\MaddixSuite\Network\WiFi_Export"
            New-Item -ItemType Directory -Path $wifiDir -Force | Out-Null
            $profiles | ForEach-Object {
                netsh wlan export profile name="$_" folder="$wifiDir" key=clear
            }
            Write-Host "Profiles exported to $wifiDir" -ForegroundColor Green
        }
        "3" {
            $name = Read-Host "Enter WiFi name to forget"
            netsh wlan delete profile name="$name"
            Write-Host "Profile '$name' deleted." -ForegroundColor Green
        }
        "4" {
            $name = Read-Host "Enter WiFi name"
            $pass = Read-Host "Enter WiFi password"
            Write-Host "`nUse this URL to generate QR (replace SSID/PASS):" -ForegroundColor Yellow
            Write-Host "https://qifi.org/?ssid=$name&key=$pass&type=WPA" -ForegroundColor Cyan
        }
    }
    Pause
}

function DNS-Manager {
    Write-Host "`n=== DNS MANAGER ===" -ForegroundColor Cyan
    
    Write-Host "Current DNS Configuration:" -ForegroundColor Yellow
    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -eq "802.3" -or $_.MediaType -eq "Native 802.11" }
    foreach ($a in $adapters) {
        $dns = Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        Write-Host "  $($a.Name): $($dns.ServerAddresses)" -ForegroundColor Gray
    }
    
    Write-Host "`nDNS Profiles:" -ForegroundColor Yellow
    Write-Host "  1. Google DNS (8.8.8.8 / 8.8.4.4)"
    Write-Host "  2. Cloudflare (1.1.1.1 / 1.0.0.1)"
    Write-Host "  3. OpenDNS (208.67.222.222 / 208.67.220.220)"
    Write-Host "  4. Quad9 (9.9.9.9 / 149.112.112.112)"
    Write-Host "  5. Custom"
    Write-Host "  6. Reset to DHCP (automatic)"
    $dc = Read-Host "Select DNS profile"
    
    $dns1 = ""; $dns2 = ""
    switch ($dc) {
        "1" { $dns1 = "8.8.8.8"; $dns2 = "8.8.4.4" }
        "2" { $dns1 = "1.1.1.1"; $dns2 = "1.0.0.1" }
        "3" { $dns1 = "208.67.222.222"; $dns2 = "208.67.220.220" }
        "4" { $dns1 = "9.9.9.9"; $dns2 = "149.112.112.112" }
        "5" { $dns1 = Read-Host "Primary DNS"; $dns2 = Read-Host "Secondary DNS" }
        "6" {
            $adapter = (Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1).Name
            if ($adapter) {
                Set-DnsClientServerAddress -InterfaceAlias $adapter -ResetServerAddresses
                Write-Host "DNS reset to DHCP." -ForegroundColor Green
            }
            Pause; return
        }
    }
    
    if ($dns1) {
        $adapter = (Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1).Name
        if ($adapter) {
            Set-DnsClientServerAddress -InterfaceAlias $adapter -ServerAddresses ($dns1, $dns2)
            Write-Host "DNS set to $dns1, $dns2 on $adapter" -ForegroundColor Green
            ipconfig /flushdns | Out-Null
            Write-Host "DNS cache flushed." -ForegroundColor Gray
        }
    }
    Pause
}

function Repair-Network {
    Write-Host "`n=== NETWORK REPAIR ===" -ForegroundColor Cyan
    Write-Host "This will reset the entire network stack. Continue?" -ForegroundColor Yellow
    $confirm = Read-Host "Type YES to confirm"
    if ($confirm -ne "YES") { return }
    
    Write-Host "[1/7] Releasing IP..." -ForegroundColor Yellow
    ipconfig /release 2>$null
    
    Write-Host "[2/7] Renewing IP..." -ForegroundColor Yellow
    ipconfig /renew 2>$null
    
    Write-Host "[3/7] Flushing DNS..." -ForegroundColor Yellow
    ipconfig /flushdns
    
    Write-Host "[4/7] Resetting Winsock..." -ForegroundColor Yellow
    netsh winsock reset
    
    Write-Host "[5/7] Resetting TCP/IP..." -ForegroundColor Yellow
    netsh int ip reset
    
    Write-Host "[6/7] Resetting Firewall..." -ForegroundColor Yellow
    netsh advfirewall reset
    
    Write-Host "[7/7] Registering DNS..." -ForegroundColor Yellow
    ipconfig /registerdns
    
    Write-Host "`nNetwork repair completed!" -ForegroundColor Green
    Write-Host "A system reboot is highly recommended." -ForegroundColor Red
    $reboot = Read-Host "Reboot now? (y/n)"
    if ($reboot -eq 'y') { Restart-Computer -Force }
    Pause
}

function Connection-Monitor {
    Write-Host "`n=== CONNECTION MONITOR ===" -ForegroundColor Cyan
    Write-Host "Monitoring network connections (press Q to stop)..." -ForegroundColor Yellow
    Write-Host ""
    
    $lastRefresh = Get-Date
    $interval = 2
    
    do {
        $now = Get-Date
        if (($now - $lastRefresh).TotalSeconds -ge $interval) {
            Clear-Host
            Write-Host "Maddix-NetworkPro - Connection Monitor (refreshing every ${interval}s)" -ForegroundColor Cyan
            Write-Host "Press Q to quit`n" -ForegroundColor Yellow
            
            $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue | Group-Object State
            Write-Host "TCP Connection States:" -ForegroundColor Yellow
            $connections | Sort-Object Count -Descending | ForEach-Object {
                $color = switch ($_.Name) {
                    "Established" { "Green" }
                    "TimeWait" { "Gray" }
                    "CloseWait" { "Red" }
                    "SynSent" { "Yellow" }
                    default { "White" }
                }
                Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor $color
            }
            
            Write-Host "`nTop Remote IPs by connection count:" -ForegroundColor Yellow
            Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Group-Object RemoteAddress | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
                Write-Host "  $($_.Name): $($_.Count) connections" -ForegroundColor Gray
            }
            
            Write-Host "`nInterface Statistics:" -ForegroundColor Yellow
            Get-NetAdapterStatistics -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "Loopback|Teredo|ISATAP" } | ForEach-Object {
                $rx = [math]::Round($_.ReceivedBytes / 1MB, 1)
                $tx = [math]::Round($_.SentBytes / 1MB, 1)
                Write-Host "  $($_.Name): RX=${rx}MB TX=${tx}MB" -ForegroundColor Gray
            }
            
            $lastRefresh = $now
        }
        
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.KeyChar -eq 'q' -or $key.KeyChar -eq 'Q') { break }
        }
        Start-Sleep -Milliseconds 200
    } while ($true)
}

function Speed-Test {
    Write-Host "`n=== SPEED TEST (Latency-based estimate) ===" -ForegroundColor Cyan
    Write-Host "Downloads multiple test files to estimate speed..." -ForegroundColor Yellow
    Write-Host ""
    
    $testFiles = @(
        @{Url="http://speedtest.tele2.net/1MB.zip"; Size=1},
        @{Url="http://speedtest.tele2.net/5MB.zip"; Size=5}
    )
    
    $totalSpeed = 0
    $measurements = 0
    
    foreach ($file in $testFiles) {
        Write-Host "Testing $($file.Size)MB file..." -ForegroundColor Gray
        try {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $wc = New-Object System.Net.WebClient
            $data = $wc.DownloadData($file.Url)
            $stopwatch.Stop()
            $speedMbps = [math]::Round(($data.Length * 8) / ($stopwatch.Elapsed.TotalSeconds * 1MB), 2)
            Write-Host "  Speed: ${speedMbps} Mbps" -ForegroundColor Green
            $totalSpeed += $speedMbps
            $measurements++
        } catch {
            Write-Host "  Failed: $_" -ForegroundColor Red
        }
    }
    
    if ($measurements -gt 0) {
        $avgSpeed = [math]::Round($totalSpeed / $measurements, 2)
        Write-Host "`nEstimated download speed: $avgSpeed Mbps" -ForegroundColor Cyan
        
        if ($avgSpeed -gt 50) { Write-Host "Rating: Excellent" -ForegroundColor Green }
        elseif ($avgSpeed -gt 20) { Write-Host "Rating: Good" -ForegroundColor Cyan }
        elseif ($avgSpeed -gt 10) { Write-Host "Rating: Fair" -ForegroundColor Yellow }
        else { Write-Host "Rating: Poor" -ForegroundColor Red }
    }
    Pause
}

function Show-Menu {
    Show-Banner
    Write-Host " ──── DIAGNOSTICS ────" -ForegroundColor Magenta
    Write-Host "   1.  Quick Network Check (Ping, DNS, Interfaces)"
    Write-Host "   2.  Advanced Analysis (Traceroute, PathPing, TCP)"
    Write-Host ""
    Write-Host " ──── WiFi & DNS ────" -ForegroundColor Magenta
    Write-Host "   3.  WiFi Manager (scan, export, forget)"
    Write-Host "   4.  DNS Changer (Google, Cloudflare, OpenDNS, Custom)"
    Write-Host ""
    Write-Host " ──── TOOLS ────" -ForegroundColor Magenta
    Write-Host "   5.  Network Repair (full stack reset)"
    Write-Host "   6.  Connection Monitor (real-time)"
    Write-Host "   7.  Speed Test (download estimate)"
    Write-Host ""
    Write-Host " ──── GENERAL ────" -ForegroundColor Magenta
    Write-Host "   0.  Exit"
    Write-Host ""
}

function Main {
    while ($true) {
        Show-Menu
        $c = Read-Host "Select option (0-7)"
        switch ($c) {
            "1" { Diagnostic-Quick }
            "2" { Diagnostic-Advanced }
            "3" { WiFi-Manager }
            "4" { DNS-Manager }
            "5" { Repair-Network }
            "6" { Connection-Monitor }
            "7" { Speed-Test }
            "0" { Write-Host "Goodbye!" -ForegroundColor Cyan; exit }
            default { Write-Host "Invalid." -ForegroundColor Red; Pause }
        }
    }
}

Main

