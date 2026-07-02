Register-Tool @{
    ID          = 'AD-021'
    Name        = 'Failover Cluster Setup'
    Category    = 'AD'
    Description = 'Install Failover-Clustering, validate/test cluster'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Install Failover-Clustering feature and optionally validate cluster?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking Failover Clustering status..." "Cyan"
            $fc = Get-WindowsFeature -Name Failover-Clustering -ErrorAction SilentlyContinue

            if ($fc -and $fc.Installed) {
                Write-Color "  [+] Failover Clustering is installed" "Green"
                $choice = Read-Host "  [?] Run Cluster Validation tests? (y/N)"
                if ($choice -eq 'y') {
                    $nodesInput = Read-Host "  Node names (comma-separated)"
                    if ($nodesInput) {
                        $nodes = $nodesInput.Split(',') | ForEach-Object { $_.Trim() }
                        Write-Color "  [*] Running Cluster Validation..." "Cyan"
                        Test-Cluster -Node $nodes -Include "Storage", "Network", "System Configuration"
                        Write-Color "  [+] Validation complete" "Green"
                    }
                }
            } else {
                Write-Color "  [i] Failover Clustering is not installed" "Yellow"
                $choice = Read-Host "  [?] Install Failover Clustering feature? (y/N)"
                if ($choice -eq 'y') {
                    Write-Color "  [*] Installing Failover Clustering..." "Cyan"
                    Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
                    Write-Color "  [+] Failover Clustering installed" "Green"
                    Write-Color "  [i] Validate cluster: Test-Cluster -Node Node1,Node2" "Gray"
                }
            }
        } catch {
            Write-Color "  [!] Cluster setup failed: $_" "Red"
        }
        Pause
    }
}
