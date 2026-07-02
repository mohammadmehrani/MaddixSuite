Register-Tool @{
    ID          = 'AD-031'
    Name        = 'Fine-Grained Password Policy'
    Category    = 'AD'
    Description = 'Create FGPP with New-ADFineGrainedPasswordPolicy, apply to groups'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'View existing FGPPs and optionally create a new Fine-Grained Password Policy?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Fine-Grained Password Policies" "Cyan"
            $fgpps = Get-ADFineGrainedPasswordPolicy -Filter * -ErrorAction SilentlyContinue
            if ($fgpps) {
                Write-Color "  [+] Existing FGPPs:" "Cyan"
                $fgpps | Format-Table Name, MinPasswordLength, ComplexityEnabled, Precedence -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
            } else {
                Write-Color "  [i] No Fine-Grained Password Policies found" "Gray"
            }

            $newName = Read-Host "  New FGPP name (Enter to skip)"
            if ($newName) {
                Write-Color "  [*] Creating FGPP: $newName ..." "Cyan"
                New-ADFineGrainedPasswordPolicy -Name $newName -MinPasswordLength 14 -ComplexityEnabled $true -Precedence 100
                $group = Read-Host "  Apply to group (SAMAccountName)"
                if ($group) {
                    Add-ADFineGrainedPasswordPolicySubject -Identity $newName -Subjects $group
                    Write-Color "  [+] FGPP '$newName' created and applied to '$group'" "Green"
                } else {
                    Write-Color "  [+] FGPP '$newName' created (not applied to any group)" "Green"
                }
            }
        } catch {
            Write-Color "  [!] FGPP operation failed: $_" "Red"
        }
        Pause
    }
}
