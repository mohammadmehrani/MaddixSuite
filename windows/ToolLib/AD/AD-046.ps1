Register-Tool @{
    ID          = 'AD-046'
    Name        = 'AD Tombstone Lifecycle'
    Category    = 'AD'
    Description = 'Check tombstone lifetime, configure'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Check/configure AD tombstone lifetime?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $configNC = (Get-ADRootDSE).ConfigurationNamingContext
            $cnDirSvc = "CN=Directory Service,CN=Windows NT,CN=Services,$configNC"
            $dsObj = Get-ADObject $cnDirSvc -Properties tombstoneLifetime -ErrorAction Stop
            $currentTsl = $dsObj.tombstoneLifetime
            Write-Color "`n  ─── AD TOMBSTONE LIFETIME ───" "Cyan"
            if ($currentTsl) {
                Write-Color "  [i] Current Tombstone Lifetime: $currentTsl days" "White"
                if ($currentTsl -ge 180) {
                    Write-Color "  [✓] Adequate for AD backup/restore scenarios" "Green"
                } else {
                    Write-Color "  [!] Tombstone lifetime is less than 180 days" "Yellow"
                    Write-Color "  [!] This may cause issues with backups older than $currentTsl days" "Yellow"
                }
            } else {
                Write-Color "  [i] Current Tombstone Lifetime: Not set (default varies by OS version)" "Gray"
                Write-Color "  [i] Windows 2003+: default is 60 days, 2003 SP1+: 180 days" "Gray"
                Write-Color "  [i] Windows Server 2008+: default is 180 days" "Gray"
                $currentTsl = 0
            }
            $recycleBinEnabled = (Get-ADOptionalFeature -Filter "Name -like '*Recycle*'" -ErrorAction SilentlyContinue).EnabledScopes.Count -gt 0
            if ($recycleBinEnabled) {
                Write-Color "  [i] AD Recycle Bin is enabled - deleted objects retained for tombstone lifetime" "Green"
            }
            $recommended = 180
            Write-Color "`n  ─── Recommendation ───" "Cyan"
            Write-Color "  Recommended minimum: $recommended days" "White"
            $default = if ((Get-ADForest).ForestMode -match "2008|2008 R2|2012|2012 R2|2016|2019|2022|Native") { 180 } else { 60 }
            Write-Color "  Default for this forest: $default days" "Gray"
            $effective = if ($currentTsl -gt 0) { $currentTsl } else { $default }
            Write-Color "  Effective tombstone lifetime: $effective days" "Cyan"
            $choice = Read-Host "`nEnter new tombstone lifetime in days (0 to skip, $recommended recommended)"
            if ($choice -match '^\d+$' -and [int]$choice -ge 1) {
                $newValue = [int]$choice
                Set-ADObject $cnDirSvc -Replace @{tombstoneLifetime=$newValue} -ErrorAction Stop
                Write-Color "  [+] Tombstone lifetime set to $newValue days" "Green"
                Write-Color "  [!] Changes take effect immediately, no reboot required" "Yellow"
            } else {
                Write-Color "  [i] No changes made" "Gray"
            }
            Write-Color "`n  ─── Impact of Tombstone Lifetime ───" "Cyan"
            Write-Color "  - Authoritative restores: backup must be within tombstone lifetime" "White"
            Write-Color "  - Replication partner syncs must occur within this window" "White"
            Write-Color "  - AD Recycle Bin retention is tied to this value" "White"
        } catch {
            Write-Color "  [!] AD Tombstone Lifecycle check failed: $_" "Red"
        }
        Pause
    }
}
