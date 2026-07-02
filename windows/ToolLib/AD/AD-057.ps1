Register-Tool @{
    ID          = 'AD-057'
    Name        = 'AD Schema Extensions'
    Category    = 'AD'
    Description = 'Check/import schema extension files'
    DangerLevel = 'Dangerous'
    ConfirmMessage = 'Check AD schema status and import extensions?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $domain = Get-ADDomain
            $forest = Get-ADForest
            $schemaNC = (Get-ADRootDSE).SchemaNamingContext
            Write-Color "`n  ─── AD SCHEMA EXTENSIONS ───" "Cyan"
            Write-Color "  Domain: $($domain.DNSRoot)" "White"
            Write-Color "  Schema NC: $schemaNC" "Gray"
            Write-Color "  Schema Version: $((Get-ADObject $schemaNC -Property objectVersion).objectVersion)" "White"
            Write-Color "  Forest Mode: $($forest.ForestMode)" "Gray"
            $choice = Read-Host "`nChoose: (1) Check schema status (2) Import LDIF extension (3) List schema classes (0) Exit"
            switch ($choice) {
                "1" {
                    Write-Color "`n  ─── Schema Status ───" "Cyan"
                    $schemaObj = Get-ADObject $schemaNC -Properties objectVersion,schemaUpdateAllowed
                    Write-Color "  Schema Version: $($schemaObj.objectVersion)" "White"
                    Write-Color "  Schema Update Allowed: $($schemaObj.schemaUpdateAllowed)" "White"
                    Write-Color "`n  ─── Known Schema Versions ───" "Cyan"
                    $knownVersions = @(
                        @{Ver=13; OS="Windows 2000"},
                        @{Ver=30; OS="Windows Server 2003"},
                        @{Ver=31; OS="Windows Server 2003 R2"},
                        @{Ver=44; OS="Windows Server 2008"},
                        @{Ver=47; OS="Windows Server 2008 R2"},
                        @{Ver=56; OS="Windows Server 2012"},
                        @{Ver=69; OS="Windows Server 2012 R2"},
                        @{Ver=87; OS="Windows Server 2016"},
                        @{Ver=88; OS="Windows Server 2019"},
                        @{Ver=89; OS="Windows Server 2022"}
                    )
                    foreach ($kv in $knownVersions) {
                        $mark = if ($kv.Ver -eq $schemaObj.objectVersion) { " <-- CURRENT" } else { "" }
                        Write-Color "  v$($kv.Ver): $($kv.OS)$mark" "Gray"
                    }
                    Write-Color "`n  ─── Schema Update History ───" "Cyan"
                    try {
                        $updates = Get-ADObject -SearchBase $schemaNC -Filter "ObjectClass -eq 'attributeSchema' -or ObjectClass -eq 'classSchema'" -Properties WhenChanged,Name -ResultPageSize 1000 | Sort-Object WhenChanged -Descending | Select-Object -First 20
                        Write-Color "  Last 20 schema changes:" "Gray"
                        $updates | Select-Object Name,WhenChanged | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Color $_ "Gray" }
                    } catch { Write-Color "  [!] Could not retrieve schema history" "Yellow" }
                    Write-Color "`n  ─── Schema FSMO ───" "Cyan"
                    Write-Color "  Schema Master: $($forest.SchemaMaster)" "White"
                    Write-Color "`n  [i] To enable schema updates on non-schema-master:" "Gray"
                    Write-Color "  Set-ADObject $schemaNC -Replace @{schemaUpdateAllowed=1}" "Gray"
                }
                "2" {
                    $ldifPath = Read-Host "Enter path to .ldf extension file"
                    if (-not (Test-Path $ldifPath)) {
                        Write-Color "  [!] File not found: $ldifPath" "Red"
                        return
                    }
                    Write-Color "`n  [*] Analyzing LDIF file: $ldifPath" "Cyan"
                    $ldifContent = Get-Content $ldifPath -Raw
                    $ldifLines = $ldifContent -split "`n"
                    $entryCount = ($ldifLines | Select-String "^dn:").Count
                    $changeCount = ($ldifLines | Select-String "^changetype:").Count
                    Write-Color "  [i] Entries: $entryCount | Changes: $changeCount" "Gray"
                    $confirmImport = Read-Host "`nProceed with LDIF import? This modifies the AD schema (y/n)"
                    if ($confirmImport -eq 'y') {
                        $schemaMaster = $forest.SchemaMaster
                        Write-Color "  [*] Importing LDIF on schema master: $schemaMaster ..." "Cyan"
                        $result = & ldifde -i -f $ldifPath -s $schemaMaster -c "CN=Schema,CN=Configuration,DC=X" $schemaNC 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            Write-Color "  [+] LDIF import completed successfully" "Green"
                        } else {
                            Write-Color "  [!] LDIF import may have failed. Check output:" "Red"
                            $result | ForEach-Object { Write-Color "  $_" "Red" }
                        }
                        Write-Color "  [i] Wait for replication before importing related extensions" "Yellow"
                    } else {
                        Write-Color "  [i] Import cancelled" "Yellow"
                    }
                }
                "3" {
                    Write-Color "`n  ─── Schema Classes ───" "Cyan"
                    $search = Read-Host "Search class name (wildcard like *Computer* or *User*)"
                    if ($search) {
                        $classes = Get-ADObject -SearchBase $schemaNC -LDAPFilter "(&(objectClass=classSchema)(cn=$search))" -Properties cn,adminDisplayName,ldapDisplayName,objectClassCategory,subClassOf,systemMayContain,systemMustContain -ResultPageSize 500 -ErrorAction SilentlyContinue
                        if ($classes) {
                            foreach ($c in $classes) {
                                Write-Color "`n  Class: $($c.cn)" "Green"
                                Write-Color "  LDAP Name: $($c.ldapDisplayName)" "Gray"
                                Write-Color "  Parent Class: $($c.subClassOf)" "Gray"
                                Write-Color "  Category: $($c.objectClassCategory)" "Gray"
                                $mayContain = if ($c.systemMayContain) { ($c.systemMayContain -join ', ').Substring(0,[Math]::Min(200,($c.systemMayContain -join ', ').Length)) } else { "" }
                                $mustContain = if ($c.systemMustContain) { ($c.systemMustContain -join ', ').Substring(0,[Math]::Min(200,($c.systemMustContain -join ', ').Length)) } else { "" }
                                if ($mayContain) { Write-Color "  May Contain: $mayContain..." "Gray" }
                                if ($mustContain) { Write-Color "  Must Contain: $mustContain..." "Gray" }
                            }
                        } else {
                            Write-Color "  [i] No classes found matching '$search'" "Yellow"
                        }
                    } else {
                        $totalClasses = (Get-ADObject -SearchBase $schemaNC -LDAPFilter "(objectClass=classSchema)" -ResultPageSize 1000).Count
                        $totalAttribs = (Get-ADObject -SearchBase $schemaNC -LDAPFilter "(objectClass=attributeSchema)" -ResultPageSize 1000).Count
                        Write-Color "  [i] Total schema classes: $totalClasses" "White"
                        Write-Color "  [i] Total schema attributes: $totalAttribs" "White"
                    }
                }
                default { Write-Color "  [i] Exiting" "Gray" }
            }
        } catch {
            Write-Color "  [!] AD Schema Extensions check failed: $_" "Red"
        }
        Pause
    }
}
