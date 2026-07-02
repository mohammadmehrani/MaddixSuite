Register-Tool @{
    ID          = 'CLN-007'
    Name        = 'Prefetch Analyzer'
    Category    = 'CLN'
    Description = 'View and clean prefetch files'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Analyze and optionally clean Windows Prefetch files'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $pfPath = "$env:WINDIR\Prefetch"
            if (-not (Test-Path $pfPath)) {
                Write-Color "  [!] Prefetch folder not found" "Red"
                Pause
                return
            }

            $pfFiles = Get-ChildItem -Path $pfPath -Force -ErrorAction SilentlyContinue
            $pfCount = ($pfFiles | Where-Object { -not $_.PSIsContainer }).Count
            $pfSize = ($pfFiles | Where-Object { -not $_.PSIsContainer } | Measure-Object -Property Length -Sum).Sum

            Write-Color "  [+] Prefetch Statistics:" "Green"
            Write-Color "    Total files : $pfCount" "Cyan"
            Write-Color "    Total size  : $([math]::Round($pfSize/1MB,2)) MB" "Cyan"

            Write-Color "`n  [+] Top 20 Most Frequent Applications:" "Yellow"
            $pfFiles | Where-Object { -not $_.PSIsContainer } | Group-Object { $_.Name -replace '-.*','' } |
                Sort-Object Count -Descending | Select-Object Count, Name -First 20 |
                Format-Table -AutoSize

            Write-Color "`n  [+] Largest Prefetch Files:" "Yellow"
            $pfFiles | Where-Object { -not $_.PSIsContainer } | Sort-Object Length -Descending |
                Select-Object Name, @{N='SizeKB';E={[math]::Round($_.Length/1KB,1)}},
                @{N='LastRun';E={$_.LastWriteTime}} -First 15 | Format-Table -AutoSize

            $clean = Read-Host "`n  [+] Clean all prefetch files? (y/N)"
            if ($clean -eq 'y') {
                Remove-Item -Path "$pfPath\*" -Force -ErrorAction SilentlyContinue
                Write-Color "  [+] Prefetch cleaned" "Green"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
