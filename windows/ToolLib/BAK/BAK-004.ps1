Register-Tool @{
    ID          = 'BAK-004'
    Name        = 'Scheduled Backup Config'
    Category    = 'BAK'
    Description = 'Create scheduled task for regular backups'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Create a scheduled daily backup task?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $taskName = "MaddixSuite Daily Backup"
            $scriptPath = Join-Path $PSScriptRoot "BAK-003.ps1"
            $taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

            if ($taskExists) {
                Write-Color "  [!] Task '$taskName' already exists" "Yellow"
                $choice = Read-Host "  [?] Overwrite existing task? (y/N)"
                if ($choice -ne 'y') {
                    Write-Color "  [i] Skipping task creation" "Gray"
                    Pause
                    return
                }
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            }

            $action = New-ScheduledTaskAction -Execute "powershell.exe" `
                -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
            $trigger = New-ScheduledTaskTrigger -Daily -At "02:00AM"
            $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

            Register-ScheduledTask -TaskName $taskName `
                -Action $action `
                -Trigger $trigger `
                -Principal $principal `
                -Settings $settings `
                -Description "Daily backup of user profile folders" | Out-Null

            Write-Color "  [+] Task '$taskName' created (daily at 2:00 AM)" "Green"

            $task = Get-ScheduledTask -TaskName $taskName
            Write-Color "  [+] State: $($task.State)" "Cyan"
        } catch {
            Write-Color "  [!] Failed to create scheduled task: $_" "Red"
        }
        Pause
    }
}
