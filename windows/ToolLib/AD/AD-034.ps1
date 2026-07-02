Register-Tool @{
    ID          = 'AD-034'
    Name        = 'Group Policy Results (RSOP)'
    Category    = 'AD'
    Description = 'Generate Group Policy Resultant Set of Policy (RSOP) HTML report'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Generate RSOP HTML report for the local machine?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Generating RSOP report..." "Cyan"
            $reportPath = "$env:TEMP\MaddixSuite_RSOP_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
            Get-GPResultantSetOfPolicy -ReportType Html -Path $reportPath -ErrorAction Stop
            Write-Color "  [+] RSOP report generated" "Green"
            Write-Color "  [i] Report: $reportPath" "Cyan"
            $choice = Read-Host "  [?] Open report now? (y/N)"
            if ($choice -eq 'y') {
                Start-Process $reportPath
            }
        } catch {
            Write-Color "  [!] RSOP generation failed: $_" "Red"
        }
        Pause
    }
}
