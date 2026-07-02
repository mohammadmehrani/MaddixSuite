Register-Tool @{
    ID          = 'SEC-004'
    Name        = 'Service Security Audit'
    Category    = 'SEC'
    Description = 'Check service permissions and insecure services'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Audit Windows services for insecure configurations'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Checking services running as SYSTEM with weak permissions..." "Green"

            $services = Get-WmiObject -Class Win32_Service | Where-Object { $_.StartMode -eq 'Auto' -or $_.StartMode -eq 'Manual' }
            Write-Color "  [+] Total services: $($services.Count)" "Green"

            Write-Color "`n  [+] Services running as LocalSystem:" "Yellow"
            $sysSvc = $services | Where-Object { $_.StartName -eq 'LocalSystem' }
            $sysSvc | Select-Object Name, DisplayName, State, StartMode | Format-Table -AutoSize

            Write-Color "`n  [+] Services that can be stopped by users (checking via SDDL)..." "Yellow"
            $insecure = @()
            foreach ($svc in $services) {
                try {
                    $sd = sc.exe sdshow $svc.Name 2>$null
                    if ($sd -match 'AU') {
                        $insecure += $svc
                    }
                } catch {}
            }
            if ($insecure) {
                Write-Color "    Found $($insecure.Count) services with potential weak permissions" "Red"
                $insecure | Select-Object -First 20 Name, DisplayName | Format-Table -AutoSize
            } else {
                Write-Color "    No obviously weak service permissions detected" "Green"
            }

            Write-Color "`n  [+] Stopped but Auto-start services:" "Yellow"
            $stoppedAuto = $services | Where-Object { $_.State -ne 'Running' -and $_.StartMode -eq 'Auto' }
            if ($stoppedAuto) {
                $stoppedAuto | Select-Object Name, DisplayName | Format-Table -AutoSize
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
