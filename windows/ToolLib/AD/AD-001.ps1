Register-Tool @{
    ID          = 'AD-001'
    Name        = 'AD Environment Status'
    Category    = 'AD'
    Description = 'Show Active Directory environment status including domain, forest, FSMO, and DC info'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Displays AD environment status (read-only)'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $info = @{}
            $os = Get-CimInstance Win32_OperatingSystem
            $cs = Get-CimInstance Win32_ComputerSystem
            $info.OSName = $os.Caption; $info.OSBuild = $os.BuildNumber
            $info.Hostname = $cs.Name
            $info.Domain = $cs.Domain
            $info.InDomain = $cs.PartOfDomain
            $info.ADRole = (Get-WindowsFeature AD-Domain-Services -ErrorAction SilentlyContinue).Installed
            $info.ADDomain = if ($info.ADRole) { try { (Get-ADDomain -ErrorAction Stop).DNSRoot } catch { $null } } else { $null }
            $info.ForestMode = if ($info.ADDomain) { try { (Get-ADForest).ForestMode } catch { $null } } else { $null }
            $info.DomainMode = if ($info.ADDomain) { try { (Get-ADDomain).DomainMode } catch { $null } } else { $null }
            $info.IsDC = if ($info.ADDomain) { (Get-ADDomainController -Filter * -ErrorAction SilentlyContinue).Count -gt 0 } else { $false }
            $info.DCs = if ($info.IsDC) { (Get-ADDomainController -Filter *).Name -join ', ' } else { $null }

            Write-Color "`n  ─── AD ENVIRONMENT STATUS ───" "Cyan"
            Write-Color "  Hostname:       $($info.Hostname)" "White"
            Write-Color "  OS:             $($info.OSName) (Build $($info.OSBuild))" "Gray"
            Write-Color "  Server:         $($info.IsServer)" "White"
            Write-Color "  In Domain:      $($info.InDomain)" "White"
            Write-Color "  Domain:         $($info.Domain)" "Gray"
            Write-Color "  AD DS Role:     $($info.ADRole)" "White"
            Write-Color "  AD Domain:      $($info.ADDomain)" "Green"
            Write-Color "  Forest Mode:    $($info.ForestMode)" "Gray"
            Write-Color "  Domain Mode:    $($info.DomainMode)" "Gray"
            Write-Color "  Is DC:          $($info.IsDC)" "White"
            Write-Color "  DCs:            $($info.DCs)" "Gray"
            Write-Color "  ──────────────────────────────" "Cyan"
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
