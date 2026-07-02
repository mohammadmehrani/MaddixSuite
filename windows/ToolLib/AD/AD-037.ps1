Register-Tool @{
    ID          = 'AD-037'
    Name        = 'KDS Root Key (for gMSA)'
    Category    = 'AD'
    Description = 'Add KDS Root Key for Group Managed Service Accounts'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Check/create KDS Root Key for gMSA support?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] KDS Root Key Management" "Cyan"
            $existingKey = Get-KdsRootKey -ErrorAction SilentlyContinue

            if ($existingKey) {
                Write-Color "  [+] KDS Root Key exists" "Green"
                $existingKey | Format-List * | Out-String | ForEach-Object { Write-Host $_ }
            } else {
                Write-Color "  [i] No KDS Root Key found" "Yellow"
                $choice = Read-Host "  [?] Create KDS Root Key for gMSA support? (y/N)"
                if ($choice -eq 'y') {
                    Write-Color "  [*] Creating KDS Root Key..." "Cyan"
                    Add-KdsRootKey -EffectiveTime (Get-Date).AddHours(-10)
                    Write-Color "  [+] KDS Root Key created" "Green"
                    Write-Color "  [i] gMSA can now be created" "Gray"
                    Write-Color "  [i] It may take up to 10 hours for the key to propagate" "Yellow"
                }
            }
        } catch {
            Write-Color "  [!] KDS Root Key operation failed: $_" "Red"
        }
        Pause
    }
}
