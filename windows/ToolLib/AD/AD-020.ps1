Register-Tool @{
    ID          = 'AD-020'
    Name        = 'DFS Namespace & Replication'
    Category    = 'AD'
    Description = 'Install DFS management tools for Namespace and Replication'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Install DFS Management, Namespace, and Replication tools'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "`n  ─── DFS NAMESPACE & REPLICATION ───" "Cyan"
            $dfs = Get-WindowsFeature FS-DFS-Management, FS-DFS, FS-DFS-Replication -ErrorAction SilentlyContinue
            if (-not $dfs.Installed) {
                $install = Read-Host "  Install DFS Management tools? (Y/N)"
                if ($install -match '^[Yy]') {
                    Install-WindowsFeature FS-DFS-Management, FS-DFS, FS-DFS-Replication -IncludeManagementTools | Out-Null
                    Write-Color "  [+] DFS tools installed." "Green"
                }
            } else {
                Write-Color "  DFS tools are already installed." "Green"
            }
            Write-Color "  Open: dfsmgmt.msc for management GUI" "Gray"
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
