Register-Tool @{
    ID          = 'AD-050'
    Name        = 'AD Automated DR Plan'
    Category    = 'AD'
    Description = 'Generate disaster recovery runbook'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Generate AD disaster recovery runbook?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $domain = Get-ADDomain
            $forest = Get-ADForest
            $dcs = Get-ADDomainController -Filter *
            $output = Join-Path $env:TEMP "AD-DR-Runbook-$(Get-Date -Format yyyyMMdd-HHmmss).html"
            $sites = Get-ADReplicationSite -Filter *
            $subnets = Get-ADReplicationSubnet -Filter *
            $dnsZones = Get-DnsServerZone -ComputerName $dcs[0].Name -ErrorAction SilentlyContinue
            $gpos = Get-GPO -All -ErrorAction SilentlyContinue
            $html = @"
<!DOCTYPE html><html><head><title>AD Disaster Recovery Runbook</title>
<style>body{font-family:Segoe UI;margin:20px;background:#1e1e2e;color:#cdd6f4}h1{color:#cba6f7;border-bottom:2px solid #cba6f7}h2{color:#89b4fa}h3{color:#a6e3a1}.section{background:#313244;padding:15px;margin:10px 0;border-radius:8px;border-left:4px solid #89b4fa}.warning{border-left-color:#f9e2af;background:#313244}.critical{border-left-color:#f38ba8;background:#313244}code{background:#45475a;padding:2px 6px;border-radius:4px;font-family:Cascadia Code,Consolas}table{width:100%;border-collapse:collapse;margin:10px 0}th,td{border:1px solid #45475a;padding:6px;text-align:left}th{background:#252538}.ok{color:#a6e3a1}.warn{color:#f9e2af}.err{color:#f38ba8}</style></head><body>
<h1>AD Disaster Recovery Runbook</h1>
<p>Generated: $(Get-Date) | Domain: $($domain.DNSRoot) | Forest: $($forest.RootDomain)</p>
<div class="section critical"><h2>1. Contact Information</h2>
<p><strong>Emergency Contacts:</strong></p>
<table><tr><th>Role</th><th>Contact</th></tr>
<tr><td>AD Administrators</td><td>Enterprise Admins group</td></tr>
<tr><td>DNS Administrators</td><td>Domain Admins group</td></tr>
<tr><td>Backup Operators</td><td>Backup Operators group</td></tr>
</table></div>
<div class="section"><h2>2. Forest/Domain Information</h2>
<table>
<tr><td>Forest Root</td><td>$($forest.RootDomain)</td></tr>
<tr><td>Forest Mode</td><td>$($forest.ForestMode)</td></tr>
<tr><td>Domain</td><td>$($domain.DNSRoot) ($($domain.NetBIOSName))</td></tr>
<tr><td>Domain Mode</td><td>$($domain.DomainMode)</td></tr>
<tr><td>UPN Suffixes</td><td>$($forest.UPNSuffixes -join ', ')</td></tr>
</table></div>
<div class="section"><h2>3. Domain Controllers</h2><table><tr><th>DC</th><th>Site</th><th>GC</th><th>RODC</th><th>IP</th></tr>
"@
            foreach ($dc in $dcs) {
                try {
                    $ip = (Resolve-DnsName $dc.Name -Type A -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress
                } catch { $ip = "Unknown" }
                $html += "<tr><td>$($dc.Name)</td><td>$($dc.Site)</td><td>$($dc.IsGlobalCatalog)</td><td>$($dc.IsReadOnly)</td><td>$ip</td></tr>"
            }
            $html += "</table></div>"
            $html += "<div class='section'><h2>4. FSMO Role Holders</h2><table><tr><th>Role</th><th>Server</th><th>Seize Command</th></tr>
<tr><td>Schema Master</td><td>$($forest.SchemaMaster)</td><td><code>Move-ADDirectoryServerOperationMasterRole -Identity <server> -OperationMasterRole SchemaMaster -Force</code></td></tr>
<tr><td>Domain Naming Master</td><td>$($forest.DomainNamingMaster)</td><td><code>Move-ADDirectoryServerOperationMasterRole -Identity <server> -OperationMasterRole DomainNamingMaster -Force</code></td></tr>
<tr><td>PDC Emulator</td><td>$($domain.PDCEmulator)</td><td><code>Move-ADDirectoryServerOperationMasterRole -Identity <server> -OperationMasterRole PDCEmulator -Force</code></td></tr>
<tr><td>RID Master</td><td>$($domain.RIDMaster)</td><td><code>Move-ADDirectoryServerOperationMasterRole -Identity <server> -OperationMasterRole RIDMaster -Force</code></td></tr>
<tr><td>Infrastructure Master</td><td>$($domain.InfrastructureMaster)</td><td><code>Move-ADDirectoryServerOperationMasterRole -Identity <server> -OperationMasterRole InfrastructureMaster -Force</code></td></tr>
</table></div>"
            $html += "<div class='section'><h2>5. Sites &amp; Subnets</h2><table><tr><th>Site</th><th>Subnets</th></tr>"
            foreach ($site in $sites) {
                $siteSubs = $subnets | Where-Object { $_.Site -eq $site.Name } | Select-Object -ExpandProperty Name -Join ', '
                $html += "<tr><td>$($site.Name)</td><td>$siteSubs</td></tr>"
            }
            $html += "</table></div>"
            $html += "<div class='section warning'><h2>6. Recovery Procedures</h2>
<h3>6.1 Single DC Failure</h3>
<code># Promote replacement DC`nInstall-WindowsFeature AD-Domain-Services`nInstall-ADDSDomainController -DomainName $($domain.DNSRoot) -Credential (Get-Credential)</code>
<h3>6.2 All DCs Lost (Authoritative Restore)</h3>
<p>1. Restore DC from backup (must be within tombstone lifetime)</p>
<p>2. Perform authoritative restore: <code>ntdsutil "authoritative restore" "restore object OU=... DC=..." q q</code></p>
<h3>6.3 Forest Recovery</h3>
<p>1. Identify backup of first DC in forest root</p>
<p>2. Restore in Directory Services Repair Mode (DSRM)</p>
<p>3. Perform authoritative restore of entire directory</p>
<p>4. Reinstall AD DS on other DCs and replicate</p>
</div>"
            $html += "<div class='section'><h2>7. Backup Strategy</h2><table><tr><th>Component</th><th>Recommendation</th></tr>
<tr><td>System State</td><td>Backup all DCs daily</td></tr>
<tr><td>AD Database (ntds.dit)</td><td>Included in system state</td></tr>
<tr><td>SYSVOL</td><td>Included in system state (FRS/DFSR)</td></tr>
<tr><td>DNS Zones</td><td>AD-integrated (backed up with AD)</td></tr>
<tr><td>GPOs</td><td>Backup with: <code>Backup-GPO -All -Path <path></code></td></tr>
<tr><td>DHCP</td><td>Backup with: <code>netsh dhcp server export <file> all</code></td></tr>
</table></div>"
            $html += "<div class='section'><h2>8. Backup Age Check</h2><table><tr><th>DC</th><th>Last Backup (est.)</th></tr>"
            foreach ($dc in $dcs) {
                try {
                    $lastBkp = (Get-ChildItem "\\$($dc.Name)\C$\Windows\System32\wbadmin\*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
                    if ($lastBkp) {
                        $daysOld = ((Get-Date) - $lastBkp).Days
                        $cls = if ($daysOld -gt $effectiveTsl) { "err" } elseif ($daysOld -gt 30) { "warn" } else { "ok" }
                        $html += "<tr><td>$($dc.Name)</td><td class='$cls'>$($lastBkp.ToString('yyyy-MM-dd')) ($daysOld days ago)</td></tr>"
                    } else { $html += "<tr><td>$($dc.Name)</td><td class='warn'>No backup found</td></tr>" }
                } catch { $html += "<tr><td>$($dc.Name)</td><td class='err'>Cannot access</td></tr>" }
            }
            $html += "</table></div></body></html>"
            $html | Out-File -FilePath $output -Encoding UTF8
            Write-Color "  [+] DR Runbook saved: $output" "Green"
            Write-Color "  [+] Opening runbook..." "Cyan"
            Start-Process $output
        } catch {
            Write-Color "  [!] AD DR Plan generation failed: $_" "Red"
        }
        Pause
    }
}
