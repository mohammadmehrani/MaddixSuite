Register-Tool @{
    ID          = 'AD-036'
    Name        = 'Domain Rename Prep'
    Category    = 'AD'
    Description = 'Check prerequisites for domain rename operation'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Check prerequisites for domain rename?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Domain Rename Prerequisites" "Cyan"
            $domain = (Get-ADDomain -ErrorAction SilentlyContinue)
            $forest = (Get-ADForest -ErrorAction SilentlyContinue)

            Write-Color "`n  ─── Prerequisites Check ───" "Cyan"

            $rendomExists = Get-Command rendom.exe -ErrorAction SilentlyContinue
            if ($rendomExists) {
                Write-Color "  [✓] rendom.exe available" "Green"
            } else {
                Write-Color "  [✗] rendom.exe not found (part of AD tools)" "Red"
            }

            $domainMode = $domain.DomainMode
            Write-Color "  [i] Current Domain Mode: $domainMode" "Gray"
            Write-Color "  [i] Current Forest Mode: $($forest.ForestMode)" "Gray"
            Write-Color "  [i] Domain: $($domain.DNSRoot)" "Gray"
            Write-Color "  [i] Forest: $($forest.Name)" "Gray"

            Write-Color "`n  ─── Requirements ───" "Cyan"
            Write-Color "  1. All DCs must be running Windows Server 2008 or later" "White"
            Write-Color "  2. Forest Functional Level must be Windows Server 2003 or higher" "White"
            Write-Color "  3. You need Enterprise Admin credentials" "White"
            Write-Color "  4. Run: rendom /list to generate DomainList.xml" "White"
            Write-Color "  5. Edit DomainList.xml to change the DNS and NetBIOS names" "White"
            Write-Color "  6. Run: rendom /upload, rendom /prepare, rendom /execute" "White"
            Write-Color "" "Gray"
            Write-Color "  [i] Domain rename requires a forest-wide reboot" "Yellow"
            Write-Color "  [i] Not recommended in production without thorough planning" "Yellow"
        } catch {
            Write-Color "  [!] Domain rename prep failed: $_" "Red"
        }
        Pause
    }
}
