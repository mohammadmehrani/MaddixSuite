# Tool: SYS-002 — Create Restore Point
Register-Tool @{
    ID          = 'SYS-002'
    Name        = 'Create Restore Point'
    Category    = 'SYS'
    Description = 'Create a system restore point for rollback'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Safe. Creates a snapshot of system files and registry.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        $desc = "MaddixSuite_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Checkpoint-Computer -Description $desc -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Color "  [+] Restore point created: $desc" "Green"
    }
}
