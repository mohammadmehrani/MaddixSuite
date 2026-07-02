Register-Tool @{
    ID          = 'SRV-010'
    Name        = 'Server Manager Dashboard'
    Category    = 'SRV'
    Description = 'Quick view of server roles and performance'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Show Server Manager dashboard?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Server Manager Dashboard" "Cyan"
            Write-Color "  " ""
            Write-Color "  ===== SERVER INFO =====" "Yellow"
            $cs = Get-CimInstance Win32_ComputerSystem
            $os = Get-CimInstance Win32_OperatingSystem
            Write-Color "  [+] Hostname:      $($cs.Name)" "Gray"
            Write-Color "  [+] Domain:        $($cs.Domain)" "Gray"
            Write-Color "  [+] OS:            $($os.Caption)" "Gray"
            Write-Color "  [+] Version:       $($os.Version)" "Gray"
            Write-Color "  [+] Build:         $($os.BuildNumber)" "Gray"
            Write-Color "  [+] Manufacturer:  $($cs.Manufacturer) $($cs.Model)" "Gray"
            Write-Color "  [+] CPU Cores:     $($cs.NumberOfLogicalProcessors)" "Gray"
            Write-Color "  [+] RAM:           $([math]::Round($cs.TotalPhysicalMemory/1GB,2)) GB" "Gray"
            Write-Color "  [+] Uptime:        $(Get-CimInstance Win32_OperatingSystem | % { (Get-Date) - $_.LastBootUpTime | %{ "$($_.Days)d $($_.Hours)h $($_.Minutes)m" } })" "Gray"

            Write-Color "`n  ===== PERFORMANCE =====" "Yellow"
            $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
            $memFree = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
            $memTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
            $memPct = [math]::Round(($memTotal - $memFree) / $memTotal * 100, 1)
            Write-Color "  [+] CPU Usage:    $($cpu.Average)%" "Gray"
            Write-Color "  [+] Memory Usage: $memPct% ($($memTotal - $memFree) GB / $memTotal GB)" "Gray"

            $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
            foreach ($disk in $disks) {
                $pct = [math]::Round(($disk.Size - $disk.FreeSpace) / $disk.Size * 100, 1)
                $usedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 1)
                $totalGB = [math]::Round($disk.Size / 1GB, 1)
                Write-Color "  [+] $($disk.DeviceID)  $pct% used ($usedGB GB / $totalGB GB)" "Gray"
            }

            Write-Color "`n  ===== INSTALLED ROLES & FEATURES =====" "Yellow"
            $features = Get-WindowsFeature -ErrorAction SilentlyContinue | Where-Object { $_.Installed -and $_.Category }
            if ($features) {
                $features | Group-Object -Property Category | Sort-Object Name |
                    ForEach-Object {
                        $featNames = ($_.Group.DisplayName -join ', ')
                        Write-Color "  [+] [$($_.Name)] $($_.Count) installed" "Gray"
                    }
                Write-Color "  [+] Total roles/features: $($features.Count)" "Green"
            } else {
                $optFeats = Get-WindowsOptionalFeature -Online -ErrorAction SilentlyContinue |
                    Where-Object { $_.State -eq 'Enabled' }
                Write-Color "  [+] Enabled Windows Features: $(($optFeats | Measure-Object).Count)" "Gray"
            }

            Write-Color "`n  ===== SERVICES STATUS =====" "Yellow"
            $criticalServices = @(
                @{Name='W3SVC'; Label='IIS Web Server'},
                @{Name='DHCP'; Label='DHCP Server'},
                @{Name='DNS'; Label='DNS Server'},
                @{Name='WinRM'; Label='WinRM'},
                @{Name='Wecsvc'; Label='Event Collector'},
                @{Name='TermService'; Label='Remote Desktop'}
            )
            foreach ($svc in $criticalServices) {
                $s = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
                if ($s) {
                    $color = if ($s.Status -eq 'Running') { 'Green' } else { 'Red' }
                    Write-Color "  [$($s.Status)] $($svc.Label) ($($svc.Name))" $color
                }
            }

            Write-Color "`n  ===== NETWORK =====" "Yellow"
            $adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue
            foreach ($adapter in $adapters) {
                $ip = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
                Write-Color "  [+] $($adapter.Name): $(if($ip){$ip.IPAddress}else{'No IP'}) ($($adapter.LinkSpeed))" "Gray"
            }

            Write-Color "`n  [+] Dashboard generated at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Cyan"
        } catch {
            Write-Color "  [!] Dashboard failed: $_" "Red"
        }
        Pause
    }
}
