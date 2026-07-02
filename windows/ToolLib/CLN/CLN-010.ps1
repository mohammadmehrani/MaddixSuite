Register-Tool @{
    ID          = 'CLN-010'
    Name        = 'Disk Cleanup (CleanMgr)'
    Category    = 'CLN'
    Description = 'Run Windows Disk Cleanup utility'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Launch Windows Disk Cleanup utility'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [?] Select Disk Cleanup Mode:" "Yellow"
            Write-Color "      1 - Standard (interactive)" "Cyan"
            Write-Color "      2 - Deep Clean (run as administrator, system files)" "Cyan"
            Write-Color "      3 - Automatic (clean all with low free space)" "Cyan"
            $mode = Read-Host "  [+] Enter choice (1-3)"

            switch ($mode) {
                "1" {
                    Write-Color "  [+] Launching Disk Cleanup..." "Green"
                    Start-Process -FilePath 'cleanmgr.exe' -ArgumentList '/D C' -Wait
                }
                "2" {
                    Write-Color "  [+] Launching Disk Cleanup with system file cleanup..." "Green"
                    Start-Process -FilePath 'cleanmgr.exe' -ArgumentList '/sageset:1' -Wait
                    Write-Color "  [+] Now running the saved settings..." "Yellow"
                    Start-Process -FilePath 'cleanmgr.exe' -ArgumentList '/sagerun:1' -Wait
                }
                "3" {
                    Write-Color "  [+] Running automated low-space cleanup..." "Yellow"
                    Start-Process -FilePath 'cleanmgr.exe' -ArgumentList '/verylowdisk' -Wait
                }
                default {
                    Write-Color "  [+] Launching Disk Cleanup (default)..." "Green"
                    Start-Process -FilePath 'cleanmgr.exe' -Wait
                }
            }
            Write-Color "  [+] Disk Cleanup completed" "Green"
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
