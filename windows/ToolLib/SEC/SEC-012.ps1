Register-Tool @{
    ID          = 'SEC-012'
    Name        = 'PowerShell Logging Audit'
    Category    = 'SEC'
    Description = 'Check PowerShell script block/module logging'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Audit PowerShell logging configuration'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] PowerShell Logging Configuration:" "Green"

            Write-Color "`n  [*] Script Block Logging:" "Yellow"
            $sbLogging = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -Name 'EnableScriptBlockLogging' -ErrorAction SilentlyContinue
            if ($sbLogging -and $sbLogging.EnableScriptBlockLogging -eq 1) {
                Write-Color "    Status: Enabled" "Green"
            } else {
                Write-Color "    Status: Disabled" "Red"
            }
            $sbInvoke = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -Name 'EnableScriptBlockInvocationLogging' -ErrorAction SilentlyContinue
            if ($sbInvoke -and $sbInvoke.EnableScriptBlockInvocationLogging -eq 1) {
                Write-Color "    Invocation Logging: Enabled" "Green"
            }

            Write-Color "`n  [*] Module Logging:" "Yellow"
            $modLogging = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging' -Name 'EnableModuleLogging' -ErrorAction SilentlyContinue
            if ($modLogging -and $modLogging.EnableModuleLogging -eq 1) {
                Write-Color "    Status: Enabled" "Green"
                $mods = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames' -ErrorAction SilentlyContinue
                if ($mods) {
                    Write-Color "    Logged Modules:" "Cyan"
                    $mods.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object {
                        Write-Color "      - $($_.Name)" "Cyan"
                    }
                }
            } else {
                Write-Color "    Status: Disabled" "Red"
            }

            Write-Color "`n  [*] Transcription:" "Yellow"
            $trans = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription' -Name 'EnableTranscripting' -ErrorAction SilentlyContinue
            if ($trans -and $trans.EnableTranscripting -eq 1) {
                Write-Color "    Status: Enabled" "Green"
                $transDir = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription' -Name 'OutputDirectory' -ErrorAction SilentlyContinue
                if ($transDir) { Write-Color "    Directory: $($transDir.OutputDirectory)" "Cyan" }
            } else {
                Write-Color "    Status: Disabled" "Red"
            }

            Write-Color "`n  [*] PowerShell Event Log (Channel 4104 - ScriptBlock Logging):" "Yellow"
            $events = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-PowerShell/Operational';ID=4104} -MaxEvents 10 -ErrorAction SilentlyContinue
            if ($events) {
                Write-Color "    Last 10 entries found. Check Event Viewer for details." "Green"
            } else {
                Write-Color "    No entries found - logging may be disabled or empty" "Yellow"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
