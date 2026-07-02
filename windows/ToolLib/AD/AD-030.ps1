Register-Tool @{
    ID          = 'AD-030'
    Name        = 'Password Policy'
    Category    = 'AD'
    Description = 'View and set domain password policy with Set-ADDefaultDomainPasswordPolicy'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'View and optionally modify the domain password policy?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Domain Password Policy" "Cyan"
            $policy = Get-ADDefaultDomainPasswordPolicy -ErrorAction SilentlyContinue
            if (-not $policy) { throw "Unable to retrieve domain password policy" }

            Write-Color "  [+] Current Policy:" "Cyan"
            $policy | Format-List * | Out-String | ForEach-Object { Write-Host $_ }

            $minLen = Read-Host "  New Min Password Length (current: $($policy.MinPasswordLength), Enter to skip)"
            $maxAge = Read-Host "  New Max Password Age in days (current: $($policy.MaxPasswordAge.Days), Enter to skip)"

            if ($minLen -or $maxAge) {
                $params = @{}
                if ($minLen) { $params.MinPasswordLength = [int]$minLen }
                if ($maxAge) { $params.MaxPasswordAge = [TimeSpan]::FromDays([int]$maxAge) }
                Write-Color "  [*] Updating password policy..." "Cyan"
                Set-ADDefaultDomainPasswordPolicy @params
                Write-Color "  [+] Password policy updated" "Green"
            }
        } catch {
            Write-Color "  [!] Password policy operation failed: $_" "Red"
        }
        Pause
    }
}
