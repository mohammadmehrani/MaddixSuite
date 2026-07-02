Register-Tool @{
    ID          = 'NET-003'
    Name        = 'WiFi Manager'
    Category    = 'NET'
    Description = 'Scan networks, export WiFi profiles, manage saved networks'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Read-only WiFi scan and profile export.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── WIFI MANAGER ───" "Cyan"
        Write-Color "  1. Scan WiFi Networks" "White"
        Write-Color "  2. Show Current Connection" "White"
        Write-Color "  3. Export All WiFi Profiles" "White"
        Write-Color "  4. List Saved Profiles" "White"
        Write-Color "  0. Back" "Red"
        $c = Read-Host "> "
        switch ($c) {
            "1" {
                $netsh = netsh wlan show networks mode=bssid
                Write-Color "$netsh" "Gray"
            }
            "2" {
                $iface = netsh wlan show interfaces
                Write-Color "$iface" "Gray"
            }
            "3" {
                $profiles = netsh wlan show profiles | Select-String ":\s+(.+)$"
                $exportDir = "$env:USERPROFILE\Desktop\MaddixSuite\WiFi_Profiles"
                New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
                foreach ($p in $profiles) {
                    $name = $p.Matches.Groups[1].Value.Trim()
                    $file = "$exportDir\$name.xml"
                    netsh wlan export profile name="$name" folder="$exportDir" key=clear
                    Write-Color "    Exported: $name -> $file" "Gray"
                }
                Write-Color "  [+] All profiles exported to $exportDir" "Green"
            }
            "4" { netsh wlan show profiles | Write-Color "Gray" }
        }
        Pause
    }
}
