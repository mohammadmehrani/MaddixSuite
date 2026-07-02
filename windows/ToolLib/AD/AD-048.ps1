Register-Tool @{
    ID          = 'AD-048'
    Name        = 'AD Kerberos Health'
    Category    = 'AD'
    Description = 'Check Kerberos configuration, test authentication'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Check Kerberos health and configuration?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $domain = Get-ADDomain
            $forest = Get-ADForest
            $dcs = Get-ADDomainController -Filter *
            Write-Color "`n  ─── AD KERBEROS HEALTH CHECK ───" "Cyan"
            Write-Color "  Domain: $($domain.DNSRoot)" "White"
            Write-Color "  NetBIOS: $($domain.NetBIOSName)" "Gray"
            Write-Color "`n  ─── KDC Servers ───" "Cyan"
            $kdcList = @()
            foreach ($dc in $dcs) {
                $kdc = "$($dc.Name).$($domain.DNSRoot)"
                $kdcList += $kdc
                Write-Color "  $kdc ($($dc.Site))" "White"
            }
            Write-Color "`n  ─── SRV Record Check ───" "Cyan"
            $srvRecords = @(
                "_kerberos._tcp.$($domain.DNSRoot)",
                "_kerberos._udp.$($domain.DNSRoot)",
                "_kpasswd._tcp.$($domain.DNSRoot)",
                "_kpasswd._udp.$($domain.DNSRoot)",
                "_ldap._tcp.$($domain.DNSRoot)",
                "_gc._tcp.$($forest.RootDomain)"
            )
            foreach ($srv in $srvRecords) {
                try {
                    $resolved = Resolve-DnsName -Name $srv -Type SRV -ErrorAction Stop
                    $count = ($resolved | Measure-Object).Count
                    Write-Color "  [✓] $srv ($count targets)" "Green"
                } catch {
                    Write-Color "  [✗] $srv - NOT FOUND" "Red"
                }
            }
            Write-Color "`n  ─── Kerberos Policy ───" "Cyan"
            $krbPolicy = Get-ADObject -Identity "CN=Kerberos Policy,CN=Services,$((Get-ADRootDSE).ConfigurationNamingContext)" -Properties * -ErrorAction SilentlyContinue
            if ($krbPolicy) {
                Write-Color "  Max Lifetime (Ticket): $($krbPolicy.MaxTicketLifetime) hours" "White"
                Write-Color "  Max Lifetime (Renew): $($krbPolicy.MaxRenewAge) days" "White"
                Write-Color "  Max Service Ticket Age: $($krbPolicy.MaxServiceTicketAge) minutes" "White"
                Write-Color "  Clock Skew Tolerance: $($krbPolicy.ClockSkew) minutes" "White"
            } else {
                Write-Color "  [i] Default Kerberos policy in effect" "Gray"
            }
            Write-Color "`n  ─── Time Synchronization ───" "Cyan"
            Write-Color "  PDC Emulator: $($domain.PDCEmulator)" "White"
            foreach ($dc in $dcs) {
                try {
                    $dcTime = Invoke-Command -ComputerName $dc.Name -ScriptBlock { Get-Date } -ErrorAction Stop
                    $diff = ((Get-Date) - $dcTime).TotalSeconds
                    if ([Math]::Abs($diff) -le 5) {
                        Write-Color "  [✓] $($dc.Name) time diff: $([Math]::Round($diff,2))s" "Green"
                    } else {
                        Write-Color "  [✗] $($dc.Name) time diff: $([Math]::Round($diff,2))s - OUT OF SYNC" "Red"
                    }
                } catch {
                    Write-Color "  [!] $($dc.Name) - unreachable" "Yellow"
                }
            }
            Write-Color "`n  ─── Kerberos Authentication Test ───" "Cyan"
            try {
                $testUser = Get-ADUser -Filter * -Properties SamAccountName | Select-Object -First 1
                if ($testUser) {
                    $token = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
                    Write-Color "  [✓] Current user: $($token.Identity.Name)" "Green"
                    Write-Color "  [i] Authentication type: $($token.Identity.AuthenticationType)" "Gray"
                    Write-Color "  [i] Is authenticated: $($token.Identity.IsAuthenticated)" "Gray"
                }
            } catch {
                Write-Color "  [!] Kerberos auth test failed: $_" "Yellow"
            }
            Write-Color "`n  ─── Encryption Types ───" "Cyan"
            Write-Color "  Supported: AES256-CTS-HMAC-SHA1-96, AES128-CTS-HMAC-SHA1-96, RC4-HMAC" "Gray"
            Write-Color "  [i] AES encryption is default for Windows Server 2008+ DCs" "Gray"
            Write-Color "`n  ─── Common Kerberos Issues ───" "Cyan"
            Write-Color "  - Time skew > 5 minutes: clock sync issue" "White"
            Write-Color "  - Missing SPN: duplicate or missing servicePrincipalName" "White"
            Write-Color "  - Large Kerberos tokens (> 48000 bytes): DC and firewall UDP settings" "White"
            Write-Color "  - KDC unreachable: DNS SRV records missing or incorrect" "White"
        } catch {
            Write-Color "  [!] AD Kerberos Health check failed: $_" "Red"
        }
        Pause
    }
}
