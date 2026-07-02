Register-Tool @{
    ID          = 'AD-054'
    Name        = 'AD WMI Filter for GPO'
    Category    = 'AD'
    Description = 'Create WMI filters for GPO targeting'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Create WMI filters for GPO targeting?'
    ServerOnly  = $true
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "`n  ─── AD WMI FILTER FOR GPO ───" "Cyan"
            Write-Color "  Select a WMI filter template to create:" "White"
            Write-Color "  1. Windows Server only (all versions)" "White"
            Write-Color "  2. Windows Server 2019 or later" "White"
            Write-Color "  3. Windows 10/11 Enterprise only" "White"
            Write-Color "  4. Windows 10/11 with minimum RAM (8 GB)" "White"
            Write-Color "  5. Domain Controller only" "White"
            Write-Color "  6. Exclude specific OS by name" "White"
            Write-Color "  7. Custom WMI query" "White"
            $choice = Read-Host "`nSelect template (1-7)"
            $filterName = ""
            $filterDesc = ""
            $wmiQuery = ""
            switch ($choice) {
                "1" {
                    $filterName = "Windows Server Only"
                    $filterDesc = "Targets all Windows Server editions"
                    $wmiQuery = "SELECT * FROM Win32_OperatingSystem WHERE ProductType = 3"
                }
                "2" {
                    $filterName = "Windows Server 2019+"
                    $filterDesc = "Targets Windows Server 2019, 2022, and later"
                    $wmiQuery = "SELECT * FROM Win32_OperatingSystem WHERE ProductType = 3 AND Version >= '10.0.17763'"
                }
                "3" {
                    $filterName = "Windows 10/11 Enterprise"
                    $filterDesc = "Targets Windows 10/11 Enterprise edition"
                    $wmiQuery = "SELECT * FROM Win32_OperatingSystem WHERE Caption LIKE '%Windows 10%' OR Caption LIKE '%Windows 11%' AND Caption LIKE '%Enterprise%'"
                }
                "4" {
                    $filterName = "Windows with 8GB+ RAM"
                    $filterDesc = "Targets Windows 10/11 with at least 8 GB RAM"
                    $wmiQuery = "SELECT * FROM Win32_ComputerSystem WHERE (Name LIKE '%') AND TotalPhysicalMemory >= 8589934592"
                }
                "5" {
                    $filterName = "Domain Controllers Only"
                    $filterDesc = "Targets only Domain Controllers"
                    $wmiQuery = "SELECT * FROM Win32_OperatingSystem WHERE ProductType = 2"
                }
                "6" {
                    $excludeName = Read-Host "Enter OS name to exclude (e.g., 'Windows 7')"
                    $filterName = "Exclude $excludeName"
                    $filterDesc = "Excludes $excludeName from GPO application"
                    $wmiQuery = "SELECT * FROM Win32_OperatingSystem WHERE NOT Caption LIKE '%$excludeName%'"
                }
                "7" {
                    Write-Color "  Enter your WMI query below:" "Cyan"
                    $wmiQuery = Read-Host "WMI Query"
                    $filterName = Read-Host "Filter Name"
                    $filterDesc = Read-Host "Filter Description (optional)"
                }
                default {
                    Write-Color "  [!] Invalid selection" "Red"
                    return
                }
            }
            if (-not $wmiQuery) { Write-Color "  [!] No query specified" "Yellow"; return }
            Write-Color "`n  ─── WMI Filter Preview ───" "Cyan"
            Write-Color "  Name: $filterName" "White"
            Write-Color "  Description: $filterDesc" "Gray"
            Write-Color "  Query: $wmiQuery" "White"
            $confirm = Read-Host "`nCreate this WMI filter? (y/n)"
            if ($confirm -eq 'y') {
                try {
                    $domain = (Get-ADDomain).DistinguishedName
                    $wmipath = "CN=SOM,CN=WMIPolicy,CN=System,$domain"
                    $filterDn = "CN=$filterName,$wmipath"
                    $existingFilter = Get-ADObject -Filter "Name -eq '$filterName'" -SearchBase $wmipath -ErrorAction SilentlyContinue
                    if ($existingFilter) {
                        Write-Color "  [!] Filter name '$filterName' already exists. Remove it first or choose a different name." "Yellow"
                    } else {
                        $filterObj = New-ADObject -Name $filterName -Type "msWMI-PolicyTemplate" -Path $wmipath -OtherAttributes @{
                            'msWMI-Name' = $filterName;
                            'msWMI-Parm1' = $wmiQuery;
                            'msWMI-Parm2' = "1;3;10;24;29;30;31;32";
                            'msWMI-Encoding' = 1;
                            'description' = $filterDesc
                        } -ErrorAction Stop
                        Write-Color "  [✓] WMI Filter created: $filterName" "Green"
                        Write-Color "  [i] DN: $($filterObj.DistinguishedName)" "Gray"
                        Write-Color "`n  [i] To link a GPO to this filter:" "Cyan"
                        Write-Color "  Get-GPO -Name 'MyGPO' | Set-GPLink -WmiFilter '$filterName'" "Gray"
                    }
                } catch {
                    Write-Color "  [!] Failed to create WMI filter: $_" "Red"
                    Write-Color "`n  [i] Alternative: create manually via GPMC > WMI Filters" "Yellow"
                }
            }
            Write-Color "`n  ─── Existing WMI Filters ───" "Cyan"
            try {
                $existingFilters = Get-ADObject -Filter "ObjectClass -eq 'msWMI-PolicyTemplate'" -SearchBase $wmipath -Properties msWMI-Name,msWMI-Parm1,description -ErrorAction SilentlyContinue
                if ($existingFilters) {
                    foreach ($f in $existingFilters) {
                        Write-Color "  $($f.msWMI-Name): $($f.description)" "Gray"
                    }
                } else {
                    Write-Color "  [i] No existing WMI filters found" "Gray"
                }
            } catch {}
        } catch {
            Write-Color "  [!] AD WMI Filter creation failed: $_" "Red"
        }
        Pause
    }
}
