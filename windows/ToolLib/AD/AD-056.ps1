Register-Tool @{
    ID          = 'AD-056'
    Name        = 'AD Privileged Groups Monitor'
    Category    = 'AD'
    Description = 'Monitor changes to Domain Admins, Enterprise Admins'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Monitor privileged group membership changes?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $csvPath = Join-Path $env:TEMP "AD-PrivilegedGroupMonitor-$(Get-Date -Format yyyyMMdd-HHmmss).csv"
            $baselinePath = Join-Path $env:TEMP "AD-PrivilegedBaseline.csv"
            $thresholdDays = 90
            Write-Color "`n  ─── AD PRIVILEGED GROUPS MONITOR ───" "Cyan"
            $privGroups = @(
                @{Name="Domain Admins"; SID="S-1-5-21*-512"},
                @{Name="Enterprise Admins"; SID="S-1-5-21*-519"},
                @{Name="Schema Admins"; SID="S-1-5-21*-518"},
                @{Name="Administrators"; SID="S-1-5-32-544"},
                @{Name="Account Operators"; SID="S-1-5-32-548"},
                @{Name="Server Operators"; SID="S-1-5-32-549"},
                @{Name="Backup Operators"; SID="S-1-5-32-551"},
                @{Name="Print Operators"; SID="S-1-5-32-550"},
                @{Name="DnsAdmins"; SID="S-1-5-21*-1101"}
            )
            $currentSnapshot = @()
            Write-Color "  [*] Taking snapshot of privileged group memberships..." "Cyan"
            foreach ($pg in $privGroups) {
                try {
                    $group = Get-ADGroup -Filter "Name -eq '$($pg.Name)'" -Properties Name,DistinguishedName,Description,GroupScope -ErrorAction Stop
                    if (-not $group) { continue }
                    $members = Get-ADGroupMember -Identity $group.DistinguishedName -ErrorAction SilentlyContinue
                    if (-not $members) { $members = @() }
                    foreach ($member in $members) {
                        $memberDetail = $null
                        if ($member.objectClass -eq 'user') {
                            try { $memberDetail = Get-ADUser $member.DistinguishedName -Properties LastLogonDate,Enabled,Created,PasswordLastSet,SamAccountName -ErrorAction SilentlyContinue } catch {}
                        } elseif ($member.objectClass -eq 'group') {
                            try { $memberDetail = Get-ADGroup $member.DistinguishedName -Properties SamAccountName,Created -ErrorAction SilentlyContinue } catch {}
                        } elseif ($member.objectClass -eq 'computer') {
                            try { $memberDetail = Get-ADComputer $member.DistinguishedName -Properties SamAccountName,Created -ErrorAction SilentlyContinue } catch {}
                        }
                        $currentSnapshot += [PSCustomObject]@{
                            GroupName = $group.Name
                            GroupDN = $group.DistinguishedName
                            MemberName = $member.Name
                            MemberType = $member.objectClass
                            MemberSam = if ($memberDetail) { $memberDetail.SamAccountName } else { $member.SamAccountName }
                            MemberDN = $member.DistinguishedName
                            IsEnabled = if ($memberDetail -and $memberDetail.Enabled -ne $null) { $memberDetail.Enabled } else { "N/A" }
                            Created = if ($memberDetail -and $memberDetail.Created) { $memberDetail.Created.ToString("yyyy-MM-dd") } else { "Unknown" }
                            LastLogon = if ($memberDetail -and $memberDetail.LastLogonDate) { $memberDetail.LastLogonDate.ToString("yyyy-MM-dd") } else { "Unknown" }
                        }
                    }
                } catch {
                    Write-Color "  [!] Could not check group '$($pg.Name)': $_" "Yellow"
                }
            }
            $currentSnapshot | Sort-Object GroupName,MemberType,MemberSam | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
            Write-Color "  [+] Current snapshot saved: $csvPath" "Green"
            Write-Color "`n  ─── Current Members ───" "Cyan"
            $currentSnapshot | Group-Object GroupName | ForEach-Object {
                Write-Color "  $($_.Name): $($_.Count) members" "White"
                $_.Group | Select-Object MemberName,MemberType,MemberSam,IsEnabled | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
            }
            $baselineExists = Test-Path $baselinePath
            if ($baselineExists) {
                Write-Color "`n  ─── Baseline Comparison ───" "Cyan"
                $baseline = Import-Csv $baselinePath -Encoding UTF8
                $changes = Compare-Object $baseline $currentSnapshot -Property GroupName,MemberDN -PassThru
                $added = $changes | Where-Object { $_.SideIndicator -eq '=>' }
                $removed = $changes | Where-Object { $_.SideIndicator -eq '<=' }
                if ($added) {
                    Write-Color "  [+] New members added since baseline:" "Yellow"
                    $added | Select-Object GroupName,MemberName,MemberSam | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "White" }
                }
                if ($removed) {
                    Write-Color "  [!] Members removed since baseline:" "Yellow"
                    $removed | Select-Object GroupName,MemberName,MemberSam | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "White" }
                }
                if (-not $added -and -not $removed) {
                    Write-Color "  [i] No changes detected from baseline" "Green"
                }
            } else {
                Write-Color "`n  [i] No baseline file found. Saving current snapshot as baseline." "Cyan"
            }
            $currentSnapshot | Export-Csv -Path $baselinePath -NoTypeInformation -Encoding UTF8
            Write-Color "  [+] Baseline updated: $baselinePath" "Green"
            Write-Color "`n  ─── Inactive Privileged Accounts ───" "Cyan"
            $inactive = $currentSnapshot | Where-Object { $_.MemberType -eq 'user' -and $_.LastLogon -ne 'Unknown' } | Where-Object {
                try { [DateTime]$_.LastLogon -lt (Get-Date).AddDays(-$thresholdDays) } catch { $false }
            }
            if ($inactive) {
                Write-Color "  [!] Privileged accounts not logged on in $thresholdDays days:" "Yellow"
                $inactive | Select-Object GroupName,MemberName,LastLogon | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "White" }
            } else {
                Write-Color "  [✓] All privileged accounts have logged on recently" "Green"
            }
            Write-Color "`n  ─── Audit Recommendation ───" "Cyan"
            Write-Color "  Run this tool regularly to track changes" "White"
            Write-Color "  Configure Event ID 4728/4732/4756 alerts for real-time monitoring" "White"
        } catch {
            Write-Color "  [!] AD Privileged Groups Monitor failed: $_" "Red"
        }
        Pause
    }
}
