Register-Tool @{
    ID          = 'AD-008'
    Name        = 'AD Group Manager'
    Category    = 'AD'
    Description = 'List groups, view members, create groups, add/remove members'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Open AD Group Manager submenu'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            do {
                Write-Color "`n  ─── AD GROUP MANAGER ───" "Cyan"
                Write-Color "  1. List All Groups" "White"
                Write-Color "  2. View Group Members" "White"
                Write-Color "  3. Create Group" "White"
                Write-Color "  4. Add Member to Group" "White"
                Write-Color "  5. Remove Member from Group" "White"
                Write-Color "  0. Back" "Red"
                $c = Read-Host "> "
                switch ($c) {
                    "1" {
                        Get-ADGroup -Filter * | Format-Table Name, GroupCategory, GroupScope, SamAccountName -AutoSize
                    }
                    "2" {
                        $g = Read-Host "  Group name (SAM)"
                        Get-ADGroupMember $g | Format-Table Name, SamAccountName, ObjectClass -AutoSize
                    }
                    "3" {
                        $n = Read-Host "  Group name"
                        $cat = Read-Host "  Category (Security/Distribution)"
                        $scope = Read-Host "  Scope (Global/DomainLocal/Universal)"
                        if (-not $cat) { $cat = "Security" }
                        if (-not $scope) { $scope = "Global" }
                        New-ADGroup -Name $n -GroupCategory $cat -GroupScope $scope
                        Write-Color "  [+] Group $n created" "Green"
                    }
                    "4" {
                        $g = Read-Host "  Group name (SAM)"
                        $m = Read-Host "  Member SAM to add"
                        Add-ADGroupMember -Identity $g -Members $m
                        Write-Color "  [+] $m added to $g" "Green"
                    }
                    "5" {
                        $g = Read-Host "  Group name (SAM)"
                        $m = Read-Host "  Member SAM to remove"
                        Remove-ADGroupMember -Identity $g -Members $m -Confirm:$false
                        Write-Color "  [+] $m removed from $g" "Green"
                    }
                }
            } while ($c -ne "0")
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
