Register-Tool @{
    ID          = 'NET-022'
    Name        = 'DNS Cache Viewer'
    Category    = 'NET'
    Description = 'View, analyze, and flush DNS cache entries'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only. Views and analyzes DNS resolver cache.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── DNS CACHE VIEWER ───" "Cyan"
        Write-Color "  1. Show all cached entries" "White"
        Write-Color "  2. Search cache by domain" "White"
        Write-Color "  3. Show cache statistics" "White"
        Write-Color "  4. Flush DNS cache" "White"
        Write-Color "  5. Export cache to file" "White"
        Write-Color "  0. Back" "Red"
        $c = Read-Host "`n  Select option"
        switch ($c) {
            "1" {
                try {
                    $cache = Get-DnsClientCache -ErrorAction Stop
                    if (-not $cache) { Write-Color "  No cached entries." "Yellow"; break }
                    Write-Color "  Total entries: $($cache.Count)" "White"
                    $cache | Select-Object Entry, Type, Data, TimeToLive, Section | Sort-Object Entry | Format-Table -AutoSize -Wrap | Out-String -Width 4096 | ForEach-Object { Write-Color $_ "Gray" }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "2" {
                try {
                    $search = Read-Host "  Search domain"
                    $cache = Get-DnsClientCache -ErrorAction Stop | Where-Object { $_.Entry -like "*$search*" }
                    if ($cache) {
                        Write-Color "  Found $($cache.Count) match(es):" "Green"
                        $cache | Select-Object Entry, Type, Data, TimeToLive | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
                    } else {
                        Write-Color "  No matches for '$search'" "Yellow"
                    }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "3" {
                try {
                    $cache = Get-DnsClientCache -ErrorAction Stop
                    Write-Color "  ┌──────────────────────────────────────┐" "Cyan"
                    Write-Color "  │         DNS CACHE STATISTICS         │" "Cyan"
                    Write-Color "  ├──────────────────────────────────────┤" "Cyan"
                    Write-Color "  │ Total Entries:     $($cache.Count)".PadRight(39) + "│" "White"
                    $typeGroups = $cache | Group-Object Type | Sort-Object Count -Descending
                    foreach ($g in $typeGroups) {
                        Write-Color "  │ $($g.Name):".PadRight(22) + "$($g.Count)".PadRight(17) + "│" "Gray"
                    }
                    $sectionGroups = $cache | Group-Object Section | Sort-Object Count -Descending
                    foreach ($g in $sectionGroups) {
                        Write-Color "  │ $($g.Name):".PadRight(22) + "$($g.Count)".PadRight(17) + "│" "Gray"
                    }
                    $totalTtl = ($cache | Measure-Object TimeToLive -Average).Average
                    Write-Color "  │ Avg TTL:".PadRight(22) + "$('{0:N0}' -f $totalTtl)s".PadRight(17) + "│" "Gray"
                    Write-Color "  └──────────────────────────────────────┘" "Cyan"
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "4" {
                try {
                    $confirm = Read-Host "  Flush entire DNS cache? (y/N)"
                    if ($confirm -eq "y") {
                        Clear-DnsClientCache -ErrorAction Stop
                        Write-Color "  [+] DNS cache flushed successfully" "Green"
                    } else { Write-Color "  Cancelled." "Yellow" }
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
            "5" {
                try {
                    $cache = Get-DnsClientCache -ErrorAction Stop
                    $file = "$env:USERPROFILE\Desktop\MaddixSuite\DNS_Cache_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
                    $exportDir = Split-Path $file -Parent
                    if (-not (Test-Path $exportDir)) { New-Item -ItemType Directory -Path $exportDir -Force | Out-Null }
                    $cache | Select-Object Entry, Type, Data, TimeToLive, Section | Export-Csv -Path $file -NoTypeInformation
                    Write-Color "  [+] Exported to $file" "Green"
                } catch { Write-Color "  [!] Error: $_" "Red" }
            }
        }
        Pause
    }
}
