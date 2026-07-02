Register-Tool @{
    ID          = 'SYS-007'
    Name        = 'Process Explorer'
    Category    = 'SYS'
    Description = 'List all running processes with CPU, RAM, and details'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only. Displays all running processes with resource usage.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  Top 20 processes by CPU usage:" "Cyan"
        Get-Process | Sort-Object CPU -Descending | Select-Object -First 20 | Format-Table Name, Id, CPU, WorkingSet, StartTime -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
        Write-Color "`n  Top 10 processes by Memory:" "Cyan"
        Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 | Format-Table Name, Id, WorkingSet, PM, Handles -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
        Write-Color "`n  Total processes: $(Get-Process).Count" "White"
        Write-Color "  Total threads: $((Get-Process | Measure-Object Threads -Sum).Sum)" "Gray"
        Write-Color "  Total handles: $((Get-Process | Measure-Object Handles -Sum).Sum)" "Gray"
    }
}
