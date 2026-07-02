Register-Tool @{
    ID          = 'AD-041'
    Name        = 'AD Health Dashboard'
    Category    = 'AD'
    Description = 'Generate HTML dashboard with AD status, DCs, FSMO roles, replication, DNS, DHCP health'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Generate AD Health Dashboard HTML report?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $output = Join-Path $env:TEMP "AD-HealthDashboard-$(Get-Date -Format yyyyMMdd-HHmmss).html"
            $domain = Get-ADDomain
            $forest = Get-ADForest
            $dcs = Get-ADDomainController -Filter *
            $fsmo = @{
                'Schema Master' = $forest.SchemaMaster
                'Domain Naming Master' = $forest.DomainNamingMaster
                'PDC Emulator' = $domain.PDCEmulator
                'RID Master' = $domain.RIDMaster
                'Infrastructure Master' = $domain.InfrastructureMaster
            }
            $html = @"
<!DOCTYPE html><html><head><title>AD Health Dashboard</title>
<style>body{font-family:Segoe UI;margin:20px;background:#1e1e2e;color:#cdd6f4}h1{color:#cba6f7}h2{color:#89b4fa;border-bottom:1px solid #45475a;padding-bottom:5px}.ok{color:#a6e3a1}.warn{color:#f9e2af}.err{color:#f38ba8}table{width:100%;border-collapse:collapse;margin:10px 0}th,td{border:1px solid #45475a;padding:8px;text-align:left}th{background:#313244;color:#cdd6f4}tr:nth-child(even){background:#252538}.card{background:#313244;padding:15px;margin:10px 0;border-radius:8px}</style></head><body>
<h1>AD Health Dashboard - $($domain.DNSRoot)</h1>
<p>Generated: $(Get-Date)</p>
<div class="card"><h2>Domain / Forest</h2>
<table><tr><th>Property</th><th>Value</th></tr>
<tr><td>Domain</td><td>$($domain.DNSRoot)</td></tr>
<tr><td>NetBIOS</td><td>$($domain.NetBIOSName)</td></tr>
<tr><td>Forest</td><td>$($forest.RootDomain)</td></tr>
<tr><td>Forest Mode</td><td>$($forest.ForestMode)</td></tr>
<tr><td>Domain Mode</td><td>$($domain.DomainMode)</td></tr>
</table></div>
<div class="card"><h2>FSMO Role Holders</h2><table><tr><th>Role</th><th>Owner</th></tr>
"@
            foreach ($role in $fsmo.GetEnumerator() | Sort-Object Name) {
                $html += "<tr><td>$($role.Name)</td><td>$($role.Value)</td></tr>`n"
            }
            $html += "</table></div>"
            $html += "<div class='card'><h2>Domain Controllers</h2><table><tr><th>Name</th><th>Site</th><th>GC</th><th>RODC</th><th>OS</th><th>Status</th></tr>"
            foreach ($dc in $dcs) {
                $dcObj = Get-ADComputer $dc.Name -Properties OperatingSystem,Enabled,LastLogonDate
                $status = "Unknown"
                try {
                    if (Test-Connection -ComputerName $dc.Name -Count 1 -Quiet) { $status = "<span class='ok'>Online</span>" } else { $status = "<span class='err'>Offline</span>" }
                } catch { $status = "<span class='err'>Unreachable</span>" }
                $html += "<tr><td>$($dc.Name)</td><td>$($dc.Site)</td><td>$($dc.IsGlobalCatalog)</td><td>$($dc.IsReadOnly)</td><td>$($dcObj.OperatingSystem)</td><td>$status</td></tr>"
            }
            $html += "</table></div>"
            try {
                $repl = Get-ADReplicationSummary -ErrorAction Stop
                $html += "<div class='card'><h2>Replication Summary</h2><table><tr><th>Server</th><th>Partition</th><th>Status</th></tr>"
                foreach ($r in $repl) {
                    $repStat = if ($r.Status -eq 0) { "<span class='ok'>Healthy</span>" } else { "<span class='err'>Failed - $($r.FailureCount)</span>" }
                    $html += "<tr><td>$($r.Server)</td><td>$($r.Partition)</td><td>$repStat</td></tr>"
                }
                $html += "</table></div>"
            } catch { $html += "<div class='card'><h2>Replication</h2><p class='warn'>Could not retrieve replication data</p></div>" }
            try {
                $dns = Get-DnsServerZone -ComputerName $dcs[0].Name -ErrorAction Stop
                $html += "<div class='card'><h2>DNS Zones ($($dns.Count))</h2><table><tr><th>Zone</th><th>Type</th><th>Status</th></tr>"
                foreach ($z in $dns) {
                    $html += "<tr><td>$($z.ZoneName)</td><td>$($z.ZoneType)</td><td>$($z.IsAutoCreated)</td></tr>"
                }
                $html += "</table></div>"
            } catch { $html += "<div class='card'><h2>DNS</h2><p class='warn'>Could not query DNS</p></div>" }
            try {
                $scopes = Get-DhcpServerv4Scope -ComputerName $dcs[0].Name -ErrorAction Stop
                $html += "<div class='card'><h2>DHCP Scopes ($($scopes.Count))</h2><table><tr><th>Name</th><th>Range</th><th>Usage</th><th>State</th></tr>"
                foreach ($s in $scopes) {
                    $stats = Get-DhcpServerv4ScopeStatistics -ScopeId $s.ScopeId -ComputerName $dcs[0].Name -ErrorAction SilentlyContinue
                    $pct = if ($stats) { "{0:N0}%" -f (($stats.InUse / $stats.Used) * 100) } else { "N/A" }
                    $state = if ($s.State -eq "Active") { "<span class='ok'>Active</span>" } else { "<span class='warn'>$($s.State)</span>" }
                    $html += "<tr><td>$($s.Name)</td><td>$($s.StartRange) - $($s.EndRange)</td><td>$pct</td><td>$state</td></tr>"
                }
                $html += "</table></div>"
            } catch { $html += "<div class='card'><h2>DHCP</h2><p class='warn'>Could not query DHCP</p></div>" }
            $html += "<div class='card'><h2>Time Sync</h2><table><tr><th>DC</th><th>Time Difference</th></tr>"
            foreach ($dc in $dcs) {
                try {
                    $dcTime = [DateTime](Get-WmiObject -Class Win32_OperatingSystem -ComputerName $dc.Name -ErrorAction Stop).LocalDateTime
                    $diff = ((Get-Date) - $dcTime).TotalSeconds
                    $diffStr = if ([Math]::Abs($diff) -le 5) { "<span class='ok'>$([Math]::Round($diff,2))s</span>" } else { "<span class='warn'>$([Math]::Round($diff,2))s</span>" }
                    $html += "<tr><td>$($dc.Name)</td><td>$diffStr</td></tr>"
                } catch { $html += "<tr><td>$($dc.Name)</td><td class='err'>Unreachable</td></tr>" }
            }
            $html += "</table></div></body></html>"
            $html | Out-File -FilePath $output -Encoding UTF8
            Write-Color "  [+] Dashboard saved to: $output" "Green"
            Write-Color "  [+] Opening in default browser..." "Cyan"
            Start-Process $output
        } catch {
            Write-Color "  [!] AD Health Dashboard failed: $_" "Red"
        }
        Pause
    }
}
