Register-Tool @{
    ID          = 'BAK-009'
    Name        = 'Driver Backup'
    Category    = 'BAK'
    Description = 'Export all installed drivers to a folder'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Export all installed drivers to a backup folder?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $backupDir = "C:\DriverBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Write-Color "  [+] Exporting drivers to $backupDir" "Cyan"

            $driverCount = (Get-WindowsDriver -Online -ErrorAction SilentlyContinue | Measure-Object).Count
            Write-Color "  [+] Found $driverCount installed drivers" "Gray"

            $result = dism /online /export-driver /destination:$backupDir
            $exported = (Get-ChildItem $backupDir -Filter "*.inf" -Recurse | Measure-Object).Count
            $size = (Get-ChildItem $backupDir -Recurse -File | Measure-Object -Property Length -Sum).Sum
            $sizeMB = [math]::Round($size / 1MB, 2)

            if ($exported -gt 0) {
                Write-Color "  [+] Exported $exported driver packages ($sizeMB MB)" "Green"

                $reportPath = Join-Path $backupDir "driver_manifest.txt"
                Get-WindowsDriver -Online -ErrorAction SilentlyContinue |
                    Select-Object Driver, OriginalFileName, BootCritical,
                        @{N='ClassName';E={$_.ClassName -join ';'}} |
                    Format-Table -AutoSize | Out-File $reportPath -Encoding ascii
                Write-Color "  [+] Driver manifest saved" "Green"
            } else {
                Write-Color "  [!] No drivers exported - run as Administrator" "Yellow"
            }
        } catch {
            Write-Color "  [!] Driver backup failed: $_" "Red"
        }
        Pause
    }
}
