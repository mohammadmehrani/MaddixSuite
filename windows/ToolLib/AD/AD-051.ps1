Register-Tool @{
    ID          = 'AD-051'
    Name        = 'Windows LAPS Setup'
    Category    = 'AD'
    Description = 'Install/configure Windows LAPS'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Install/configure Windows LAPS on this server?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $os = Get-CimInstance Win32_OperatingSystem
            $osBuild = [int]$os.BuildNumber
            Write-Color "`n  ─── WINDOWS LAPS SETUP ───" "Cyan"
            Write-Color "  OS Build: $osBuild" "White"
            $lapsInstalled = $false
            try {
                $lapsCheck = Get-WindowsFeature -Name "LAPS" -ErrorAction SilentlyContinue
                if ($lapsCheck -and $lapsCheck.Installed) {
                    $lapsInstalled = $true
                    Write-Color "  [✓] LAPS feature is already installed" "Green"
                }
            } catch {}
            try {
                $lapsModule = Get-Module -Name "LAPS" -ListAvailable -ErrorAction SilentlyContinue
                if (-not $lapsModule) {
                    try { $lapsModule = Get-Module -Name "Microsoft.LAPS" -ListAvailable -ErrorAction SilentlyContinue } catch {}
                }
                if ($lapsModule) {
                    $lapsInstalled = $true
                    Write-Color "  [✓] LAPS management module found ($($lapsModule.Version))" "Green"
                }
            } catch {}
            if (-not $lapsInstalled) {
                Write-Color "`n  ─── LAPS Installation ───" "Cyan"
                if ($osBuild -ge 20348) {
                    Write-Color "  [*] Installing LAPS via Windows Feature..." "Yellow"
                    Install-WindowsFeature -Name "LAPS" -IncludeManagementTools -ErrorAction Stop | Out-Null
                    Write-Color "  [✓] LAPS feature installed" "Green"
                } else {
                    Write-Color "  [*] LAPS requires manual download for this OS version" "Yellow"
                    Write-Color "  Download: https://www.microsoft.com/en-us/download/details.aspx?id=46899" "Blue"
                    Write-Color "  Install MSI, then run this tool again" "Gray"
                }
            }
            Write-Color "`n  ─── AD Schema Extension Check ───" "Cyan"
            $schemaAttribs = @(
                "ms-Mcs-AdmPwd",
                "ms-Mcs-AdmPwdExpirationTime",
                "msLAPS-Password",
                "msLAPS-PasswordExpirationTime"
            )
            $attribFound = $false
            foreach ($attr in $schemaAttribs) {
                try {
                    $check = Get-ADObject -SearchBase (Get-ADRootDSE).SchemaNamingContext -Filter "Name -eq '$attr'" -ErrorAction SilentlyContinue
                    if ($check) { $attribFound = $true; Write-Color "  [✓] Schema attribute '$attr' exists" "Green" }
                } catch {}
            }
            if (-not $attribFound) {
                Write-Color "  [!] No LAPS schema attributes found - need to extend schema" "Yellow"
                if ($lapsInstalled) {
                    Write-Color "  [*] Running LAPS schema update..." "Cyan"
                    if ($osBuild -ge 20348) {
                        try { Update-LapsADSchema -ErrorAction Stop; Write-Color "  [✓] Schema updated with Windows LAPS attributes" "Green" } catch { Write-Color "  [!] Schema update failed: $_" "Red" }
                    } else {
                        try { Import-Module "AdmPwd.PS" -ErrorAction Stop; Update-AdmPwdADSchema -ErrorAction Stop; Write-Color "  [✓] Schema updated with Legacy LAPS attributes" "Green" } catch { Write-Color "  [!] Legacy schema update failed: $_" "Red" }
                    }
                }
            }
            Write-Color "`n  ─── LAPS Configuration Steps ───" "Cyan"
            Write-Color "  1. Delegate LAPS password read permissions to computers:" "White"
            Write-Color "     Set-AdmPwdComputerSelfPermission -OrgUnit 'OU=Computers,DC=domain,DC=com'" "Gray"
            Write-Color "  2. Create GPO for LAPS policy:" "White"
            Write-Color "     Computer Config > Policies > Admin Templates > LAPS" "Gray"
            Write-Color "     - Enable: 'Configure password backup directory'" "Gray"
            Write-Color "     - Set: 'Back up passwords to AD'" "Gray"
            Write-Color "  3. Configure password settings:" "White"
            Write-Color "     - Password length: 14-20 characters" "Gray"
            Write-Color "     - Password age: 30 days" "Gray"
            Write-Color "  4. Read a password:" "White"
            Write-Color "     Get-LapsADPassword -Identity <computername> -AsPlainText" "Gray"
            Write-Color "`n  [!] Wait for GPO replication before passwords are backed up" "Yellow"
        } catch {
            Write-Color "  [!] Windows LAPS Setup failed: $_" "Red"
        }
        Pause
    }
}
