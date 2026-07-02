Register-Tool @{
    ID          = 'SYS-012'
    Name        = 'Event Log Viewer'
    Category    = 'SYS'
    Description = 'View Critical/Error events from System, Application, Security logs'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only. Displays recent critical system events.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        $log = Read-Host "  Log name (System/Application/Security) [System]"
        if (-not $log) { $log = "System" }
        $count = Read-Host "  Number of events [20]"
        if (-not $count -or $count -notmatch '^\d+$') { $count = 20 }
        try {
            $events = Get-WinEvent -LogName $log -MaxEvents $count -ErrorAction Stop
            Write-Color "  Last $count events from $log :" "Cyan"
            $events | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message | Format-Table -AutoSize -Wrap | Out-String -Width 200 | ForEach-Object { Write-Color $_ "Gray" }
        } catch {
            Write-Color "  [!] Failed to read $log log: $_" "Red"
            Write-Color "  Try running as Administrator." "Yellow"
        }
        Pause
    }
}
