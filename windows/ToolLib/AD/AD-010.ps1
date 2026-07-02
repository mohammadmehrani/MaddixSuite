Register-Tool @{
    ID          = 'AD-010'
    Name        = 'AD Bulk User Import (CSV)'
    Category    = 'AD'
    Description = 'Bulk import users from a CSV file with Name, Sam, UPN, Password columns'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Import multiple users from CSV file into Active Directory'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $csv = Read-Host "  CSV file path"
            if (-not $csv) { Write-Color "  No file specified." "Yellow"; Pause; return }
            if (-not (Test-Path $csv)) { Write-Color "  File not found: $csv" "Red"; Pause; return }

            $users = Import-Csv $csv
            $count = 0
            foreach ($u in $users) {
                try {
                    $pw = ConvertTo-SecureString $u.Password -AsPlainText -Force
                    New-ADUser -Name $u.Name -SamAccountName $u.Sam -UserPrincipalName $u.UPN -AccountPassword $pw -Enabled $true
                    $count++
                    Write-Color "  [+] Created: $($u.Name)" "Green"
                } catch {
                    Write-Color "  [!] Failed: $($u.Name) — $_" "Red"
                }
            }
            Write-Color "  Imported $count of $($users.Count) users." "Green"
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
