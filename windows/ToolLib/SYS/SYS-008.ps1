Register-Tool @{
    ID          = 'SYS-008'
    Name        = 'Services Manager'
    Category    = 'SYS'
    Description = 'List, start, stop, restart, or reconfigure Windows services'
    DangerLevel = 'Caution'
    ConfirmMessage = 'Can start/stop services. Stopping critical services may affect system stability.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── SERVICES MANAGER ───" "Cyan"
        Write-Color "  1. List All Services" "White"
        Write-Color "  2. List Running Services" "White"
        Write-Color "  3. List Stopped Services" "White"
        Write-Color "  4. Restart a Service" "White"
        Write-Color "  5. Stop a Service" "White"
        Write-Color "  6. Start a Service" "White"
        Write-Color "  7. List Failed Services" "White"
        Write-Color "  0. Back" "Red"
        $c = Read-Host "> "
        switch ($c) {
            "1" { Get-Service | Format-Table Name, DisplayName, Status, StartType -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" } }
            "2" { Get-Service | Where-Object Status -eq Running | Format-Table Name, DisplayName, StartType -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" } }
            "3" { Get-Service | Where-Object Status -eq Stopped | Format-Table Name, DisplayName, StartType -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" } }
            "4" { $n = Read-Host "Service Name"; Restart-Service $n -Force; Write-Color "  [+] $n restarted" "Green" }
            "5" { $n = Read-Host "Service Name"; Stop-Service $n -Force; Write-Color "  [+] $n stopped" "Yellow" }
            "6" { $n = Read-Host "Service Name"; Start-Service $n; Write-Color "  [+] $n started" "Green" }
            "7" { Get-Service | Where-Object Status -eq Running | Where-Object StartType -eq Disabled | Format-Table Name, Status, StartType -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" } }
        }
        Pause
    }
}
