Register-Tool @{
    ID          = 'SEC-011'
    Name        = 'Credential Guard Check'
    Category    = 'SEC'
    Description = 'Check if Credential Guard / VBS is enabled'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Check Virtualization-Based Security and Credential Guard status'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Virtualization-Based Security (VBS) Status:" "Green"

            $vbs = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue
            if ($vbs) {
                $vbsStatus = switch ($vbs.VirtualizationBasedSecurityStatus) {
                    0 { "Disabled" }
                    1 { "Enabled without UEFI lock" }
                    2 { "Enabled with UEFI lock" }
                    default { "Unknown ($($vbs.VirtualizationBasedSecurityStatus))" }
                }
                Write-Color "    VBS Status  : $vbsStatus" "Cyan"

                $credGuard = switch ($vbs.CredentialGuardSecurityLevel) {
                    0 { "Disabled" }
                    1 { "Enabled (UEFI lock)" }
                    2 { "Enabled (without lock)" }
                    default { "Unknown ($($vbs.CredentialGuardSecurityLevel))" }
                }
                Write-Color "    Cred Guard  : $credGuard" "Cyan"
                Write-Color "    Secure Boot : $($vbs.SecureBootConfigured)" "Cyan"
                Write-Color "    TPM Present : $($vbs.TpmConfigured)" "Cyan"

                $required = switch ($vbs.RequiredSecurityProperties) { 0 { "None" } 1 { "Secure Boot" } 2 { "DMA Protection" } 3 { "Secure Boot + DMA" } default { "Unknown" } }
                Write-Color "    Required Sec: $required" "Cyan"
            } else {
                Write-Color "    VBS info not available (might need admin or unsupported SKU)" "Yellow"
            }

            Write-Color "`n  [+] Checking via Registry:" "Green"
            $regPaths = @(
                @{Path='HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard';Name='Enabled';Desc='Credential Guard'},
                @{Path='HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard';Name='EnableVirtualizationBasedSecurity';Desc='VBS'}
            )
            foreach ($entry in $regPaths) {
                if (Test-Path $entry.Path) {
                    $val = Get-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
                    $status = if ($val.($entry.Name) -eq 1) { "Enabled" } else { "Disabled" }
                    Write-Color "    $($entry.Desc) : $status" "Cyan"
                } else {
                    Write-Color "    $($entry.Desc) : Not configured" "Yellow"
                }
            }

            Write-Color "`n  [+] Checking System Guard / Secure Launch:" "Green"
            $sysGuard = Get-CimInstance -ClassName Win32_SystemGuard -Namespace root\Microsoft\Windows\SystemGuard -ErrorAction SilentlyContinue
            if ($sysGuard) {
                Write-Color "    System Guard: Available" "Green"
            } else {
                Write-Color "    System Guard: Not available" "Yellow"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
