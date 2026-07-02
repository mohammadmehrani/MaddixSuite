Register-Tool @{
    ID          = 'AD-038'
    Name        = 'Managed Service Accounts'
    Category    = 'AD'
    Description = 'Create and install Group Managed Service Accounts (gMSA)'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'List existing gMSAs and optionally create a new one?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Managed Service Accounts" "Cyan"
            $gmsas = Get-ADServiceAccount -Filter * -ErrorAction SilentlyContinue
            if ($gmsas) {
                Write-Color "  [+] Existing gMSAs:" "Cyan"
                $gmsas | Format-Table Name, HostComputers -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
            } else {
                Write-Color "  [i] No gMSAs found" "Gray"
            }

            $newName = Read-Host "`n  New gMSA name (Enter to skip)"
            if ($newName) {
                $domain = (Get-ADDomain -ErrorAction SilentlyContinue).DNSRoot
                if (-not $domain) { throw "Not connected to an AD domain" }

                Write-Color "  [*] Creating gMSA: $newName ..." "Cyan"
                $principals = @("$env:COMPUTERNAME$")
                New-ADServiceAccount -Name $newName -DNSHostName "$newName.$domain" -PrincipalsAllowedToRetrieveManagedPassword $principals
                Write-Color "  [+] gMSA '$newName' created" "Green"

                $installChoice = Read-Host "  [?] Install gMSA on this server? (y/N)"
                if ($installChoice -eq 'y') {
                    Install-ADServiceAccount -Identity $newName
                    Write-Color "  [+] gMSA '$newName' installed on this server" "Green"
                }
            }
        } catch {
            Write-Color "  [!] gMSA operation failed: $_" "Red"
        }
        Pause
    }
}
