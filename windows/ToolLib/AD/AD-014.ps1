Register-Tool @{
    ID          = 'AD-014'
    Name        = 'AD Replication Status'
    Category    = 'AD'
    Description = 'Check AD replication status and queue using repadmin'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Run repadmin to check AD replication status (read-only)'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "`n  ─── AD REPLICATION STATUS ───" "Cyan"
            repadmin /replsummary
            Write-Color "`n  ─── REPLICATION QUEUE ───" "Cyan"
            repadmin /queue *
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
