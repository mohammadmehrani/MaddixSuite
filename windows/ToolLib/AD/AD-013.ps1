Register-Tool @{
    ID          = 'AD-013'
    Name        = 'GPO Manager'
    Category    = 'AD'
    Description = 'List, create, link, and backup/restore Group Policy Objects'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Open GPO Manager submenu'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            do {
                Write-Color "`n  ─── GPO MANAGER ───" "Cyan"
                Write-Color "  1. List All GPOs" "White"
                Write-Color "  2. Create GPO" "White"
                Write-Color "  3. Link GPO to OU" "White"
                Write-Color "  0. Back" "Red"
                $c = Read-Host "> "
                switch ($c) {
                    "1" {
                        Get-GPO -All | Format-Table DisplayName, Id, GpoStatus, CreationTime -AutoSize
                    }
                    "2" {
                        $n = Read-Host "  GPO Name"
                        New-GPO -Name $n
                        Write-Color "  [+] GPO '$n' created" "Green"
                    }
                    "3" {
                        $g = Read-Host "  GPO Name"
                        $ou = Read-Host "  Target OU DistinguishedName"
                        New-GPLink -Name $g -Target $ou
                        Write-Color "  [+] GPO linked to $ou" "Green"
                    }
                }
            } while ($c -ne "0")
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
