Register-Tool @{
    ID          = 'NET-009'
    Name        = 'Proxy Config Manager'
    Category    = 'NET'
    Description = 'Set/system proxy settings (WinINET)'
    DangerLevel = 'Caution'
    ConfirmMessage = 'Modifies Windows system proxy settings.'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        Write-Color "  ─── PROXY CONFIG MANAGER ───" "Cyan"
        try {
            $current = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable, ProxyServer, ProxyOverride -ErrorAction SilentlyContinue
            $status = if ($current.ProxyEnable -eq 1) { "Enabled" } else { "Disabled" }
            Write-Color "  Current proxy status: $status" "White"
            if ($current.ProxyEnable -eq 1) {
                Write-Color "  Server: $($current.ProxyServer)" "Gray"
                Write-Color "  Override: $($current.ProxyOverride)" "Gray"
            }
        } catch { Write-Color "  Unable to read proxy settings" "Yellow" }
        Write-Color "`n  1. Enable proxy" "White"
        Write-Color "  2. Disable proxy" "White"
        Write-Color "  3. Set custom proxy" "White"
        Write-Color "  4. Show current settings" "White"
        Write-Color "  0. Back" "Red"
        $c = Read-Host "`n  Select option"
        switch ($c) {
            "1" {
                try {
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1
                    Write-Color "  [+] Proxy enabled" "Green"
                } catch { Write-Color "  [!] Failed: $_" "Red" }
            }
            "2" {
                try {
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 0
                    Write-Color "  [+] Proxy disabled" "Green"
                } catch { Write-Color "  [!] Failed: $_" "Red" }
            }
            "3" {
                try {
                    $addr = Read-Host "  Proxy address (e.g. 192.168.1.1:8080)"
                    $bypass = Read-Host "  Bypass list (e.g. *.local;192.168.*)"
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value $addr
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride -Value $bypass
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1
                    Write-Color "  [+] Proxy set to $addr" "Green"
                } catch { Write-Color "  [!] Failed: $_" "Red" }
            }
            "4" {
                try {
                    $reg = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
                    Write-Color "  Proxy Enabled: $(if ($reg.ProxyEnable -eq 1) { 'Yes' } else { 'No' })" "White"
                    Write-Color "  Proxy Server: $($reg.ProxyServer)" "White"
                    Write-Color "  Proxy Override: $($reg.ProxyOverride)" "White"
                    $ieProxy = [System.Net.WebRequest]::DefaultWebProxy
                    Write-Color "  System Proxy: $($ieProxy.GetProxy('http://example.com'))" "Gray"
                } catch { Write-Color "  [!] Error reading settings: $_" "Red" }
            }
        }
        Pause
    }
}
