Register-Tool @{
    ID          = 'OPT-006'
    Name        = 'Visual Effects Tuner'
    Category    = 'OPT'
    Description = 'Adjust visual effects for performance'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Adjust Windows visual effects for performance'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [+] Visual Effects Configuration:" "Green"

            Write-Color "`n  [?] Select visual performance level:" "Yellow"
            Write-Color "      1 - Best Appearance (all effects on)" "Cyan"
            Write-Color "      2 - Best Performance (all effects off)" "Cyan"
            Write-Color "      3 - Custom (choose)" "Cyan"
            $choice = Read-Host "  [+] Enter choice (1-3)"

            $regPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
            if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }

            switch ($choice) {
                "1" {
                    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'VisualFXSetting' -Value 0
                    Write-Color "  [+] Best Appearance enabled" "Green"
                }
                "2" {
                    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'VisualFXSetting' -Value 2
                    Write-Color "  [+] Best Performance enabled" "Green"
                    $animations = @(
                        'TaskbarAnimations',
                        'TaskbarWordWrap',
                        'EnableLivePreview',
                        'EnableWindowBorder',
                        'EnableAeroPeek',
                        'EnableGlass',
                        'EnableWindowColorization'
                    )
                    foreach ($anim in $animations) {
                        Set-ItemProperty -Path $regPath -Name $anim -Value 0 -ErrorAction SilentlyContinue
                    }
                }
                "3" {
                    Write-Color "`n  [*] Toggle individual effects:" "Yellow"
                    $effects = @(
                        @{Name='Animate windows when minimizing/maximizing';Key='MinAnimate'},
                        @{Name='Show shadows under windows';Key='ComboBoxAnimation'},
                        @{Name='Show shadows under mouse';Key='CursorShadow'},
                        @{Name='Show thumbnails instead of icons';Key='ListviewAlphaSelect'},
                        @{Name='Smooth edges of screen fonts';Key='SmoothScroll'},
                        @{Name='Use drop shadows for icons';Key='WindowShadow'},
                        @{Name='Show translucent selection rectangle';Key='ListviewShadow'}
                    )
                    foreach ($effect in $effects) {
                        $current = Get-ItemProperty -Path $regPath -Name $effect.Key -ErrorAction SilentlyContinue
                        $state = if ($current -and $current.($effect.Key) -eq 0) { 'Off' } else { 'On' }
                        $toggle = Read-Host "  $($effect.Name) [$state] - Toggle? (y/N)"
                        if ($toggle -eq 'y') {
                            $newVal = if ($state -eq 'On') { 0 } else { 1 }
                            Set-ItemProperty -Path $regPath -Name $effect.Key -Value $newVal
                            Write-Color "    -> Toggled" "Green"
                        }
                    }
                }
            }

            Write-Color "`n  [*] Enabling/disabling animations may require logoff/restart" "Yellow"
        } catch {
            Write-Color "  [!] Error: $_" "Red"
        }
        Pause
    }
}
