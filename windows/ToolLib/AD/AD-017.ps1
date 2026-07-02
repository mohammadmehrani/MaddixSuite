Register-Tool @{
    ID          = 'AD-017'
    Name        = 'Schema Management'
    Category    = 'AD'
    Description = 'Show AD schema version and register schema snap-in (schmmgmt.msc)'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Display schema version and optionally register the Schema snap-in DLL'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "`n  ─── SCHEMA MANAGEMENT ───" "Cyan"
            $schemaVersion = (Get-ADObject (Get-ADRootDSE).SchemaNamingContext -Property objectVersion).objectVersion
            Write-Color "  Schema Version: $schemaVersion" "White"
            Write-Color "  Forest: $((Get-ADForest).Name)" "Gray"
            Write-Color "  Schema Master: $((Get-ADForest).SchemaMaster)" "Gray"

            $reg = Read-Host "`n  Register Schema Snap-in (schmmgmt.msc)? (Y/N)"
            if ($reg -match '^[Yy]') {
                regsvr32.exe schmmgmt.dll /s
                Write-Color "  [+] Schema snap-in registered. Run: schmmgmt.msc" "Green"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
