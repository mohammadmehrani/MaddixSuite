Register-Tool @{
    ID          = 'AD-055'
    Name        = 'AD Cross-Forest Migration'
    Category    = 'AD'
    Description = 'Prepare and execute cross-forest migration'
    DangerLevel = 'Dangerous'
    ConfirmMessage = 'Prepare cross-forest migration assessment?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            $sourceDomain = Read-Host "Source domain FQDN"
            $targetDomain = Read-Host "Target domain FQDN"
            Write-Color "`n  ─── AD CROSS-FOREST MIGRATION ───" "Cyan"
            Write-Color "  Source: $sourceDomain" "White"
            Write-Color "  Target: $targetDomain" "White"
            Write-Color "`n  ─── Trust Relationship Check ───" "Cyan"
            $trusts = Get-ADTrust -Filter *
            $trustExists = $false
            foreach ($trust in $trusts) {
                if ($trust.Source -match $sourceDomain -and $trust.Target -match $targetDomain) {
                    $trustExists = $true
                    Write-Color "  [✓] Trust found: $($trust.Source) -> $($trust.Target) ($($trust.TrustType))" "Green"
                    Write-Color "  [i] Direction: $($trust.TrustDirection)" "Gray"
                    Write-Color "  [i] Transitive: $($trust.TrustTransitive)" "Gray"
                }
                if ($trust.Source -match $targetDomain -and $trust.Target -match $sourceDomain) {
                    $trustExists = $true
                    Write-Color "  [✓] Trust found: $($trust.Source) -> $($trust.Target) ($($trust.TrustType))" "Green"
                }
            }
            if (-not $trustExists) {
                Write-Color "  [!] No trust found between $sourceDomain and $targetDomain" "Yellow"
                Write-Color "  [i] Create trust:" "Cyan"
                Write-Color "  New-ADTrust -Name '$sourceDomain-$targetDomain' -SourceDC <DC> -TargetDC <DC>" "Gray"
            }
            Write-Color "`n  ─── Forest/Domain Comparison ───" "Cyan"
            try {
                $srcForestInfo = Get-ADForest -Server $sourceDomain -ErrorAction Stop
                $tgtForestInfo = Get-ADForest -Server $targetDomain -ErrorAction Stop
                Write-Color "  Source Forest Mode: $($srcForestInfo.ForestMode)" "White"
                Write-Color "  Target Forest Mode: $($tgtForestInfo.ForestMode)" "White"
                if ($srcForestInfo.ForestMode -le $tgtForestInfo.ForestMode) {
                    Write-Color "  [✓] Target forest mode supports source" "Green"
                } else {
                    Write-Color "  [!] Target forest mode is lower than source - may need upgrade" "Yellow"
                }
                Write-Color "  Source UPN Suffixes: $($srcForestInfo.UPNSuffixes -join ', ')" "Gray"
                Write-Color "  Target UPN Suffixes: $($tgtForestInfo.UPNSuffixes -join ', ')" "Gray"
            } catch {
                Write-Color "  [!] Could not query one or both forests: $_" "Red"
            }
            Write-Color "`n  ─── Migration Readiness ───" "Cyan"
            Write-Color "  [i] Tools required: Active Directory Migration Tool (ADMT) v3.2" "White"
            Write-Color "  [i] Download: https://www.microsoft.com/en-us/download/details.aspx?id=56570" "Blue"
            $srccount = @(Get-ADUser -Filter * -Server $sourceDomain -ErrorAction SilentlyContinue).Count
            $tgtcount = @(Get-ADUser -Filter * -Server $targetDomain -ErrorAction SilentlyContinue).Count
            Write-Color "  Source users: $srccount | Target users: $tgtcount" "Gray"
            Write-Color "`n  ─── Migration Steps ───" "Cyan"
            Write-Color "  1. Install ADMT on a migration server (preferably in source domain)" "White"
            Write-Color "  2. Configure SID filtering and auditing" "White"
            Write-Color "     $ netdom trust $sourceDomain /quarantine:No" "Gray"
            Write-Color "  3. Perform pre-migration by running ADMT wizards:" "White"
            Write-Color "     - User Migration Wizard" "Gray"
            Write-Color "     - Group Migration Wizard" "Gray"
            Write-Color "     - Computer Migration Wizard" "Gray"
            Write-Color "  4. Password Export Server (PES) setup (for password migration)" "White"
            Write-Color "     Install PES on target DC via ADMT setup" "Gray"
            Write-Color "  5. Retire source accounts after cutover" "White"
            Write-Color "`n  ─── Migration Considerations ───" "Cyan"
            Write-Color "  - SIDHistory is enabled to preserve resource access" "White"
            Write-Color "  - Exchange migration requires additional tools" "White"
            Write-Color "  - DNS namespace may need conditional forwarders" "White"
            Write-Color "  - GPOs must be migrated separately via GPMC" "White"
            Write-Color "  - Schema differences may affect synchronized objects" "White"
            Write-Color "`n  [!] Cross-forest migration is complex. Test in a lab first." "Yellow"
            $reportPath = Join-Path $env:TEMP "AD-CrossForest-$(Get-Date -Format yyyyMMdd-HHmmss).txt"
            @"
CROSS-FOREST MIGRATION ASSESSMENT
==================================
Generated: $(Get-Date)
Source: $sourceDomain
Target: $targetDomain
Trust: $(if ($trustExists) {"Exists"} else {"NOT FOUND"})
Source Users: $srccount
Target Users: $tgtcount
"@
            $reportPath | Out-File -FilePath $reportPath -Encoding UTF8
            Write-Color "  [i] Report saved: $reportPath" "Green"
        } catch {
            Write-Color "  [!] AD Cross-Forest Migration prep failed: $_" "Red"
        }
        Pause
    }
}
