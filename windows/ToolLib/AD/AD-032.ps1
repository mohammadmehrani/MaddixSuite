Register-Tool @{
    ID          = 'AD-032'
    Name        = 'AD Audit Policy'
    Category    = 'AD'
    Description = 'Enable advanced audit with auditpol for AD categories'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'View current audit policy and enable advanced AD auditing?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Advanced Audit Policy" "Cyan"

            Write-Color "  [+] Current audit policy:" "Cyan"
            auditpol /get /category:* 2>&1 | ForEach-Object { Write-Host $_ }

            $choice = Read-Host "`n  [?] Enable advanced auditing for AD categories? (y/N)"
            if ($choice -eq 'y') {
                Write-Color "  [*] Enabling AD audit policies..." "Cyan"
                auditpol /set /subcategory:"Directory Service Changes" /success:enable /failure:enable
                auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable
                auditpol /set /subcategory:"Computer Account Management" /success:enable /failure:enable
                auditpol /set /subcategory:"Security Group Management" /success:enable /failure:enable
                Write-Color "  [+] AD audit policies enabled" "Green"
            }
        } catch {
            Write-Color "  [!] Audit policy operation failed: $_" "Red"
        }
        Pause
    }
}
