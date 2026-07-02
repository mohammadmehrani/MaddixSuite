Register-Tool @{
    ID          = 'OPT-010'
    Name        = 'Service Optimizer'
    Category    = 'OPT'
    Description = 'Disable unnecessary services for performance'
    DangerLevel = 'Moderate'
    ConfirmMessage = 'Review and disable unnecessary Windows services for performance'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Service Optimizer" "Green"

            $servicesToReview = @(
                @{Name='XblAuthManager'; Display='Xbox Live Auth Manager'},
                @{Name='XblGameSave'; Display='Xbox Live Game Save'},
                @{Name='XboxNetApiSvc'; Display='Xbox Live Networking'},
                @{Name='XboxGipSvc'; Display='Xbox Accessory Management'},
                @{Name='WdScannerSvc'; Display='Windows Defender Scanner (if 3rd party AV)'},
                @{Name='WMPNetworkSvc'; Display='Windows Media Player Network Sharing'},
                @{Name='WSearch'; Display='Windows Search'},
                @{Name='WerSvc'; Display='Windows Error Reporting'},
                @{Name='wcncsvc'; Display='Windows Connect Now'},
                @{Name='TabletInputService'; Display='Touch Keyboard and Handwriting'},
                @{Name='PcaSvc'; Display='Program Compatibility Assistant'},
                @{Name='MapsBroker'; Display='Downloaded Maps Manager'},
                @{Name='lfsvc'; Display='Geolocation Service'},
                @{Name='iphlpsvc'; Display='IP Helper (IPv6 tunnel)'},
                @{Name='Fax'; Display='Fax Service'},
                @{Name='FontCache3.0.0.0'; Display='Windows Font Cache 3.0'},
                @{Name='CscService'; Display='Offline Files'},
                @{Name='Browser'; Display='Computer Browser'},
                @{Name='BDESVC'; Display='BitLocker Drive Encryption Service'},
                @{Name='ALG'; Display='Application Layer Gateway'},
                @{Name='SharedAccess'; Display='Internet Connection Sharing'},
                @{Name='RemoteRegistry'; Display='Remote Registry'},
                @{Name='RemoteAccess'; Display='Routing and Remote Access'},
                @{Name='lpdsvc'; Display='Line Printer Daemon'},
                @{Name='Spooler'; Display='Print Spooler (if no printer)'},
                @{Name='SessionEnv'; Display='Remote Desktop Configuration'},
                @{Name='TermService'; Display='Remote Desktop Services'},
                @{Name='UmRdpService'; Display='Remote Desktop USB Redirector'},
                @{Name='RpcLocator'; Display='Remote Procedure Call Locator'},
                @{Name='WbioSrvc'; Display='Windows Biometric Service'},
                @{Name='WlanSvc'; Display='WLAN AutoConfig (if no WiFi)'},
                @{Name='wlidsvc'; Display='Microsoft Account Sign-in Assistant'},
                @{Name='wudfsvc'; Display='Windows Update (consider disable only if managed)'}
            )

            Write-Color "  [!] The following services can be disabled on most systems." "Yellow"
            Write-Color "  [!] Only disable if you do not use the related feature." "Yellow"

            foreach ($svc in $servicesToReview) {
                try {
                    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
                    if ($service -and $service.StartType -ne 'Disabled' -and $service.StartType -ne 4) {
                        Write-Color "`n  [*] $($svc.Display) ($($svc.Name))" "Cyan"
                        Write-Color "      Current: $($service.StartType)" "Cyan"
                        $choice = Read-Host "      Disable? (y/N/s=skip all)"
                        if ($choice -eq 'y') {
                            Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
                            Set-Service -Name $svc.Name -StartupType Disabled
                            Write-Color "      -> Disabled" "Green"
                        } elseif ($choice -eq 's') {
                            Write-Color "  [+] Skipping remaining services" "Green"
                            break
                        }
                    }
                } catch {}
            }

            Write-Color "`n  [+] Service optimization completed" "Green"
            Write-Color "  [!] Some changes may require a reboot" "Yellow"
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
