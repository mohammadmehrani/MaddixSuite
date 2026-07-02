Register-Tool @{
    ID          = 'AD-052'
    Name        = 'AD BitLocker Recovery'
    Category    = 'AD'
    Description = 'Query/manage BitLocker recovery passwords in AD'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Query BitLocker recovery passwords from AD?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "`n  ─── AD BITLOCKER RECOVERY ───" "Cyan"
            $options = @(
                "1. List all computers with BitLocker recovery keys",
                "2. Find recovery key for a specific computer",
                "3. Export BitLocker recovery report to CSV",
                "4. Check BitLocker schema extensions",
                "0. Exit"
            )
            $options | ForEach-Object { Write-Color "  $_" "White" }
            $choice = Read-Host "`nSelect option"
            switch ($choice) {
                "1" {
                    Write-Color "`n  [*] Searching AD for BitLocker recovery objects..." "Cyan"
                    $searchBase = "CN=BitLocker Recovery,CN=FDConfiguration,$((Get-ADRootDSE).ConfigurationNamingContext)"
                    $recoveryKeys = Get-ADObject -SearchBase (Get-ADDomain).DomainMode -Filter "ObjectClass -eq 'msFVE-RecoveryInformation'" -Properties msFVE-RecoveryPassword,msFVE-VolumeGuid,DistinguishedName -ErrorAction Stop -ResultPageSize 5000
                    if (-not $recoveryKeys) {
                        try {
                            $recoveryKeys = Get-ADObject -LDAPFilter "(objectClass=msFVE-RecoveryInformation)" -Properties msFVE-RecoveryPassword,msFVE-VolumeGuid,DistinguishedName -ResultPageSize 5000 -ErrorAction Stop
                        } catch {
                            Write-Color "  [!] Alternate search also failed" "Red"
                        }
                    }
                    if ($recoveryKeys -and $recoveryKeys.Count -gt 0) {
                        Write-Color "  [i] Found $($recoveryKeys.Count) recovery keys" "Green"
                        $grouped = $recoveryKeys | Group-Object { ($_.DistinguishedName -split ',')[1..5] -join ',' }
                        foreach ($g in $grouped) {
                            Write-Color "  Computer: $($g.Name)" "White"
                            Write-Color "  Keys: $($g.Count)" "Gray"
                        }
                    } else {
                        Write-Color "  [i] No BitLocker recovery keys found in AD" "Yellow"
                        Write-Color "  [i] This is normal if BitLocker is not configured to back up to AD" "Gray"
                    }
                }
                "2" {
                    $computerName = Read-Host "  Enter computer name"
                    Write-Color "  [*] Searching for $computerName..." "Cyan"
                    $filter = "(&(objectClass=msFVE-RecoveryInformation)(cn=$computerName*))"
                    $keys = Get-ADObject -LDAPFilter $filter -Properties msFVE-RecoveryPassword,msFVE-VolumeGuid,DistinguishedName -ErrorAction Stop
                    if ($keys -and $keys.Count -gt 0) {
                        foreach ($k in $keys) {
                            Write-Color "`n  Volume GUID: $($k.msFVE-VolumeGuid)" "White"
                            Write-Color "  Recovery Password: $($k.'msFVE-RecoveryPassword')" "Green"
                            Write-Color "  DN: $($k.DistinguishedName)" "Gray"
                        }
                    } else {
                        Write-Color "  [!] No keys found for $computerName" "Yellow"
                    }
                }
                "3" {
                    $csvPath = Join-Path $env:TEMP "BitLocker-RecoveryReport-$(Get-Date -Format yyyyMMdd-HHmmss).csv"
                    Write-Color "  [*] Exporting all BitLocker recovery keys..." "Cyan"
                    try {
                        $allKeys = Get-ADObject -LDAPFilter "(objectClass=msFVE-RecoveryInformation)" -Properties msFVE-RecoveryPassword,msFVE-VolumeGuid,DistinguishedName,WhenCreated -ResultPageSize 5000 -ErrorAction Stop
                    } catch {
                        $allKeys = Get-ADObject -SearchBase "CN=BitLocker Recovery,CN=FDConfiguration,$((Get-ADRootDSE).ConfigurationNamingContext)" -Filter "ObjectClass -eq 'msFVE-RecoveryInformation'" -Properties msFVE-RecoveryPassword,msFVE-VolumeGuid,DistinguishedName,WhenCreated -ErrorAction SilentlyContinue
                    }
                    if ($allKeys -and $allKeys.Count -gt 0) {
                        $results = @()
                        foreach ($k in $allKeys) {
                            $dnParts = $k.DistinguishedName -split ','
                            $computerDN = ($dnParts | Where-Object { $_ -like 'CN=*' -and $_ -ne $k.Name } | Select-Object -First 1)
                            $results += [PSCustomObject]@{
                                Computer = $computerDN
                                VolumeGUID = $k.msFVE-VolumeGuid
                                RecoveryPassword = $k.'msFVE-RecoveryPassword'
                                Created = $k.WhenCreated
                                DN = $k.DistinguishedName
                            }
                        }
                        $results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                        Write-Color "  [+] Report saved: $csvPath" "Green"
                        Write-Color "  [i] Total keys: $($results.Count)" "Cyan"
                    } else {
                        Write-Color "  [i] No BitLocker keys found in AD" "Yellow"
                    }
                }
                "4" {
                    Write-Color "`n  ─── BitLocker Schema Check ───" "Cyan"
                    $schemaNC = (Get-ADRootDSE).SchemaNamingContext
                    $bitlockerAttribs = @(
                        "ms-FVE-RecoveryPassword",
                        "ms-FVE-KeyPackage",
                        "ms-FVE-VolumeGuid"
                    )
                    foreach ($attr in $bitlockerAttribs) {
                        try {
                            $obj = Get-ADObject -SearchBase $schemaNC -Filter "Name -eq '$attr'" -ErrorAction SilentlyContinue
                            if ($obj) { Write-Color "  [✓] $attr - present" "Green" } else { Write-Color "  [?] $attr - not found (may not be needed)" "Gray" }
                        } catch { Write-Color "  [!] Could not check $attr" "Yellow" }
                    }
                    $recoveryContainer = Get-ADObject -LDAPFilter "(distinguishedName=CN=BitLocker Recovery,CN=FDConfiguration,$((Get-ADRootDSE).ConfigurationNamingContext))" -ErrorAction SilentlyContinue
                    if ($recoveryContainer) { Write-Color "  [✓] BitLocker Recovery container exists" "Green" } else { Write-Color "  [?] BitLocker Recovery container not found - schema may need extension" "Yellow" }
                    Write-Color "`n  [i] To extend BitLocker schema on Windows Server:" "Cyan"
                    Write-Color "  adprep /forestprep (already run if forest is functional)" "Gray"
                    Write-Color "  [i] BitLocker AD backup requires GPO: Computer > Windows Components > BitLocker > Store BitLocker recovery info in AD" "Gray"
                }
                default { Write-Color "  [i] Exiting" "Gray" }
            }
        } catch {
            Write-Color "  [!] AD BitLocker Recovery failed: $_" "Red"
        }
        Pause
    }
}
