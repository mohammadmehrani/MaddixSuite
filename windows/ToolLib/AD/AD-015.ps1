Register-Tool @{
    ID          = 'AD-015'
    Name        = 'AD Sites & Services'
    Category    = 'AD'
    Description = 'List AD sites and subnets, create new site with subnet'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'List AD sites/subnets and optionally create a new site'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "`n  ─── AD SITES ───" "Cyan"
            Get-ADReplicationSite -Filter * | Format-Table Name, SiteObjectBL, Location -AutoSize
            Write-Color "`n  ─── AD SUBNETS ───" "Cyan"
            Get-ADReplicationSubnet -Filter * | Format-Table Name, Site, Location -AutoSize

            $create = Read-Host "`n  Create new site? (Y/N)"
            if ($create -match '^[Yy]') {
                $s = Read-Host "  Site name"
                New-ADReplicationSite -Name $s
                $sub = Read-Host "  Subnet (e.g., 192.168.1.0/24)"
                New-ADReplicationSubnet -Name $sub -Site $s
                Write-Color "  [+] Site '$s' created with subnet $sub" "Green"
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
