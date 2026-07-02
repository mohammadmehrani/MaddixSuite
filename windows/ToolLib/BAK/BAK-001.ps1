Register-Tool @{
    ID          = 'BAK-001'
    Name        = 'System State Backup'
    Category    = 'BAK'
    Description = 'Backup registry, drivers, BCD, tasks, network config'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Create a full system state backup?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $backupDir = "C:\SystemStateBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Write-Color "  [+] Backup target: $backupDir" "Cyan"

            $regDir = Join-Path $backupDir "Registry"
            New-Item -ItemType Directory -Path $regDir -Force | Out-Null
            reg export HKLM\SAM (Join-Path $regDir "SAM.reg") /y 2>$null
            reg export HKLM\SECURITY (Join-Path $regDir "SECURITY.reg") /y 2>$null
            reg export HKLM\SYSTEM (Join-Path $regDir "SYSTEM.reg") /y 2>$null
            reg export HKLM\SOFTWARE (Join-Path $regDir "SOFTWARE.reg") /y 2>$null
            reg export HKCU\Software (Join-Path $regDir "CurrentUser.reg") /y 2>$null
            Write-Color "  [+] Registry exported" "Green"

            $drvDir = Join-Path $backupDir "Drivers"
            New-Item -ItemType Directory -Path $drvDir -Force | Out-Null
            dism /online /export-driver /destination:$drvDir | Out-Null
            Write-Color "  [+] Drivers exported" "Green"

            $bcdDir = Join-Path $backupDir "BCD"
            New-Item -ItemType Directory -Path $bcdDir -Force | Out-Null
            bcdedit /enum all | Out-File (Join-Path $bcdDir "bcdedit.txt") -Encoding ascii
            Write-Color "  [+] BCD data saved" "Green"

            $tasksDir = Join-Path $backupDir "ScheduledTasks"
            New-Item -ItemType Directory -Path $tasksDir -Force | Out-Null
            schtasks /query /fo CSV /v | Out-File (Join-Path $tasksDir "tasks.csv") -Encoding ascii
            Write-Color "  [+] Scheduled tasks exported" "Green"

            $netDir = Join-Path $backupDir "Network"
            New-Item -ItemType Directory -Path $netDir -Force | Out-Null
            netsh interface show config | Out-File (Join-Path $netDir "interface_config.txt") -Encoding ascii
            netsh advfirewall export (Join-Path $netDir "firewall_policy.wfw") | Out-Null
            Get-DnsClientServerAddress | Export-Clixml (Join-Path $netDir "dns_config.xml")
            Write-Color "  [+] Network config backed up" "Green"

            Write-Color "  [+] System state backup complete at $backupDir" "Green"
        } catch {
            Write-Color "  [!] Backup failed: $_" "Red"
        }
        Pause
    }
}
