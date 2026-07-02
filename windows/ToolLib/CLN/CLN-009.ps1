Register-Tool @{
    ID          = 'CLN-009'
    Name        = 'Run All Cleaners'
    Category    = 'CLN'
    Description = 'Run CLN-001 through CLN-008 sequentially'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Run all 8 cleaning tools sequentially'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $toolDir = $PSScriptRoot
            $cleaners = 1..8 | ForEach-Object { "{0:D3}" -f $_ }
            Write-Color "  [+] Running all cleaners sequentially..." "Green"
            Write-Color "  [!] Note: Each tool may prompt for confirmation" "Yellow"

            foreach ($num in $cleaners) {
                $file = Join-Path $toolDir "CLN-$num.ps1"
                if (Test-Path $file) {
                    Write-Color "`n  ===== Running CLN-$num =====" "Magenta"
                    try {
                        & $file
                    } catch {
                        Write-Color "  [!] CLN-$num failed: $_" "Red"
                    }
                } else {
                    Write-Color "  [!] CLN-$num.ps1 not found at $file" "Red"
                }
            }

            Write-Color "`n  [+] All cleaners completed" "Green"
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
