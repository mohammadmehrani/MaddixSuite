Register-Tool @{
    ID          = 'NET-025'
    Name        = 'ARP Table Viewer'
    Category    = 'NET'
    Description = 'View and clear the ARP cache table'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only (or clear with confirmation). Shows or clears ARP cache.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── ARP TABLE VIEWER ───" "Cyan"
        Write-Color "  1. Show full ARP table" "White"
        Write-Color "  2. Show ARP entries by interface" "White"
        Write-Color "  3. Search ARP table" "White"
        Write-Color "  4. Show ARP statistics" "White"
        Write-Color "  5. Clear ARP cache" "White"
        Write-Color "  6. Export ARP table to file" "White"
        Write-Color "  0. Back" "Red"
        $c = Read-Host "`n  Select option"
        switch ($c) {
            "1" {
                try {
                    $arp = arp -a
                    Write-Color "$arp" "Gray"
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "2" {
                try {
                    $adapters = Get-NetAdapter -Physical | Where-Object Status -eq Up
                    $i = 1
                    $aList = @()
                    foreach ($a in $adapters) {
                        $ip = (Get-NetIPAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
                        Write-Color "  $i. $($a.Name) - $ip" "White"
                        $aList += $a
                        $i++
                    }
                    $sel = Read-Host "`n  Select interface (number)"
                    $target = $aList[[int]$sel - 1]
                    $ip = (Get-NetIPAddress -InterfaceIndex $target.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
                    if ($ip) {
                        $subnet = $ip -replace '\d+$', '0'
                        $arp = arp -a -N $ip
                        Write-Color "  ARP entries for $($target.Name) ($ip):" "Cyan"
                        Write-Color "$arp" "Gray"
                    } else { Write-Color "  No IPv4 address assigned." "Yellow" }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "3" {
                $search = Read-Host "  Search term (IP or MAC)"
                try {
                    $arp = arp -a | Select-String $search
                    if ($arp) {
                        Write-Color "  Matching entries:" "Green"
                        Write-Color "$($arp -join "`n")" "Gray"
                    } else { Write-Color "  No matches for '$search'" "Yellow" }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "4" {
                try {
                    $arpOutput = arp -a
                    $lines = $arpOutput -split "`r`n" | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+' }
                    $total = $lines.Count
                    $uniqueIps = $lines | ForEach-Object { $_ -split '\s+' | Select-Object -First 1 } | Sort-Object -Unique
                    $types = $lines | ForEach-Object { if ($_ -match 'dynamic') { 'dynamic' } elseif ($_ -match 'static') { 'static' } else { 'unknown' } }
                    $dynamic = ($types | Where-Object { $_ -eq 'dynamic' }).Count
                    $static = ($types | Where-Object { $_ -eq 'static' }).Count
                    $interfaces = ($arpOutput | Select-String -Pattern 'Interface:' | Measure-Object).Count
                    Write-Color "  ┌──────────────────────────────────────┐" "Cyan"
                    Write-Color "  │          ARP TABLE STATISTICS        │" "Cyan"
                    Write-Color "  ├──────────────────────────────────────┤" "Cyan"
                    Write-Color "  │ Total Entries:     $total".PadRight(39) + "│" "White"
                    Write-Color "  │ Dynamic Entries:   $dynamic".PadRight(39) + "│" "Green"
                    Write-Color "  │ Static Entries:    $static".PadRight(39) + "│" "Yellow"
                    Write-Color "  │ Interfaces:        $interfaces".PadRight(39) + "│" "Gray"
                    Write-Color "  │ Unique IPs:        $($uniqueIps.Count)".PadRight(39) + "│" "White"
                    Write-Color "  └──────────────────────────────────────┘" "Cyan"
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "5" {
                $confirm = Read-Host "  Clear entire ARP cache? (y/N)"
                if ($confirm -eq "y") {
                    try {
                        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                        if (-not $isAdmin) {
                            Write-Color "  [!] Administrator privileges required." "Red"
                        } else {
                            netsh interface ip delete arpcache
                            Write-Color "  [+] ARP cache cleared" "Green"
                        }
                    } catch { Write-Color "  [!] Failed to clear ARP: $_" "Red" }
                } else { Write-Color "  Cancelled." "Yellow" }
            }
            "6" {
                try {
                    $arp = arp -a
                    $file = "$env:USERPROFILE\Desktop\MaddixSuite\ARP_Table_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                    $exportDir = Split-Path $file -Parent
                    if (-not (Test-Path $exportDir)) { New-Item -ItemType Directory -Path $exportDir -Force | Out-Null }
                    $arp | Out-File -FilePath $file -Encoding utf8
                    Write-Color "  [+] Exported to $file" "Green"
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
        }
        Pause
    }
}
