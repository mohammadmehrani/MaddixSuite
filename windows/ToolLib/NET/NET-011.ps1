Register-Tool @{
    ID          = 'NET-011'
    Name        = 'MAC Address Changer'
    Category    = 'NET'
    Description = 'View and change network adapter MAC address'
    DangerLevel = 'Caution'
    ConfirmMessage = 'Temporarily changes the MAC address of a network adapter.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── MAC ADDRESS CHANGER ───" "Cyan"
        try {
            $adapters = Get-NetAdapter -Physical | Where-Object Status -eq Up
            if (-not $adapters) {
                Write-Color "  [!] No active physical adapters found." "Red"
                Pause
                return
            }
            $i = 1
            $adapterList = @()
            foreach ($a in $adapters) {
                $mac = ($a.MacAddress -replace '-', ':' )
                Write-Color "  $i. $($a.Name) - $mac" "White"
                $adapterList += $a
                $i++
            }
            $sel = Read-Host "`n  Select adapter (number)"
            $adapter = $adapterList[[int]$sel - 1]
            Write-Color "`n  1. View current MAC" "White"
            Write-Color "  2. Change MAC address" "White"
            Write-Color "  3. Reset to original (registry restore)" "White"
            Write-Color "  0. Back" "Red"
            $c = Read-Host "`n  Select option"
            switch ($c) {
                "1" {
                    $mac = $adapter.MacAddress
                    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
                    $subKeys = Get-ChildItem $regPath -ErrorAction SilentlyContinue
                    Write-Color "  Current MAC: $($mac -replace '-',':')" "Green"
                    foreach ($sk in $subKeys) {
                        $driverDesc = $sk.GetValue("DriverDesc")
                        if ($driverDesc -eq $adapter.InterfaceDescription) {
                            $orig = $sk.GetValue("OriginalNetworkAddress")
                            $cur = $sk.GetValue("NetworkAddress")
                            if ($orig) { Write-Color "  Original MAC (registry): $orig" "Gray" }
                            if ($cur) { Write-Color "  Current (registry): $cur" "Gray" }
                        }
                    }
                }
                "2" {
                    $newMac = Read-Host "  Enter new MAC (e.g. 001122334455 or 00-11-22-33-44-55)"
                    $cleanMac = $newMac -replace '[^0-9a-fA-F]', ''
                    if ($cleanMac.Length -ne 12) {
                        Write-Color "  [!] Invalid MAC address format." "Red"
                    } else {
                        try {
                            Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
                            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
                            $subKeys = Get-ChildItem $regPath
                            foreach ($sk in $subKeys) {
                                $driverDesc = $sk.GetValue("DriverDesc")
                                if ($driverDesc -eq $adapter.InterfaceDescription) {
                                    Set-ItemProperty -Path $sk.PSPath -Name "NetworkAddress" -Value $cleanMac -ErrorAction Stop
                                    Write-Color "  [+] MAC set to $($cleanMac -replace '(.{2})','$1:' -replace ':$')" "Green"
                                }
                            }
                            Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
                            Write-Color "  [+] Adapter re-enabled. You may need to renew your IP." "Yellow"
                        } catch {
                            Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
                            Write-Color "  [!] Failed to change MAC: $_" "Red"
                        }
                    }
                }
                "3" {
                    try {
                        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
                        $subKeys = Get-ChildItem $regPath
                        Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
                        foreach ($sk in $subKeys) {
                            $driverDesc = $sk.GetValue("DriverDesc")
                            if ($driverDesc -eq $adapter.InterfaceDescription) {
                                Remove-ItemProperty -Path $sk.PSPath -Name "NetworkAddress" -ErrorAction SilentlyContinue
                                Write-Color "  [+] MAC reset to original hardware address" "Green"
                            }
                        }
                        Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
                    } catch { Write-Color "  [!] Failed to reset MAC: $_" "Red" }
                }
            }
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
