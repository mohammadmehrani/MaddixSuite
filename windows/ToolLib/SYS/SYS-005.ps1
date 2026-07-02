# Tool: SYS-005 — CHKDSK
Register-Tool @{
    ID          = 'SYS-005'
    Name        = 'CHKDSK'
    Category    = 'SYS'
    Description = 'Check disk for file system errors and bad sectors'
    DangerLevel = 'Caution'
    ConfirmMessage = 'May schedule on next reboot. Scans for file system errors.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  Running CHKDSK C: (read-only scan first)..." "Cyan"
        chkdskscan = chkdsk C: 2>&1
        $chkdskscan -split "`n" | ForEach-Object { Write-Color "    $_" "Gray" }
        Write-Color "`n  Schedule CHKDSK with repair on next boot?" "Yellow"
        if ((Read-Host " (Y/N)") -eq 'y') {
            chkdsk C: /f /r | Out-Null
            Write-Color "  CHKDSK scheduled on next reboot" "Green"
            $script:PendingReboot = $true
        }
    }
}
