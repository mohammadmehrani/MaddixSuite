Register-Tool @{
    ID          = 'SEC-015'
    Name        = 'Local Group Policy Check'
    Category    = 'SEC'
    Description = 'View important security policies'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Review important local security policies'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Important Local Security Policies:" "Green"

            Write-Color "`n  [*] Password Policy:" "Yellow"
            $pwDir = 'cmd /c net accounts 2>&1'
            $result = Invoke-Expression $pwDir
            $result | ForEach-Object { Write-Color "    $_" "Cyan" }

            Write-Color "`n  [*] Audit Policy:" "Yellow"
            $auditDir = 'HKLM:\SECURITY\Policy\PolAdtEv'
            $audit = Get-ItemProperty -Path $auditDir -ErrorAction SilentlyContinue
            try {
                $auditPol = auditpol /get /category:* 2>$null
                if ($auditPol) { $auditPol | ForEach-Object { Write-Color "    $_" "Cyan" } }
            } catch { Write-Color "    AuditPol not available" "Yellow" }

            Write-Color "`n  [*] User Rights Assignments:" "Yellow"
            $seced = secedit /export /cfg "$env:TEMP\secpol.cfg" /quiet 2>$null
            if (Test-Path "$env:TEMP\secpol.cfg") {
                $secContent = Get-Content "$env:TEMP\secpol.cfg"
                $rights = @(
                    'SeNetworkLogonRight', 'SeRemoteInteractiveLogonRight',
                    'SeShutdownPrivilege', 'SeServiceLogonRight',
                    'SeDenyNetworkLogonRight', 'SeDenyRemoteInteractiveLogonRight',
                    'SeTakeOwnershipPrivilege', 'SeDebugPrivilege'
                )
                foreach ($right in $rights) {
                    $line = $secContent | Select-String "^$right"
                    if ($line) {
                        Write-Color "    $right = $($line.ToString().Split('=')[1].Trim())" "Cyan"
                    }
                }
                Remove-Item "$env:TEMP\secpol.cfg" -Force -ErrorAction SilentlyContinue
            }

            Write-Color "`n  [*] Restricted Groups:" "Yellow"
            $adminMembers = net localgroup Administrators 2>$null
            $adminMembers | Select-Object -Skip 4 | ForEach-Object {
                if ($_ -and $_ -notmatch 'command completed') {
                    Write-Color "    Admin: $_" "Cyan"
                }
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
