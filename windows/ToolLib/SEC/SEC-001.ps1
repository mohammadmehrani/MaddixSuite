Register-Tool @{
    ID          = 'SEC-001'
    Name        = 'Windows Defender Scanner'
    Category    = 'SEC'
    Description = 'Run Defender quick/full/custom scan'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Run a Windows Defender antivirus scan'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [?] Select scan type:" "Yellow"
            Write-Color "      1 - Quick Scan" "Cyan"
            Write-Color "      2 - Full Scan" "Cyan"
            Write-Color "      3 - Custom Scan (ask for path)" "Cyan"
            $choice = Read-Host "  [+] Enter choice (1-3)"
            switch ($choice) {
                "1" {
                    Write-Color "  [+] Starting Quick Scan..." "Green"
                    Start-MpScan -ScanType QuickScan -AsJob
                    Write-Color "  [+] Quick Scan launched in background" "Green"
                }
                "2" {
                    Write-Color "  [+] Starting Full Scan (this may take hours)..." "Yellow"
                    Start-MpScan -ScanType FullScan -AsJob
                    Write-Color "  [+] Full Scan launched in background" "Green"
                }
                "3" {
                    $path = Read-Host "  [+] Enter path to scan"
                    if (Test-Path -LiteralPath $path) {
                        Start-MpScan -ScanType CustomScan -ScanPath $path -AsJob
                        Write-Color "  [+] Custom Scan launched on $path" "Green"
                    } else {
                        Write-Color "  [!] Path not found" "Red"
                    }
                }
                default { Write-Color "  [!] Invalid choice" "Red" }
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
