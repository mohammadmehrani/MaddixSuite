Register-Tool @{
    ID          = 'SEC-005'
    Name        = 'Windows Defender Status'
    Category    = 'SEC'
    Description = 'Check/update Defender signatures'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Check Windows Defender status and update signatures'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Windows Defender Status:" "Green"
            $mp = Get-MpComputerStatus
            Write-Color "    AM Engine Version    : $($mp.AMEngineVersion)" "Cyan"
            Write-Color "    AM Product Version   : $($mp.AMProductVersion)" "Cyan"
            Write-Color "    AM Service Enabled   : $($mp.AMServiceEnabled)" "Cyan"
            Write-Color "    Antispyware Enabled  : $($mp.AntispywareEnabled)" "Cyan"
            Write-Color "    Antivirus Enabled    : $($mp.AntivirusEnabled)" "Cyan"
            Write-Color "    Behavior Monitor     : $($mp.BehaviorMonitorEnabled)" "Cyan"
            Write-Color "    Ioav Protection      : $($mp.IoavProtectionEnabled)" "Cyan"
            Write-Color "    NIS Enabled          : $($mp.NISEnabled)" "Cyan"
            Write-Color "    On Access Protection : $($mp.OnAccessProtectionEnabled)" "Cyan"
            Write-Color "    Real-time Protection : $($mp.RealTimeProtectionEnabled)" "Cyan"
            Write-Color "    Last Quick Scan      : $($mp.QuickScanDateTime)" "Cyan"
            Write-Color "    Last Full Scan       : $($mp.FullScanDateTime)" "Cyan"
            Write-Color "    Signature Version    : $($mp.AntivirusSignatureVersion)" "Cyan"
            Write-Color "    Signature Last Updated: $($mp.AntivirusSignatureLastDateTime)" "Cyan"

            $choice = Read-Host "`n  [+] Update signatures now? (y/N)"
            if ($choice -eq 'y') {
                Write-Color "  [+] Updating signatures..." "Yellow"
                Update-MpSignature
                Write-Color "  [+] Signatures updated" "Green"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
