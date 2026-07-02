Register-Tool @{
    ID          = 'AD-007'
    Name        = 'AD User Manager'
    Category    = 'AD'
    Description = 'Manage AD users — list, create, disable, enable, reset password, unlock, move, delete'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Open the AD User Manager submenu for user operations'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            do {
                Write-Color "`n  ─── AD USER MANAGER ───" "Cyan"
                Write-Color "  1. List Users" "White"
                Write-Color "  2. Create User" "White"
                Write-Color "  3. Disable User" "White"
                Write-Color "  4. Enable User" "White"
                Write-Color "  5. Reset Password" "White"
                Write-Color "  6. Unlock Account" "White"
                Write-Color "  7. Move User (OU)" "White"
                Write-Color "  8. Delete User" "White"
                Write-Color "  0. Back" "Red"
                $c = Read-Host "> "
                switch ($c) {
                    "1" {
                        Get-ADUser -Filter * -Properties LastLogonDate, Enabled | Format-Table Name, SamAccountName, Enabled, LastLogonDate -AutoSize
                    }
                    "2" {
                        $n = Read-Host "  Name"
                        $s = Read-Host "  SAM Account Name"
                        $u = Read-Host "  UPN (prefix)"
                        $pw = Read-Host "  Password" -AsSecureString
                        $domain = (Get-ADDomain).DNSRoot
                        New-ADUser -Name $n -SamAccountName $s -UserPrincipalName "$u@$domain" -AccountPassword $pw -Enabled $true
                        Write-Color "  [+] User $n created" "Green"
                    }
                    "3" {
                        $u = Read-Host "  Username"
                        Disable-ADAccount $u
                        Write-Color "  [+] $u disabled" "Yellow"
                    }
                    "4" {
                        $u = Read-Host "  Username"
                        Enable-ADAccount $u
                        Write-Color "  [+] $u enabled" "Green"
                    }
                    "5" {
                        $u = Read-Host "  Username"
                        $pw = Read-Host "  New Password" -AsSecureString
                        Set-ADAccountPassword $u -NewPassword $pw -Reset
                        Write-Color "  [+] Password reset for $u" "Green"
                    }
                    "6" {
                        $u = Read-Host "  Username"
                        Unlock-ADAccount $u
                        Write-Color "  [+] $u unlocked" "Green"
                    }
                    "7" {
                        $u = Read-Host "  Username"
                        $ou = Read-Host "  Target OU DistinguishedName"
                        Move-ADObject -Identity (Get-ADUser $u).DistinguishedName -TargetPath $ou
                        Write-Color "  [+] $u moved" "Green"
                    }
                    "8" {
                        $u = Read-Host "  Username"
                        $conf = Read-Host "  Delete $u? (Y/N)"
                        if ($conf -match '^[Yy]') { Remove-ADUser -Identity $u -Confirm:$false; Write-Color "  [+] $u deleted" "Green" }
                    }
                }
            } while ($c -ne "0")
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
