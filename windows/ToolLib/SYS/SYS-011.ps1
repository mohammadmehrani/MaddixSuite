Register-Tool @{
    ID          = 'SYS-011'
    Name        = 'USB Device Manager'
    Category    = 'SYS'
    Description = 'List USB devices, disable/enable ports, view USB history'
    DangerLevel = 'Caution'
    ConfirmMessage = 'Can disable USB ports. Will require reboot to re-enable.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── USB DEVICE MANAGER ───" "Cyan"
        Write-Color "  1. List USB Devices" "White"
        Write-Color "  2. USB History (SetupAPI)" "White"
        Write-Color "  3. Disable USB Storage (registry)" "White"
        Write-Color "  4. Enable USB Storage (registry)" "White"
        Write-Color "  0. Back" "Red"
        $c = Read-Host "> "
        switch ($c) {
            "1" { Get-CimInstance Win32_USBControllerDevice | ForEach-Object { $_.Dependent } | Select-Object Name, DeviceID, Status | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" } }
            "2" { Get-WinEvent -LogName SetupAPI -MaxEvents 20 -ErrorAction SilentlyContinue | Where-Object { $_.Message -match "USB" } | Format-Table TimeCreated, Id, LevelDisplayName -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" } }
            "3" { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR" -Name Start -Value 4 -Type DWord -Force; Write-Color "  [+] USB storage disabled (reboot required)" "Yellow" }
            "4" { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR" -Name Start -Value 3 -Type DWord -Force; Write-Color "  [+] USB storage enabled" "Green" }
        }
        Pause
    }
}
