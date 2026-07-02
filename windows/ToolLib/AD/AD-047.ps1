Register-Tool @{
    ID          = 'AD-047'
    Name        = 'AD PAM Trust Setup'
    Category    = 'AD'
    Description = 'Check/configure Privileged Access Management'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Check/configure AD PAM trust for enhanced security?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $forest = Get-ADForest
            $domain = Get-ADDomain
            $forestMode = $forest.ForestMode
            Write-Color "`n  ─── AD PRIVILEGED ACCESS MANAGEMENT (PAM) ───" "Cyan"
            Write-Color "  Forest: $($forest.RootDomain)" "White"
            Write-Color "  Forest Mode: $forestMode" "Gray"
            Write-Color "  Domain Mode: $($domain.DomainMode)" "Gray"
            $mimEnabled = $false
            try {
                $bastion = Get-ADObject -Filter "Name -eq 'CN=BASTION'" -SearchBase $forest.PartitionsContainer -ErrorAction SilentlyContinue
                $mimEnabled = $null -ne $bastion
            } catch {}
            if ($forestMode -match "2016|2019|2022|Native") {
                Write-Color "  [✓] Forest mode supports PAM (Windows Server 2016+ required)" "Green"
            } else {
                Write-Color "  [!] Forest mode must be Windows Server 2016 or higher for PAM" "Red"
                Write-Color "  [i] Current mode: $forestMode - raise the forest functional level first" "Yellow"
            }
            Write-Color "`n  ─── PAM Trust Status ───" "Cyan"
            if ($mimEnabled) {
                Write-Color "  [✓] PAM trust / MIM Bastion forest appears configured" "Green"
            } else {
                Write-Color "  [i] PAM trust not currently configured" "Yellow"
                Write-Color "`n  ─── PAM Setup Steps ───" "Cyan"
                Write-Color "  1. Create a dedicated bastion forest (separate domain)" "White"
                Write-Color "     New-ADForest -Name 'bastion.contoso.com' -ForestMode Windows2016Forest" "Gray"
                Write-Color "  2. Create PAM trust from bastion to production forest:" "White"
                Write-Color "     New-ADObject -Name 'CN=...' -Type 'trustedDomain' ..." "Gray"
                Write-Color "  3. Install MIM components on bastion forest PDC" "White"
                Write-Color "  4. Configure shadow principal synchronization" "White"
                Write-Color "  5. Move privileged groups to PAM-managed OUs" "White"
                Write-Color "`n  ─── Prerequisites ───" "Cyan"
                Write-Color "  - Two forests: production + bastion" "White"
                Write-Color "  - Forest functional level 2016+" "White"
                Write-Color "  - MIM 2016 R2 or later" "White"
                Write-Color "  - SQL Server for MIM database" "White"
                Write-Color "  - Azure AD Premium P2 (if using Azure AD integration)" "White"
            }
            Write-Color "`n  ─── Current Privileged Groups ───" "Cyan"
            $privGroups = @("Domain Admins", "Enterprise Admins", "Schema Admins", "Administrators", "Account Operators", "Server Operators", "Backup Operators")
            foreach ($pg in $privGroups) {
                try {
                    $grp = Get-ADGroup -Filter "Name -eq '$pg'" -Properties Members -ErrorAction SilentlyContinue
                    if ($grp) {
                        $count = (Get-ADGroupMember $grp.DistinguishedName -ErrorAction SilentlyContinue).Count
                        Write-Color "  $pg : $count members" "White"
                    }
                } catch {}
            }
        } catch {
            Write-Color "  [!] AD PAM Trust check failed: $_" "Red"
        }
        Pause
    }
}
