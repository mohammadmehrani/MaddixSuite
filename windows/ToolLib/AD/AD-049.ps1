Register-Tool @{
    ID          = 'AD-049'
    Name        = 'AD DNS Zones Migration'
    Category    = 'AD'
    Description = 'Export/import DNS zones, check zone status'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Export DNS zones and prepare migration?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $dc = (Get-ADDomainController -Filter * | Select-Object -First 1).Name
            $exportDir = Join-Path $env:TEMP "DNS-Migration-$(Get-Date -Format yyyyMMdd-HHmmss)"
            New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
            Write-Color "`n  ─── AD DNS ZONES MIGRATION ───" "Cyan"
            Write-Color "  Source DC: $dc" "White"
            Write-Color "  Export directory: $exportDir" "Gray"
            Write-Color "`n  [*] Enumerating DNS zones..." "Cyan"
            $zones = Get-DnsServerZone -ComputerName $dc -ErrorAction Stop
            $adZones = $zones | Where-Object { $_.IsAutoCreated -eq $false }
            Write-Color "  [i] Total zones: $($zones.Count)" "Gray"
            Write-Color "  [i] Non-auto zones: $($adZones.Count)" "Gray"
            Write-Color "`n  ─── Zone Status Report ───" "Cyan"
            $zoneReport = @()
            foreach ($zone in $zones | Sort-Object ZoneName) {
                try {
                    $zoneInfo = Get-DnsServerZone -Name $zone.ZoneName -ComputerName $dc -ErrorAction SilentlyContinue
                    $zoneStatus = "OK"
                    $zoneIssues = @()
                    if ($zone.ZoneType -eq 'Primary' -and $zone.IsDsIntegrated) {
                        $replScope = Get-DnsServerZoneScope -ZoneName $zone.ZoneName -ComputerName $dc -ErrorAction SilentlyContinue
                        $replicaDCs = ($replScope | Select-Object -ExpandProperty Scopes) -join ','
                    } else { $replicaDCs = "N/A (Not AD integrated)" }
                    $zoneReport += [PSCustomObject]@{
                        ZoneName = $zone.ZoneName
                        ZoneType = $zone.ZoneType
                        IsADIntegrated = $zone.IsDsIntegrated
                        IsReverseLookup = $zone.IsReverseLookupZone
                        DirectoryPartition = $zone.DirectoryPartition
                        ReplicaDCs = $replicaDCs
                    }
                } catch { $zoneReport += [PSCustomObject]@{ ZoneName = $zone.ZoneName; ZoneType = $zone.ZoneType; IsADIntegrated = $zone.IsDsIntegrated; IsReverseLookup = $zone.IsReverseLookupZone; DirectoryPartition = $zone.DirectoryPartition; ReplicaDCs = "Error" } }
            }
            $zoneReport | Format-Table ZoneName,ZoneType,IsADIntegrated,IsReverseLookup -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
            Write-Color "`n  ─── Zone Export ───" "Cyan"
            $exportCount = 0
            foreach ($zone in $adZones) {
                $file = Join-Path $exportDir "$($zone.ZoneName).dns"
                try {
                    Export-DnsServerZone -Name $zone.ZoneName -FileName $file -ComputerName $dc -ErrorAction Stop
                    Write-Color "  [✓] Exported: $($zone.ZoneName)" "Green"
                    $exportCount++
                } catch {
                    Write-Color "  [✗] Failed: $($zone.ZoneName) - $_" "Red"
                }
            }
            Write-Color "`n  ─── Summary ───" "Cyan"
            Write-Color "  [i] Zones exported: $exportCount / $($adZones.Count)" "White"
            Write-Color "  [i] Export location: $exportDir" "Green"
            $zoneReport | Export-Csv -Path (Join-Path $exportDir "ZoneReport.csv") -NoTypeInformation -Encoding UTF8
            Write-Color "  [i] Zone report: $(Join-Path $exportDir 'ZoneReport.csv')" "Green"
            Write-Color "`n  ─── Import Instructions ───" "Cyan"
            Write-Color "  On destination server:" "White"
            Write-Color "  Import-DnsServerZone -Name <zone> -FileName <file>" "Gray"
            Write-Color "  Or use DNSCMD:" "Gray"
            Write-Color "  dnscmd <DestDC> /ZoneAdd <zone> /Primary /File <zone.dns> /Load" "Gray"
            Write-Color "`n  [!] For AD-integrated zones, replication will handle transfer" "Yellow"
        } catch {
            Write-Color "  [!] AD DNS Zones Migration failed: $_" "Red"
        }
        Pause
    }
}
