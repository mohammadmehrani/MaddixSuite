Register-Tool @{
    ID          = 'AD-060'
    Name        = 'AD Automation Scheduler'
    Category    = 'AD'
    Description = 'Create scheduled tasks for AD maintenance'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Create scheduled AD maintenance tasks?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $taskDir = Join-Path $env:ProgramData "MaddixSuite\AD-Maintenance"
            if (-not (Test-Path $taskDir)) { New-Item -ItemType Directory -Path $taskDir -Force | Out-Null }
            Write-Color "`n  ─── AD AUTOMATION SCHEDULER ───" "Cyan"
            Write-Color "  This tool creates scheduled tasks for common AD maintenance activities" "Cyan"
            Write-Color "`n  Available tasks:" "White"
            Write-Color "  1. Daily AD Health Check (output to event log)" "White"
            Write-Color "  2. Weekly Inactive User Report (CSV export)" "White"
            Write-Color "  3. Daily Privileged Group Audit (baseline comparison)" "White"
            Write-Color "  4. Weekly Tombstone Lifetime Monitor" "White"
            Write-Color "  5. Daily AD Replication Status Check" "White"
            Write-Color "  6. Hourly Lockout Event Monitor" "White"
            $choices = Read-Host "`nEnter task numbers to create (comma-separated, e.g. 1,3,5)"
            $selectedTasks = $choices -split ',' | ForEach-Object { $_.Trim() }
            foreach ($sel in $selectedTasks) {
                switch ($sel) {
                    "1" {
                        $scriptPath = Join-Path $taskDir "AD-HealthCheck.ps1"
                        @"
`$domain = Get-ADDomain -ErrorAction SilentlyContinue
`$healthStatus = "OK"
`$issues = @()
try {
    `$dcs = Get-ADDomainController -Filter *
    foreach (`$dc in `$dcs) {
        `$online = Test-Connection -ComputerName `$dc.Name -Count 1 -Quiet -ErrorAction SilentlyContinue
        if (-not `$online) { `$issues += "DC offline: `$(`$dc.Name)"; `$healthStatus = "WARN" }
    }
    `$repl = Get-ADReplicationSummary -ErrorAction SilentlyContinue
    foreach (`$r in `$repl) {
        if (`$r.Status -ne 0) { `$issues += "Replication failure on `$(`$r.Server)"; `$healthStatus = "ERROR" }
    }
    if (`$issues.Count -eq 0) { `$issues += "All checks passed" }
    Write-EventLog -LogName Application -Source "AD-Maintenance" -EntryType Information -EventId 1000 -Message "AD Health Check: `$healthStatus`nIssues: `$(`$issues -join '; ')"
} catch {
    Write-EventLog -LogName Application -Source "AD-Maintenance" -EntryType Error -EventId 1001 -Message "AD Health Check failed: `$_"
}
"@ | Out-File -FilePath $scriptPath -Encoding UTF8
                        $taskParams = @{TaskName="AD-HealthCheck"; Script=$scriptPath; Trigger=(New-ScheduledTaskTrigger -Daily -At "06:00AM"); Description="Daily AD health check - logs to Application event log"}
                        Write-Color "  [*] Registering task: AD-HealthCheck" "Cyan"
                        Register-ScheduledTask @taskParams -Force -ErrorAction Stop | Out-Null
                        Write-Color "  [+] AD-HealthCheck scheduled (daily 6:00 AM)" "Green"
                    }
                    "2" {
                        $scriptPath = Join-Path $taskDir "AD-InactiveUserReport.ps1"
                        @"
`$csvPath = "$env:TEMP\AD-InactiveUsers-`$(Get-Date -Format yyyyMMdd).csv"
`$threshold = (Get-Date).AddDays(-90)
`$users = Get-ADUser -Filter { Enabled -eq `$true } -Properties LastLogonDate,SamAccountName,Name,PasswordLastSet
`$inactive = `$users | Where-Object { -not `$_.LastLogonDate -or `$_.LastLogonDate -lt `$threshold }
`$inactive | Select-Object SamAccountName,Name,LastLogonDate,PasswordLastSet | Export-Csv -Path `$csvPath -NoTypeInformation
Write-EventLog -LogName Application -Source "AD-Maintenance" -EntryType Information -EventId 2000 -Message "Inactive user report generated: `$(`$inactive.Count) inactive users. Report: `$csvPath"
"@ | Out-File -FilePath $scriptPath -Encoding UTF8
                        $taskParams = @{TaskName="AD-InactiveUserReport"; Script=$scriptPath; Trigger=(New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "07:00AM"); Description="Weekly inactive user report (90+ days)"}
                        Register-ScheduledTask @taskParams -Force -ErrorAction Stop | Out-Null
                        Write-Color "  [+] AD-InactiveUserReport scheduled (weekly Monday 7:00 AM)" "Green"
                    }
                    "3" {
                        $scriptPath = Join-Path $taskDir "AD-PrivilegedGroupAudit.ps1"
                        @"
`$baselinePath = "$env:TEMP\AD-PrivilegedBaseline.xml"
`$groupNames = @("Domain Admins","Enterprise Admins","Schema Admins","Administrators")
`$snapshot = @()
foreach (`$g in `$groupNames) {
    try {
        `$group = Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue
        if (`$group) {
            `$members = Get-ADGroupMember `$group.DistinguishedName -ErrorAction SilentlyContinue
            foreach (`$m in `$members) {
                `$snapshot += [PSCustomObject]@{Group=`$g;Member=`$m.Name;DN=`$m.DistinguishedName;Timestamp=(Get-Date)}
            }
        }
    } catch {}
}
if (Test-Path `$baselinePath) {
    `$baseline = Import-Clixml -Path `$baselinePath
    `$diff = Compare-Object `$baseline `$snapshot -Property Group,Member -PassThru
    if (`$diff) {
        `$changes = `$diff | Select-Object Group,Member,@{N='Change';E={if(`$_.SideIndicator -eq '=>'){'Added'}else{'Removed'}}}
        `$changes | Export-Csv -Path "$env:TEMP\AD-PrivilegedChanges-`$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation
        Write-EventLog -LogName Security -Source "AD-Maintenance" -EntryType Warning -EventId 3000 -Message "Privileged group change detected: `$(`$changes.Count) changes"
    }
}
`$snapshot | Export-Clixml -Path `$baselinePath
"@ | Out-File -FilePath $scriptPath -Encoding UTF8
                        $taskParams = @{TaskName="AD-PrivilegedGroupAudit"; Script=$scriptPath; Trigger=(New-ScheduledTaskTrigger -Daily -At "08:00AM"); Description="Daily privileged group membership audit"}
                        Register-ScheduledTask @taskParams -Force -ErrorAction Stop | Out-Null
                        Write-Color "  [+] AD-PrivilegedGroupAudit scheduled (daily 8:00 AM)" "Green"
                    }
                    "4" {
                        $scriptPath = Join-Path $taskDir "AD-TombstoneMonitor.ps1"
                        @"
`$configNC = (Get-ADRootDSE).ConfigurationNamingContext
`$tsl = Get-ADObject "CN=Directory Service,CN=Windows NT,CN=Services,`$configNC" -Properties tombstoneLifetime
`$value = if (`$tsl.tombstoneLifetime) { `$tsl.tombstoneLifetime } else { 180 }
if (`$value -lt 60) {
    Write-EventLog -LogName Application -Source "AD-Maintenance" -EntryType Warning -EventId 4000 -Message "Tombstone lifetime is `$value days - below recommended 180 days"
} else {
    Write-EventLog -LogName Application -Source "AD-Maintenance" -EntryType Information -EventId 4001 -Message "Tombstone lifetime is `$value days - OK"
}
"@ | Out-File -FilePath $scriptPath -Encoding UTF8
                        $taskParams = @{TaskName="AD-TombstoneMonitor"; Script=$scriptPath; Trigger=(New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "09:00AM"); Description="Weekly tombstone lifetime check"}
                        Register-ScheduledTask @taskParams -Force -ErrorAction Stop | Out-Null
                        Write-Color "  [+] AD-TombstoneMonitor scheduled (weekly Sunday 9:00 AM)" "Green"
                    }
                    "5" {
                        $scriptPath = Join-Path $taskDir "AD-ReplicationCheck.ps1"
                        @"
try {
    `$failures = 0
    `$dcs = Get-ADDomainController -Filter *
    foreach (`$dc in `$dcs) {
        try {
            `$repl = Get-ADReplicationFailure -Target `$dc.Name -ErrorAction Stop
            if (`$repl) {
                `$failures++
                `$repl | ForEach-Object { Write-EventLog -LogName Application -Source "AD-Maintenance" -EntryType Warning -EventId 5000 -Message "Replication failure on `$(`$dc.Name): `$(`$_.FailureType) - `$(`$_.LastFailureMessage)" }
            }
        } catch {}
    }
    if (`$failures -eq 0) {
        Write-EventLog -LogName Application -Source "AD-Maintenance" -EntryType Information -EventId 5001 -Message "AD replication check passed - no failures on `$(`$dcs.Count) DCs"
    }
} catch {
    Write-EventLog -LogName Application -Source "AD-Maintenance" -EntryType Error -EventId 5002 -Message "AD replication check failed: `$_"
}
"@ | Out-File -FilePath $scriptPath -Encoding UTF8
                        $taskParams = @{TaskName="AD-ReplicationCheck"; Script=$scriptPath; Trigger=(New-ScheduledTaskTrigger -Daily -At "05:00AM"); Description="Daily AD replication status check"}
                        Register-ScheduledTask @taskParams -Force -ErrorAction Stop | Out-Null
                        Write-Color "  [+] AD-ReplicationCheck scheduled (daily 5:00 AM)" "Green"
                    }
                    "6" {
                        $scriptPath = Join-Path $taskDir "AD-LockoutMonitor.ps1"
                        @"
try {
    `$pdc = (Get-ADDomain).PDCEmulator
    `$events = Get-WinEvent -ComputerName `$pdc -FilterHashtable @{LogName='Security';Id=4740} -MaxEvents 50 -ErrorAction Stop
    `$recent = `$events | Where-Object { `$_.TimeCreated -gt (Get-Date).AddHours(-1) }
    if (`$recent) {
        `$count = (`$recent | Measure-Object).Count
        `$users = `$recent | ForEach-Object { `$_.Properties[0].Value } | Select-Object -Unique
        Write-EventLog -LogName Application -Source "AD-Maintenance" -EntryType Warning -EventId 6000 -Message "Lockout alert: `$count lockout(s) in last hour. Users: `$(`$users -join ', ')"
    }
} catch {
    Write-EventLog -LogName Application -Source "AD-Maintenance" -EntryType Information -EventId 6001 -Message "Lockout monitor check completed (no errors or no events)"
}
"@ | Out-File -FilePath $scriptPath -Encoding UTF8
                        $taskParams = @{TaskName="AD-LockoutMonitor"; Script=$scriptPath; Trigger=(New-ScheduledTaskTrigger -Once -RepetitionInterval (New-TimeSpan -Minutes 60) -At (Get-Date).AddHours(1)); Description="Hourly lockout event monitor"}
                        Register-ScheduledTask @taskParams -Force -ErrorAction Stop | Out-Null
                        Write-Color "  [+] AD-LockoutMonitor scheduled (hourly)" "Green"
                    }
                    default { Write-Color "  [!] Unknown selection: $sel" "Yellow" }
                }
            }
            # Create the event log source if it doesn't exist
            if (-not [System.Diagnostics.EventLog]::SourceExists("AD-Maintenance")) {
                New-EventLog -LogName Application -Source "AD-Maintenance" -ErrorAction SilentlyContinue
            }
            Write-Color "`n  ─── Scheduled Tasks Summary ───" "Cyan"
            Get-ScheduledTask -TaskName "AD-*" -ErrorAction SilentlyContinue | Select-Object TaskName,State,@{N='NextRun';E={$_.NextRunTime}} | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
            Write-Color "  [+] Scripts location: $taskDir" "Green"
            Write-Color "  [i] Events logged to: Application log (source: AD-Maintenance)" "Gray"
        } catch {
            Write-Color "  [!] AD Automation Scheduler failed: $_" "Red"
        }
        Pause
    }
}
