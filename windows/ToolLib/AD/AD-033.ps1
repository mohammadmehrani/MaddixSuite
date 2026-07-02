Register-Tool @{
    ID          = 'AD-033'
    Name        = 'AD Delegation Control'
    Category    = 'AD'
    Description = 'Delegate AD permissions with dsacls'
    DangerLevel = 'Dangerous'
    ConfirmMessage = 'Delegate AD permissions on an OU to a user/group?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] AD Delegation Control" "Cyan"
            $user = Read-Host "  User or group to delegate"
            $ou = Read-Host "  Target OU DistinguishedName (e.g., OU=Users,DC=domain,DC=local)"

            if (-not $user -or -not $ou) { throw "User/group and OU are required" }

            $perms = @("Create User", "Delete User", "Reset Password", "Modify Group Membership")
            Write-Color "  Available permissions:" "Gray"
            for ($i = 0; $i -lt $perms.Count; $i++) {
                Write-Color "    $($i+1). $($perms[$i])" "White"
            }
            $sel = Read-Host "  Select permission number (1-4)"
            if ($sel -match '^[1-4]$') {
                $rightMap = @("CreateChild", "DeleteChild", "ResetPassword", "WriteMember")
                $right = $rightMap[[int]$sel - 1]
                Write-Color "  [*] Setting delegation: $right on $ou for $user ..." "Cyan"
                dsacls $ou /G "$user`:$right;user" 2>$null
                Write-Color "  [+] Delegation applied to '$user' on '$ou'" "Green"
            }
        } catch {
            Write-Color "  [!] Delegation failed: $_" "Red"
        }
        Pause
    }
}
