Register-Tool @{
    ID          = 'OPT-008'
    Name        = 'Run All Optimizers'
    Category    = 'OPT'
    Description = 'Run OPT-001 through OPT-007 sequentially'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Run all 7 optimization tools sequentially'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $toolDir = $PSScriptRoot
            $optimizers = 1..7 | ForEach-Object { "{0:D3}" -f $_ }
            Write-Color "  [+] Running all optimizers sequentially..." "Green"
            Write-Color "  [!] Each tool may prompt for confirmation" "Yellow"

            foreach ($num in $optimizers) {
                $file = Join-Path $toolDir "OPT-$num.ps1"
                if (Test-Path $file) {
                    Write-Color "`n  ===== Running OPT-$num =====" "Magenta"
                    try {
                        & $file
                    } catch {
                        Write-Color "  [!] OPT-$num failed: $_" "Red"
                    }
                } else {
                    Write-Color "  [!] OPT-$num.ps1 not found at $file" "Red"
                }
            }

            Write-Color "`n  [+] All optimizers completed" "Green"
            Write-Color "  [!] Some changes may require a reboot" "Yellow"
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
