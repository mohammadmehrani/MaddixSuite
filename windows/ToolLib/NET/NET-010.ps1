Register-Tool @{
    ID          = 'NET-010'
    Name        = 'Network Profile Manager'
    Category    = 'NET'
    Description = 'Set network category to Private/Public/Domain'
    DangerLevel = 'Caution'
    ConfirmMessage = 'Changes network profile category on active adapters.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── NETWORK PROFILE MANAGER ───" "Cyan"
        try {
            $adapters = Get-NetConnectionProfile -ErrorAction Stop
            if (-not $adapters) {
                Write-Color "  [!] No network connection profiles found." "Red"
                Pause
                return
            }
            Write-Color "  Available profiles:" "White"
            $i = 1
            $profiles = @()
            foreach ($a in $adapters) {
                Write-Color "  $i. $($a.Name) - $($a.NetworkCategory)" ($a.NetworkCategory -eq "Public" ? "Yellow" : "Green")
                $profiles += $a
                $i++
            }
            $sel = Read-Host "`n  Select profile (number)"
            $selected = $profiles[[int]$sel - 1]
            Write-Color "`n  Current: $($selected.NetworkCategory)" "White"
            Write-Color "  1. Public" "Yellow"
            Write-Color "  2. Private" "Green"
            Write-Color "  3. Domain (requires domain membership)" "Blue"
            Write-Color "  0. Back" "Red"
            $mode = Read-Host "`n  Set to"
            $catMap = @{ "1" = "Public"; "2" = "Private"; "3" = "Domain" }
            if ($catMap.ContainsKey($mode)) {
                $newCat = $catMap[$mode]
                try {
                    Set-NetConnectionProfile -InterfaceIndex $selected.InterfaceIndex -NetworkCategory $newCat -ErrorAction Stop
                    Write-Color "  [+] $($selected.Name) changed to $newCat" "Green"
                } catch {
                    Write-Color "  [!] Failed to set profile: $_" "Red"
                }
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
