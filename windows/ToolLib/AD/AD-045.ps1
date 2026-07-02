Register-Tool @{
    ID          = 'AD-045'
    Name        = 'AD Lockout Analysis'
    Category    = 'AD'
    Description = 'Find locked accounts, recent lockout events'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Analyze AD lockout events?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $pdc = (Get-ADDomain).PDCEmulator
            $lockedUsers = Search-ADAccount -LockedOut -ErrorAction Stop
            $csvPath = Join-Path $env:TEMP "AD-LockoutAnalysis-$(Get-Date -Format yyyyMMdd-HHmmss).csv"
            Write-Color "`n  ─── AD LOCKOUT ANALYSIS ───" "Cyan"
            Write-Color "  PDC Emulator: $pdc" "Gray"
            Write-Color "`n  [*] Currently locked accounts: $($lockedUsers.Count)" "Yellow"
            if ($lockedUsers.Count -gt 0) {
                $lockedUsers | Select-Object Name,SamAccountName,DistinguishedName,LockedOut,LastLogonDate | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "White" }
            }
            Write-Color "`n  [*] Scanning lockout events from last 7 days..." "Cyan"
            $results = @()
            try {
                $lockoutEvents = Get-WinEvent -ComputerName $pdc -FilterHashtable @{LogName='Security';Id=4740} -MaxEvents 500 -ErrorAction Stop
                foreach ($event in $lockoutEvents) {
                    if ($event.TimeCreated -lt (Get-Date).AddDays(-7)) { continue }
                    $user = $event.Properties[0].Value
                    $callerHost = $event.Properties[1].Value
                    $results += [PSCustomObject]@{
                        Time = $event.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                        Username = $user
                        CallerComputer = $callerHost
                        EventId = $event.Id
                    }
                }
            } catch { Write-Color "  [!] Could not read lockout events from PDC. Trying alternate DCs..." "Yellow" }
            if ($results.Count -eq 0) {
                $altDcs = Get-ADDomainController -Filter * | Where-Object { $_.Name -ne $pdc.Split('.')[0] }
                foreach ($altDc in $altDcs) {
                    try {
                        $lockoutEvents = Get-WinEvent -ComputerName $altDc.Name -FilterHashtable @{LogName='Security';Id=4740} -MaxEvents 200 -ErrorAction Stop
                        foreach ($event in $lockoutEvents) {
                            if ($event.TimeCreated -lt (Get-Date).AddDays(-7)) { continue }
                            $user = $event.Properties[0].Value
                            $callerHost = $event.Properties[1].Value
                            $results += [PSCustomObject]@{
                                Time = $event.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                                Username = $user
                                CallerComputer = $callerHost
                                EventId = $event.Id
                            }
                        }
                        if ($results.Count -gt 0) { Write-Color "  [+] Found events on $($altDc.Name)" "Green"; break }
                    } catch { continue }
                }
            }
            $results = $results | Sort-Object Time -Descending
            if ($results.Count -gt 0) {
                Write-Color "`n  ─── Recent Lockout Events (Last 7 days) ───" "Cyan"
                $results | Select-Object Time,Username,CallerComputer | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
                $results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                Write-Color "  [+] Events exported: $csvPath" "Green"
            } else {
                Write-Color "  [i] No lockout events found in last 7 days" "Green"
            }
            Write-Color "`n  ─── Password Policy ───" "Cyan"
            $policy = Get-ADDefaultDomainPasswordPolicy
            Write-Color "  LockoutThreshold: $($policy.LockoutThreshold)" "White"
            Write-Color "  LockoutDuration: $($policy.LockoutDuration)" "White"
            Write-Color "  LockoutObservationWindow: $($policy.LockoutObservationWindow)" "White"
            Write-Color "`n  [i] To unlock an account: Unlock-ADAccount -Identity <username>" "Cyan"
        } catch {
            Write-Color "  [!] AD Lockout Analysis failed: $_" "Red"
        }
        Pause
    }
}
