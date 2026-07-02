Register-Tool @{
    ID          = 'AD-035'
    Name        = 'AD Health Check (dcdiag)'
    Category    = 'AD'
    Description = 'Run dcdiag /v /c /e for comprehensive AD health check'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Run comprehensive dcdiag health check?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Running AD Health Check (dcdiag)..." "Cyan"
            $output = dcdiag /v /c /e 2>&1
            $output | ForEach-Object { Write-Host $_ }

            $issues = $output | Select-String -Pattern "failed|error|warning" -CaseSensitive:$false
            if ($issues) {
                Write-Color "`n  [!] Issues found:" "Yellow"
                $issues | ForEach-Object { Write-Color "    $_" "Yellow" }
            } else {
                Write-Color "`n  [+] All tests passed" "Green"
            }
        } catch {
            Write-Color "  [!] dcdiag failed: $_" "Red"
        }
        Pause
    }
}
