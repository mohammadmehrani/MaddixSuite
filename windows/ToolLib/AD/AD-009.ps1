Register-Tool @{
    ID          = 'AD-009'
    Name        = 'AD Computer Manager'
    Category    = 'AD'
    Description = 'List computers, disable/enable/move computer accounts'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Open AD Computer Manager submenu'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            do {
                Write-Color "`n  ─── AD COMPUTER MANAGER ───" "Cyan"
                Write-Color "  1. List Computers" "White"
                Write-Color "  2. Disable Computer" "White"
                Write-Color "  3. Enable Computer" "White"
                Write-Color "  4. Move Computer (OU)" "White"
                Write-Color "  0. Back" "Red"
                $c = Read-Host "> "
                switch ($c) {
                    "1" {
                        Get-ADComputer -Filter * -Properties OperatingSystem, Enabled | Format-Table Name, Enabled, OperatingSystem -AutoSize
                    }
                    "2" {
                        $comp = Read-Host "  Computer name"
                        Disable-ADAccount -Identity "$comp$"
                        Write-Color "  [+] $comp disabled" "Yellow"
                    }
                    "3" {
                        $comp = Read-Host "  Computer name"
                        Enable-ADAccount -Identity "$comp$"
                        Write-Color "  [+] $comp enabled" "Green"
                    }
                    "4" {
                        $comp = Read-Host "  Computer name"
                        $ou = Read-Host "  Target OU DistinguishedName"
                        Move-ADObject -Identity (Get-ADComputer $comp).DistinguishedName -TargetPath $ou
                        Write-Color "  [+] $comp moved" "Green"
                    }
                }
            } while ($c -ne "0")
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
