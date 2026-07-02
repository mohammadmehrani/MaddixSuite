Register-Tool @{
    ID          = 'SEC-006'
    Name        = 'Ransomware Protection Check'
    Category    = 'SEC'
    Description = 'Check Controlled Folder Access, ASR rules'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Check ransomware protection settings'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Controlled Folder Access:" "Green"
            $cfa = Get-MpPreference | Select-Object -ExpandProperty EnableControlledFolderAccess
            if ($cfa -eq 1) {
                Write-Color "    Status: Enabled (Audit Mode)" "Yellow"
            } elseif ($cfa -eq 2) {
                Write-Color "    Status: Enabled (Block Mode)" "Green"
            } else {
                Write-Color "    Status: Disabled" "Red"
            }

            $protectedFolders = Get-MpPreference | Select-Object -ExpandProperty ControlledFolderAccessProtectedFolders
            if ($protectedFolders) {
                Write-Color "    Protected Folders:" "Cyan"
                $protectedFolders | ForEach-Object { Write-Color "      - $_" "Cyan" }
            }

            Write-Color "`n  [+] Attack Surface Reduction (ASR) Rules:" "Green"
            $asr = Get-MpPreference | Select-Object -ExpandProperty AttackSurfaceReductionRules_Ids
            $asrActions = Get-MpPreference | Select-Object -ExpandProperty AttackSurfaceReductionRules_Actions
            if ($asr) {
                for ($i = 0; $i -lt $asr.Count; $i++) {
                    $action = if ($asrActions[$i] -eq 1) { "Block" } elseif ($asrActions[$i] -eq 2) { "Audit" } else { "Off" }
                    Write-Color "    Rule: $($asr[$i]) -> $action" "Cyan"
                }
            } else {
                Write-Color "    No ASR rules configured" "Yellow"
            }

            Write-Color "`n  [+] Network Protection:" "Green"
            $np = Get-MpPreference | Select-Object -ExpandProperty EnableNetworkProtection
            if ($np -eq 1) { Write-Color "    Status: Enabled (Block Mode)" "Green" }
            elseif ($np -eq 2) { Write-Color "    Status: Enabled (Audit Mode)" "Yellow" }
            else { Write-Color "    Status: Disabled" "Red" }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
