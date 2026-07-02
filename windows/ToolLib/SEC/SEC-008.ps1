Register-Tool @{
    ID          = 'SEC-008'
    Name        = 'AppLocker Policy Check'
    Category    = 'SEC'
    Description = 'View AppLocker rules'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Check AppLocker application control policies'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $service = Get-Service -Name 'AppIDSvc' -ErrorAction SilentlyContinue
            if (-not $service -or $service.Status -ne 'Running') {
                Write-Color "  [!] AppLocker service (AppIDSvc) is not running. Some data may be unavailable." "Yellow"
            }

            Write-Color "  [+] AppLocker Policy Status:" "Green"
            try {
                $policy = Get-AppLockerPolicy -Effective -ErrorAction Stop
                Write-Color "    Policy exists and is applied" "Green"
            } catch {
                Write-Color "    No AppLocker policy configured or policy unavailable" "Yellow"
                Pause
                return
            }

            Write-Color "`n  [+] AppLocker Rules:" "Green"
            $rules = $policy.RuleCollections
            foreach ($collection in $rules) {
                Write-Color "  --- $($collection.GetType().Name) ---" "Yellow"
                foreach ($rule in $collection) {
                    $cond = $rule.conditions
                    Write-Color "    Rule: $($rule.Name)" "Cyan"
                    Write-Color "    Action: $($rule.Action)" "Cyan"
                    Write-Color "    User: $($rule.User)" "Cyan"
                    Write-Color "    Conditions: $($cond.PathConditions -join ', ')" "Cyan"
                    Write-Color "" "Cyan"
                }
            }

            Write-Color "`n  [+] Checking AppLocker event logs..." "Green"
            $events = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-AppLocker/EXE and DLL';ID=8003} -MaxEvents 10 -ErrorAction SilentlyContinue
            if ($events) {
                Write-Color "    Recent blocked executions:" "Yellow"
                $events | Select-Object TimeCreated, Message | Format-Table -AutoSize
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
