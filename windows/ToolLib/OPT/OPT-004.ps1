Register-Tool @{
    ID          = 'OPT-004'
    Name        = 'Startup Manager'
    Category    = 'OPT'
    Description = 'List/disable startup programs and services'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Manage startup programs and services'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Startup Programs:" "Green"
            $startups = Get-CimInstance -ClassName Win32_StartupCommand
            if ($startups) {
                $startups | Select-Object Name, Command, Location, User | Format-Table -AutoSize
            } else {
                Write-Color "    No startup programs found" "Cyan"
            }

            Write-Color "`n  [*] Task Manager Startup Entries:" "Yellow"
            $taskStartups = Get-CimInstance -ClassName MSFT_TaskManagerStartup -Namespace root\standardcimv2 -ErrorAction SilentlyContinue
            if ($taskStartups) {
                $taskStartups | Select-Object Name, Publisher, Status | Sort-Object Status | Format-Table -AutoSize
            }

            Write-Color "`n  [*] Services set to Auto-Start:" "Yellow"
            $autoServices = Get-CimInstance -ClassName Win32_Service | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -eq 'Running' } |
                Sort-Object Name | Select-Object Name, DisplayName, ProcessId
            $autoServices | Format-Table -AutoSize

            $disableChoice = Read-Host "`n  [+] Enter the name of a program/service to disable (blank to skip)"
            if ($disableChoice) {
                $target = $startups | Where-Object { $_.Name -like "*$disableChoice*" }
                if ($target) {
                    $target | ForEach-Object {
                        if ($_.Location -match 'Registry') {
                            $regPath = $_.Location -replace 'registry:', 'HKLM:\'
                            Remove-ItemProperty -Path $regPath -Name $_.Name -ErrorAction SilentlyContinue
                            Write-Color "  [+] Removed $($_.Name) from startup" "Green"
                        }
                    }
                }
                $svcTarget = Get-Service -Name $disableChoice -ErrorAction SilentlyContinue
                if ($svcTarget) {
                    $disableSvc = Read-Host "  [+] Disable service '$disableChoice'? (y/N)"
                    if ($disableSvc -eq 'y') {
                        Stop-Service -Name $disableChoice -Force -ErrorAction SilentlyContinue
                        Set-Service -Name $disableChoice -StartupType Disabled
                        Write-Color "  [+] Service '$disableChoice' disabled" "Green"
                    }
                }
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
