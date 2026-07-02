Register-Tool @{
    ID          = 'AD-040'
    Name        = 'Azure AD Connect Prep'
    Category    = 'AD'
    Description = 'Check prerequisites for Azure AD Connect installation'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Check Azure AD Connect prerequisites?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Azure AD Connect Prerequisites" "Cyan"

            Write-Color "`n  ─── Prerequisites Check ───" "Cyan"

            $schemaObj = Get-ADObject (Get-ADRootDSE).SchemaNamingContext -Property objectVersion -ErrorAction SilentlyContinue
            $schemaVersion = if ($schemaObj) { $schemaObj.objectVersion } else { "Unknown" }
            Write-Color "  [i] AD Schema Version: $schemaVersion" "Gray"
            if ($schemaVersion -ge 88) {
                Write-Color "  [✓] Schema version >= 88 (required for Azure AD Connect)" "Green"
            } else {
                Write-Color "  [✗] Schema version too low. Upgrade the forest." "Red"
            }

            $forestMode = (Get-ADForest -ErrorAction SilentlyContinue).ForestMode
            Write-Color "  [i] Forest Mode: $forestMode" "Gray"

            $recycleBin = (Get-ADOptionalFeature -Filter "Name -like '*Recycle*'" -ErrorAction SilentlyContinue).EnabledScopes
            if ($recycleBin) {
                Write-Color "  [✓] AD Recycle Bin is enabled" "Green"
            } else {
                Write-Color "  [✗] AD Recycle Bin is disabled (recommended for Azure AD Connect)" "Yellow"
            }

            Write-Color "`n  ─── Requirements ───" "Cyan"
            Write-Color "  1. AD Schema version >= 88" "White"
            Write-Color "  2. UPN suffixes must match the verified domain in Azure AD" "White"
            Write-Color "  3. No orphaned objects (run AD-024)" "White"
            Write-Color "  4. AD Recycle Bin enabled (run AD-016)" "White"
            Write-Color "  5. Enterprise Admin credentials required" "White"
            Write-Color "" "Gray"
            Write-Color "  [i] Download: https://www.microsoft.com/en-us/download/details.aspx?id=47594" "Blue"
        } catch {
            Write-Color "  [!] Azure AD Connect prep failed: $_" "Red"
        }
        Pause
    }
}
