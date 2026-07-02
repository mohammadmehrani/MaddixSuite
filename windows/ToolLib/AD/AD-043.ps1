Register-Tool @{
    ID          = 'AD-043'
    Name        = 'AD Group Membership Report'
    Category    = 'AD'
    Description = 'Export all group memberships to CSV/HTML'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Export all AD group memberships?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $csvPath = Join-Path $env:TEMP "AD-GroupMembership-$(Get-Date -Format yyyyMMdd-HHmmss).csv"
            $htmlPath = Join-Path $env:TEMP "AD-GroupMembership-$(Get-Date -Format yyyyMMdd-HHmmss).html"
            $groups = Get-ADGroup -Filter * -Properties Description,GroupCategory,GroupScope,Members
            $results = @()
            $i = 0
            Write-Color "  [*] Processing $($groups.Count) groups..." "Cyan"
            foreach ($group in $groups) {
                $i++
                Write-Progress -Activity "Processing Groups" -Status $group.Name -PercentComplete (($i / $groups.Count) * 100)
                try {
                    $members = Get-ADGroupMember -Identity $group.DistinguishedName -ErrorAction Stop
                    if (-not $members) { $members = @() }
                } catch { $members = @() }
                foreach ($member in $members) {
                    $memberType = $member.objectClass
                    $memberDn = $member.distinguishedName
                    $memberName = $member.Name
                    $sam = $member.SamAccountName
                    try {
                        $memberObj = Get-ADObject -Identity $memberDn -Properties LastLogonDate,Enabled -ErrorAction Stop
                        $lastLogon = $memberObj.LastLogonDate
                        $enabled = $memberObj.Enabled
                    } catch { $lastLogon = $null; $enabled = $null }
                    $results += [PSCustomObject]@{
                        GroupName = $group.Name
                        GroupCategory = $group.GroupCategory
                        GroupScope = $group.GroupScope
                        GroupDescription = $group.Description
                        MemberName = $memberName
                        MemberSamAccountName = $sam
                        MemberType = $memberType
                        MemberDN = $memberDn
                        Enabled = $enabled
                        LastLogon = $lastLogon
                    }
                }
            }
            $results | Sort-Object GroupName,MemberName | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
            $html = "<!DOCTYPE html><html><head><title>AD Group Membership Report</title><style>body{font-family:Segoe UI;margin:20px;background:#1e1e2e;color:#cdd6f4}h1{color:#cba6f7}table{width:100%;border-collapse:collapse;margin:10px 0}th,td{border:1px solid #45475a;padding:6px;text-align:left}th{background:#313244}tr:nth-child(even){background:#252538}.count{color:#89b4fa}</style></head><body><h1>AD Group Membership Report</h1><p>Generated: $(Get-Date) | Groups: $($groups.Count) | Memberships: $($results.Count)</p>"
            $groupSummary = $results | Group-Object GroupName | Sort-Object Count -Descending
            $html += "<h2>Group Summary</h2><table><tr><th>Group</th><th>Type</th><th>Scope</th><th>Members</th></tr>"
            foreach ($gs in $groupSummary) {
                $g = $groups | Where-Object { $_.Name -eq $gs.Name }
                $html += "<tr><td>$($gs.Name)</td><td>$($g.GroupCategory)</td><td>$($g.GroupScope)</td><td>$($gs.Count)</td></tr>"
            }
            $html += "</table><h2>Detail</h2><table><tr><th>Group</th><th>Member</th><th>SAM</th><th>Type</th><th>Enabled</th><th>Last Logon</th></tr>"
            foreach ($r in $results | Sort-Object GroupName,MemberName) {
                $html += "<tr><td>$($r.GroupName)</td><td>$($r.MemberName)</td><td>$($r.MemberSamAccountName)</td><td>$($r.MemberType)</td><td>$($r.Enabled)</td><td>$($r.LastLogon)</td></tr>"
            }
            $html += "</table></body></html>"
            $html | Out-File -FilePath $htmlPath -Encoding UTF8
            Write-Color "  [+] CSV report: $csvPath" "Green"
            Write-Color "  [+] HTML report: $htmlPath" "Green"
            Write-Color "  [i] Total memberships: $($results.Count)" "Cyan"
            Start-Process $htmlPath
        } catch {
            Write-Color "  [!] AD Group Membership Report failed: $_" "Red"
        }
        Pause
    }
}
