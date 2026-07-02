Register-Tool @{
    ID          = 'AD-006'
    Name        = 'FSMO Role Management'
    Category    = 'AD'
    Description = 'Show current FSMO role holders and transfer roles to this server'
    DangerLevel = 'Dangerous'
    ConfirmMessage = 'Display FSMO roles and optionally transfer all roles to this server'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $adRole = (Get-WindowsFeature AD-Domain-Services -ErrorAction SilentlyContinue).Installed
            if (-not $adRole) { Write-Color "  AD DS not installed." "Red"; Pause; return }

            $forest = Get-ADForest
            $domain = Get-ADDomain
            Write-Color "`n  ─── FSMO ROLES ───" "Cyan"
            Write-Color "  Schema Master:        $($forest.SchemaMaster)" "White"
            Write-Color "  Domain Naming Master: $($forest.DomainNamingMaster)" "White"
            Write-Color "  PDC Emulator:         $($domain.PDCEmulator)" "White"
            Write-Color "  RID Master:           $($domain.RIDMaster)" "White"
            Write-Color "  Infrastructure Master: $($domain.InfrastructureMaster)" "White"

            $transfer = Read-Host "`n  Transfer all roles to this server? (Y/N)"
            if ($transfer -match '^[Yy]') {
                $creds = Get-Credential -Message "Enter admin credentials for current role holder"
                Move-ADDirectoryServerOperationMasterRole -Identity $env:COMPUTERNAME -OperationMasterRole SchemaMaster, DomainNamingMaster, PDCEmulator, RIDMaster, InfrastructureMaster -Credential $creds -Force
                Write-Color "  [+] FSMO roles transferred to $env:COMPUTERNAME" "Green"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
