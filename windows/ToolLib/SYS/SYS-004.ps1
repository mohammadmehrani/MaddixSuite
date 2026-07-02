# Tool: SYS-004 — DISM Repair
Register-Tool @{
    ID          = 'SYS-004'
    Name        = 'DISM Repair'
    Category    = 'SYS'
    Description = 'DISM /RestoreHealth — repair Windows component store'
    DangerLevel = 'Caution'
    ConfirmMessage = 'May take 20 minutes. Repairs component store corruption.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  Running DISM /RestoreHealth..." "Cyan"
        $p = Start-Process -FilePath dism.exe -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -eq 0) { Write-Color "  [+] DISM completed" "Green" }
        else { Write-Color "  [!] DISM exit code: $($p.ExitCode)" "Yellow" }
    }
}
