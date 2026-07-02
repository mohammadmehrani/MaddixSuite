Register-Tool @{
    ID          = 'AD-044'
    Name        = 'AD Last Logon Report'
    Category    = 'AD'
    Description = 'Find users who have not logged on in 90+ days'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Find inactive user accounts (90+ days)?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $threshold = (Get-Date).AddDays(-90)
            $csvPath = Join-Path $env:TEMP "AD-InactiveUsers-$(Get-Date -Format yyyyMMdd-HHmmss).csv"
            $dcs = Get-ADDomainController -Filter * | Select-Object -ExpandProperty Name
            $users = Get-ADUser -Filter { Enabled -eq $true } -Properties SamAccountName,Name,LastLogonDate,LastLogonTimestamp,PasswordLastSet,DistinguishedName,Enabled,AccountExpirationDate,Description -ResultPageSize 2000
            $results = @()
            Write-Color "  [*] Processing $($users.Count) enabled users across $($dcs.Count) DCs..." "Cyan"
            $i = 0
            foreach ($user in $users) {
                $i++
                Write-Progress -Activity "Checking user activity" -Status $user.SamAccountName -PercentComplete (($i / $users.Count) * 100)
                $latestLogon = $null
                $latestDc = $null
                foreach ($dc in $dcs) {
                    try {
                        $dcUser = Get-ADUser $user.SamAccountName -Properties LastLogonDate -Server $dc -ErrorAction Stop
                        if ($dcUser.LastLogonDate -and ($null -eq $latestLogon -or $dcUser.LastLogonDate -gt $latestLogon)) {
                            $latestLogon = $dcUser.LastLogonDate
                            $latestDc = $dc
                        }
                    } catch { continue }
                }
                if (-not $latestLogon) { $latestLogon = $user.LastLogonDate }
                if (-not $latestLogon -or $latestLogon -lt $threshold) {
                    $daysInactive = if ($latestLogon) { [Math]::Round(((Get-Date) - $latestLogon).TotalDays, 1) } else { "Never" }
                    $results += [PSCustomObject]@{
                        Username = $user.SamAccountName
                        Name = $user.Name
                        Email = $user.UserPrincipalName
                        LastLogon = if ($latestLogon) { $latestLogon.ToString("yyyy-MM-dd HH:mm") } else { "Never" }
                        DaysInactive = $daysInactive
                        PasswordLastSet = if ($user.PasswordLastSet) { $user.PasswordLastSet.ToString("yyyy-MM-dd") } else { "Never" }
                        DN = $user.DistinguishedName
                        Description = $user.Description
                        LastDC = $latestDc
                    }
                }
            }
            $results | Sort-Object { if ($_.DaysInactive -is [int]) { $_.DaysInactive } else { 9999 } } -Descending | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
            Write-Color "`n  ─── INACTIVE USERS (90+ days) ───" "Cyan"
            Write-Color "  [+] Found $($results.Count) inactive users" "Yellow"
            $results | Select-Object Username,Name,LastLogon,DaysInactive,PasswordLastSet | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
            Write-Color "  [+] Report saved: $csvPath" "Green"
            if ($results.Count -gt 0) {
                Write-Color "`n  [i] Review and disable with: Disable-ADAccount -Identity <username>" "Yellow"
            }
        } catch {
            Write-Color "  [!] AD Last Logon Report failed: $_" "Red"
        }
        Pause
    }
}
