Register-Tool @{
    ID          = 'AD-053'
    Name        = 'AD Certificate Auto-Enroll'
    Category    = 'AD'
    Description = 'Configure certificate auto-enrollment GPO'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Configure certificate auto-enrollment GPO?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $domain = Get-ADDomain
            Write-Color "`n  ─── AD CERTIFICATE AUTO-ENROLLMENT ───" "Cyan"
            Write-Color "  Domain: $($domain.DNSRoot)" "White"
            Write-Color "`n  ─── Certificate Authority Check ───" "Cyan"
            $caFound = $false
            try {
                $cas = Get-CertificationAuthority -ErrorAction Stop
                foreach ($ca in $cas) {
                    Write-Color "  [✓] CA: $($ca.Name) - $($ca.ComputerName)" "Green"
                    $caFound = $true
                }
            } catch {
                try {
                    $cas = Get-ChildItem -Path "AD:\$((Get-ADRootDSE).ConfigurationNamingContext)\Services\Public Key Services\Certification Authorities" -ErrorAction SilentlyContinue
                    if ($cas) { Write-Color "  [i] CAs detected in AD: $($cas.Count)" "Green"; $caFound = $true }
                } catch {}
            }
            if (-not $caFound) {
                Write-Color "  [!] No Enterprise CA detected in this environment" "Yellow"
                Write-Color "  [i] Certificate auto-enrollment requires an Enterprise CA" "Yellow"
                Write-Color "  [i] Install AD CS: Install-WindowsFeature AD-Certificate -IncludeManagementTools" "Gray"
            }
            Write-Color "`n  ─── Current Auto-Enrollment Policy ───" "Cyan"
            try {
                $gpoResult = Get-GPResultantSetOfPolicy -ComputerName $env:COMPUTERNAME -User $env:USERNAME -ErrorAction Stop
                $enrollPolicy = $gpoResult.Computer.AdministrativeTemplateSettings.PolicySetting | Where-Object { $_.KeyName -like "*Enrollment*" }
                if ($enrollPolicy) {
                    foreach ($ep in $enrollPolicy) { Write-Color "  [i] $($ep.KeyName) = $($ep.Value)" "Gray" }
                } else {
                    Write-Color "  [i] No certificate enrollment policies found in RSoP" "Gray"
                }
            } catch { Write-Color "  [!] Could not query current policy: $_" "Yellow" }
            $choice = Read-Host "`nCreate auto-enrollment GPO? (y/n)"
            if ($choice -eq 'y') {
                $gpoName = "Certificate Auto-Enrollment Policy"
                try {
                    $existing = Get-GPO -Name $gpoName -ErrorAction SilentlyContinue
                    if ($existing) {
                        Write-Color "  [i] GPO '$gpoName' already exists, updating..." "Yellow"
                        $gpo = $existing
                    } else {
                        $gpo = New-GPO -Name $gpoName -Comment "Configured by AD-053 Certificate Auto-Enroll tool" -ErrorAction Stop
                        Write-Color "  [✓] Created GPO: $gpoName" "Green"
                    }
                    $gpoId = $gpo.Id
                    $regPath = "SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment"
                    $enabledParams = @{
                        "AUOptions" = 3
                        "AUExtraOptions" = 0
                    }
                    foreach ($param in $enabledParams.GetEnumerator()) {
                        Set-GPRegistryValue -Name $gpoName -Key "HKLM\$regPath" -ValueName $param.Key -Type DWord -Value $param.Value -ErrorAction Stop | Out-Null
                    }
                    Write-Color "  [✓] Registry policy written for auto-enrollment" "Green"
                    $domainOU = Get-ADDomain | Select-Object -ExpandProperty DistinguishedName
                    $existingLink = Get-GPO -Name $gpoName | Get-GPLink -All -ErrorAction SilentlyContinue | Where-Object { $_.Target -like "*$domainOU*" }
                    if (-not $existingLink) {
                        New-GPLink -Name $gpoName -Target $domainOU -LinkEnabled Yes -Enforced No -ErrorAction Stop | Out-Null
                        Write-Color "  [✓] GPO linked to domain root: $domainOU" "Green"
                    } else {
                        Write-Color "  [i] GPO already linked to domain" "Gray"
                    }
                    Write-Color "`n  ─── GPO Settings Applied ───" "Cyan"
                    Write-Color "  Certificate Services Client - Auto-Enrollment" "White"
                    Write-Color "  Enrollment Policy: Enabled (Renew expired, update pending, remove revoked)" "Gray"
                    Write-Color "  GPO Name: $gpoName" "Green"
                    Write-Color "`n  [i] To verify: gpupdate /force && certlm.msc" "Cyan"
                } catch {
                    Write-Color "  [!] GPO creation failed: $_" "Red"
                    Write-Color "  [i] You may need Enterprise Admin rights to create/link GPOs" "Yellow"
                }
            }
            Write-Color "`n  ─── Certificate Template Auto-Enroll Steps ───" "Cyan"
            Write-Color "  1. Open Certification Authority MMC (certsrv.msc)" "White"
            Write-Color "  2. Right-click 'Certificate Templates' > Manage" "White"
            Write-Color "  3. Right-click a template > Properties > Security tab" "White"
            Write-Color "  4. Add 'Domain Computers' with 'Read' and 'Autoenroll' permissions" "White"
            Write-Color "  5. The GPO created above will handle the client-side auto-enrollment" "White"
        } catch {
            Write-Color "  [!] AD Certificate Auto-Enroll failed: $_" "Red"
        }
        Pause
    }
}
