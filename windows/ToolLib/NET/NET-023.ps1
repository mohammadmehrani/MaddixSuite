Register-Tool @{
    ID          = 'NET-023'
    Name        = 'Network Route Manager'
    Category    = 'NET'
    Description = 'View, add, and remove IPv4/IPv6 network routes'
    DangerLevel = 'Caution'
    ConfirmMessage = 'Modifies the system routing table — add or remove routes.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── NETWORK ROUTE MANAGER ───" "Cyan"
        Write-Color "  1. Show routing table (IPv4)" "White"
        Write-Color "  2. Show routing table (IPv6)" "White"
        Write-Color "  3. Show route by interface" "White"
        Write-Color "  4. Add persistent route" "White"
        Write-Color "  5. Remove route" "White"
        Write-Color "  6. Show route diagnostics" "White"
        Write-Color "  0. Back" "Red"
        $c = Read-Host "`n  Select option"
        switch ($c) {
            "1" {
                try {
                    $routes = Get-NetRoute -AddressFamily IPv4 -ErrorAction Stop | Sort-Object DestinationPrefix
                    Write-Color "  IPv4 Routes ($($routes.Count)):" "Cyan"
                    $routes | Select-Object DestinationPrefix, NextHop, RouteMetric, InterfaceAlias | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "2" {
                try {
                    $routes = Get-NetRoute -AddressFamily IPv6 -ErrorAction Stop | Sort-Object DestinationPrefix
                    Write-Color "  IPv6 Routes ($($routes.Count)):" "Cyan"
                    $routes | Select-Object DestinationPrefix, NextHop, RouteMetric, InterfaceAlias | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "3" {
                try {
                    $adapters = Get-NetAdapter -Physical | Where-Object Status -eq Up
                    $i = 1
                    $aList = @()
                    foreach ($a in $adapters) {
                        Write-Color "  $i. $($a.Name)" "White"
                        $aList += $a
                        $i++
                    }
                    $sel = Read-Host "`n  Select adapter (number)"
                    $target = $aList[[int]$sel - 1]
                    $routes = Get-NetRoute -InterfaceIndex $target.ifIndex -AddressFamily IPv4 -ErrorAction Stop
                    Write-Color "  Routes for $($target.Name):" "Cyan"
                    $routes | Select-Object DestinationPrefix, NextHop, RouteMetric | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "4" {
                try {
                    $dest = Read-Host "  Destination (e.g. 10.0.0.0/24)"
                    $gateway = Read-Host "  Gateway (e.g. 192.168.1.1)"
                    $metric = Read-Host "  Metric [default: 256]"
                    if ([string]::IsNullOrWhiteSpace($metric)) { $metric = 256 }
                    $ifIndex = Read-Host "  Interface index (leave blank for auto)"
                    $params = @{
                        DestinationPrefix = $dest
                        NextHop = $gateway
                        RouteMetric = $metric
                        PolicyStore = "PersistentStore"
                    }
                    if ($ifIndex) { $params.InterfaceIndex = [int]$ifIndex }
                    New-NetRoute @params -ErrorAction Stop
                    Write-Color "  [+] Route added: $dest -> $gateway" "Green"
                    Write-Color "  Route is persistent (survives reboot)." "Yellow"
                } catch { Write-Color "  [!] Failed to add route: $_" "Red" }
            }
            "5" {
                try {
                    $routes = Get-NetRoute -AddressFamily IPv4 -ErrorAction Stop | Where-Object DestinationPrefix -ne '0.0.0.0/0'
                    $i = 1
                    $routeList = @()
                    foreach ($r in $routes) {
                        Write-Color "  $i. $($r.DestinationPrefix) via $($r.NextHop) [$($r.InterfaceAlias)]" "White"
                        $routeList += $r
                        $i++
                        if ($i -gt 50) { Write-Color "  ... (more than 50 routes)"; break }
                    }
                    $sel = Read-Host "`n  Select route to remove (number)"
                    $target = $routeList[[int]$sel - 1]
                    $confirm = Read-Host "  Remove $($target.DestinationPrefix) via $($target.NextHop)? (y/N)"
                    if ($confirm -eq "y") {
                        Remove-NetRoute -DestinationPrefix $target.DestinationPrefix -NextHop $target.NextHop -Confirm:$false -ErrorAction Stop
                        Write-Color "  [+] Route removed" "Green"
                    }
                } catch { Write-Color "  [!] Failed to remove route: $_" "Red" }
            }
            "6" {
                try {
                    Write-Color "  Route diagnostics:" "Cyan"
                    Write-Color "  Default gateway: $(Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Select-Object -First 1 | ForEach-Object { $_.NextHop })" "White"
                    $persistent = Get-NetRoute -PolicyStore PersistentStore -ErrorAction SilentlyContinue
                    Write-Color "  Persistent routes: $($persistent.Count)" "White"
                    $active = Get-NetRoute -PolicyStore ActiveStore -ErrorAction SilentlyContinue
                    Write-Color "  Active routes: $($active.Count)" "White"
                    $bestRoutes = Get-NetRoute -AddressFamily IPv4 | Where-Object { $_.DestinationPrefix -ne '0.0.0.0/0' -and $_.RouteMetric -eq 0 } | Sort-Object DestinationPrefix
                    if ($bestRoutes) {
                        Write-Color "  Best/optimal routes (metric 0):" "Green"
                        $bestRoutes | Select-Object DestinationPrefix, NextHop, InterfaceAlias | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
                    }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
        }
        Pause
    }
}
