Register-Tool @{
    ID          = 'AD-029'
    Name        = 'Domain Trust Management'
    Category    = 'AD'
    Description = 'Create and review domain trusts with New-ADTrust'
    DangerLevel = 'Dangerous'
    ConfirmMessage = 'Check existing trusts and optionally create a new domain trust?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Domain Trust Management" "Cyan"
            $domain = (Get-ADDomain -ErrorAction SilentlyContinue).DNSRoot
            if (-not $domain) { throw "Not connected to an AD domain" }

            $trusts = Get-ADTrust -Filter * -ErrorAction SilentlyContinue
            if ($trusts) {
                Write-Color "  [+] Existing Trusts:" "Cyan"
                $trusts | Format-Table Name, Direction, TrustType, TrustAttributes -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
            } else {
                Write-Color "  [i] No existing trusts found" "Gray"
            }

            $choice = Read-Host "  [?] Create a new external trust? (y/N)"
            if ($choice -eq 'y') {
                $trustDomain = Read-Host "  Trusted domain name"
                $trustPass = Read-Host "  Trust password" -AsSecureString
                Write-Color "  [*] Creating trust with $trustDomain ..." "Cyan"
                New-ADTrust -Name $trustDomain -SourceDomain $domain -TargetDomain $trustDomain -TrustType External -TrustDirection Bidirectional -TrustPassword $trustPass
                Write-Color "  [+] Trust created with $trustDomain" "Green"
            }
        } catch {
            Write-Color "  [!] Trust management failed: $_" "Red"
        }
        Pause
    }
}
