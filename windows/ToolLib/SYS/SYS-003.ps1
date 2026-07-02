# Tool: SYS-003 — SFC Scan
Register-Tool @{
    ID          = 'SYS-003'
    Name        = 'SFC Scan'
    Category    = 'SYS'
    Description = 'System File Checker — scan and repair protected system files'
    DangerLevel = 'Caution'
    ConfirmMessage = 'May take 10-15 minutes. System files will be repaired if corrupted.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  Running SFC /ScanNow (may take 10-15 min)..." "Cyan"
        $p = Start-Process -FilePath sfc.exe -ArgumentList "/ScanNow" -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -eq 0) { Write-Color "  [+] SFC completed — no violations" "Green" }
        else { Write-Color "  [!] SFC exit code: $($p.ExitCode). Review output above." "Yellow" }
    }
}
