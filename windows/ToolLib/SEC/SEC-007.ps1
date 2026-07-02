Register-Tool @{
    ID          = 'SEC-007'
    Name        = 'USB Blocker'
    Category    = 'SEC'
    Description = 'Enable/disable USB storage via registry'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Modify registry to enable or disable USB storage'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [?] Select action:" "Yellow"
            Write-Color "      1 - Disable USB Storage (Block)" "Red"
            Write-Color "      2 - Enable USB Storage (Allow)" "Green"
            $choice = Read-Host "  [+] Enter choice (1-2)"
            $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR'
            if (-not (Test-Path $regPath)) {
                New-Item -Path $regPath -Force | Out-Null
            }
            switch ($choice) {
                "1" {
                    Set-ItemProperty -Path $regPath -Name 'Start' -Value 4 -Type DWord -Force
                    Write-Color "  [+] USB storage disabled (Start=4). Restart to apply." "Green"
                }
                "2" {
                    Set-ItemProperty -Path $regPath -Name 'Start' -Value 3 -Type DWord -Force
                    Write-Color "  [+] USB storage enabled (Start=3). Restart to apply." "Green"
                }
                default { Write-Color "  [!] Invalid choice" "Red" }
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
