Register-Tool @{
    ID          = 'BAK-002'
    Name        = 'Registry Backup'
    Category    = 'BAK'
    Description = 'Export all registry hives to .reg files'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Export all registry hives to .reg files?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $backupDir = "C:\RegistryBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Write-Color "  [+] Exporting to $backupDir" "Cyan"

            $hives = @(
                @{Path='HKLM\SAM'; File='SAM.reg'},
                @{Path='HKLM\SECURITY'; File='SECURITY.reg'},
                @{Path='HKLM\SYSTEM'; File='SYSTEM.reg'},
                @{Path='HKLM\SOFTWARE'; File='SOFTWARE.reg'},
                @{Path='HKLM\HARDWARE'; File='HARDWARE.reg'},
                @{Path='HKCU'; File='HKCU.reg'},
                @{Path='HKLM\BCD00000000'; File='BCD.reg'},
                @{Path='HKU\.DEFAULT'; File='DEFAULT_USER.reg'}
            )

            foreach ($hive in $hives) {
                $outFile = Join-Path $backupDir $hive.File
                Write-Color "  [+] Exporting $($hive.Path)..." "Gray"
                reg export $hive.Path $outFile /y 2>$null
                if ((Get-Item $outFile -ErrorAction SilentlyContinue).Length -gt 0) {
                    Write-Color "      -> $($hive.File) saved" "Green"
                } else {
                    Write-Color "      -> $($hive.File) empty or inaccessible" "Yellow"
                }
            }

            Write-Color "  [+] Registry backup complete at $backupDir" "Green"
        } catch {
            Write-Color "  [!] Registry backup failed: $_" "Red"
        }
        Pause
    }
}
