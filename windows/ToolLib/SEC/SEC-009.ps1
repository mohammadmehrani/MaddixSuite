Register-Tool @{
    ID          = 'SEC-009'
    Name        = 'BitLocker Status'
    Category    = 'SEC'
    Description = 'Check BitLocker encryption status on all drives'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Check BitLocker encryption status on all drives'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] BitLocker Encryption Status:" "Green"
            $volumes = Get-BitLockerVolume -ErrorAction SilentlyContinue
            if (-not $volumes) {
                Write-Color "    No BitLocker volumes found or BitLocker not available" "Yellow"
            } else {
                $volumes | ForEach-Object {
                    $status = $_.ProtectionStatus
                    $statusStr = if ($status -eq 1) { "ON" } elseif ($status -eq 2) { "ON (Suspended)" } else { "OFF" }
                    $perc = if ($_.EncryptionPercentage) { "$($_.EncryptionPercentage)%" } else { "N/A" }
                    $method = if ($_.EncryptionMethod) { $_.EncryptionMethod } else { "None" }
                    Write-Color "    Drive $($_.DriveLetter) : " -NoNewline
                    if ($status -eq 1) { Write-Color "Protected" "Green" } else { Write-Color "Not Protected" "Red" }
                    Write-Color "      Mount Point : $($_.MountPoint)" "Cyan"
                    Write-Color "      Encryption  : $perc ($method)" "Cyan"
                    Write-Color "      Protection  : $statusStr" "Cyan"
                    Write-Color "      Key Protectors: $($_.KeyProtector.Count)" "Cyan"
                    Write-Color "" "Cyan"
                }
            }

            Write-Color "  [+] Fixed Drives Overview:" "Green"
            Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {
                $bl = Get-BitLockerVolume -MountPoint "$($_.DeviceID)" -ErrorAction SilentlyContinue
                $enc = if ($bl -and $bl.ProtectionStatus -eq 1) { "Encrypted" } else { "Not Encrypted" }
                $encColor = if ($bl -and $bl.ProtectionStatus -eq 1) { "Green" } else { "Red" }
                Write-Color "    $($_.DeviceID) ($($_.Size/1GB -as [int]) GB) : " -NoNewline
                Write-Color "$enc" $encColor
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
