Register-Tool @{
    ID          = 'AD-042'
    Name        = 'AD Permission Analyzer'
    Category    = 'AD'
    Description = 'Use dsacls to analyze delegated permissions on OUs'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Analyze delegated permissions on AD OUs?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $output = Join-Path $env:TEMP "AD-Permissions-$(Get-Date -Format yyyyMMdd-HHmmss).csv"
            $ous = Get-ADOrganizationalUnit -Filter * -Properties DistinguishedName
            $results = @()
            Write-Color "  [*] Analyzing permissions on $($ous.Count) OUs..." "Cyan"
            $i = 0
            foreach ($ou in $ous) {
                $i++
                Write-Progress -Activity "Analyzing OUs" -Status $ou.Name -PercentComplete (($i / $ous.Count) * 100)
                try {
                    $aclOutput = & dsacls $ou.DistinguishedName 2>$null
                    $inherited = $false
                    $delegated = @()
                    $denyEntries = @()
                    foreach ($line in $aclOutput) {
                        if ($line -match "Inherited\s+ACL") { $inherited = $true }
                        if ($line -match "^\s+Allow\s+") {
                            $parts = $line.Trim() -split '\s+'
                            $user = if ($parts.Count -ge 2) { $parts[1] } else { "" }
                            $rights = if ($parts.Count -ge 3) { $parts[2] -replace ',$','' } else { "" }
                            $delegated += "$user`:$rights"
                        }
                        if ($line -match "^\s+Deny\s+") {
                            $denyEntries += $line.Trim()
                        }
                    }
                    $results += [PSCustomObject]@{
                        OU = $ou.Name
                        DistinguishedName = $ou.DistinguishedName
                        Protected = $inherited
                        DelegatedCount = $delegated.Count
                        DelegatedEntries = ($delegated -join ';').Substring(0,[Math]::Min(30000,($delegated -join ';').Length))
                        DenyCount = $denyEntries.Count
                        Path = $ou.DistinguishedName
                    }
                } catch {
                    Write-Color "  [!] Failed on $($ou.Name): $_" "Red"
                }
            }
            $results | Export-Csv -Path $output -NoTypeInformation -Encoding UTF8
            Write-Color "  [+] Permission analysis saved to: $output" "Green"
            Write-Color "  [i] Total OUs: $($results.Count)" "Gray"
            Write-Color "  [i] OUs with delegated permissions: $(($results | Where-Object { $_.DelegatedCount -gt 0 }).Count)" "Gray"
            $unprotected = ($results | Where-Object { -not $_.Protected }).Count
            if ($unprotected -gt 0) {
                Write-Color "  [!] $unprotected OUs are NOT protected from inheritance" "Yellow"
            }
        } catch {
            Write-Color "  [!] AD Permission Analyzer failed: $_" "Red"
        }
        Pause
    }
}
