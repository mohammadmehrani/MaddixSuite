Register-Tool @{
    ID          = 'OPT-007'
    Name        = 'Network Optimizer'
    Category    = 'OPT'
    Description = 'TCP auto-tuning, RSS, network throttling'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Apply network performance optimizations'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Network Optimization:" "Green"

            Write-Color "`n  [*] TCP Auto-Tuning:" "Yellow"
            $tuning = netsh int tcp show global | Select-String 'Receive Window Auto-Tuning Level'
            Write-Color "    $($tuning.ToString().Trim())" "Cyan"
            $choice = Read-Host "  [+] Set auto-tuning level (normal/disabled/restricted)? (n/d/r)"
            switch ($choice) {
                'n' { netsh int tcp set global autotuninglevel=normal }
                'd' { netsh int tcp set global autotuninglevel=disabled }
                'r' { netsh int tcp set global autotuninglevel=restricted }
            }
            if ($choice) { Write-Color "  [+] TCP auto-tuning updated" "Green" }

            Write-Color "`n  [*] RSS (Receive Side Scaling):" "Yellow"
            $rss = netsh int tcp show global | Select-String 'Receive-Side Scaling State'
            Write-Color "    $($rss.ToString().Trim())" "Cyan"
            $rssSet = Read-Host "  [+] Enable RSS? (y/N)"
            if ($rssSet -eq 'y') { netsh int tcp set global rss=enabled; Write-Color "  [+] RSS enabled" "Green" }

            Write-Color "`n  [*] Network Throttling (registry):" "Yellow"
            $nt = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'NetworkThrottlingIndex' -ErrorAction SilentlyContinue
            $ntVal = if ($nt) { $nt.NetworkThrottlingIndex } else { 'Not Set' }
            Write-Color "    Current: $ntVal" "Cyan"
            $setNT = Read-Host "  [+] Disable network throttling (set to 0xFFFFFFFF)? (y/N)"
            if ($setNT -eq 'y') {
                Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'NetworkThrottlingIndex' -Value 0xFFFFFFFF -Type DWord
                Write-Color "  [+] Network throttling disabled" "Green"
            }

            Write-Color "`n  [*] TCP Chimney Offload:" "Yellow"
            $chimney = netsh int tcp show global | Select-String 'Chimney Offload State'
            Write-Color "    $($chimney.ToString().Trim())" "Cyan"

            Write-Color "`n  [*] DNS Cache:" "Yellow"
            $dnsSize = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name 'CacheHashTableBucketSize' -ErrorAction SilentlyContinue).CacheHashTableBucketSize
            Write-Color "    DNS Cache Bucket Size: $(if($dnsSize){$dnsSize}else{'Default'})" "Cyan"
            $flush = Read-Host "  [+] Flush DNS cache? (y/N)"
            if ($flush -eq 'y') { ipconfig /flushdns | Out-Null; Write-Color "  [+] DNS flushed" "Green" }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
