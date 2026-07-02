Register-Tool @{
    ID          = 'DEV-009'
    Name        = 'Windows Terminal Config'
    Category    = 'DEV'
    Description = 'Install Windows Terminal + custom profile'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Install Windows Terminal and apply custom profile?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            Write-Color "  [*] Checking Windows Terminal..." "Cyan"
            $wt = Get-Command wt -ErrorAction SilentlyContinue

            if (-not $wt) {
                Write-Color "  [i] Windows Terminal not installed" "Yellow"
                $choice = Read-Host "  [?] Install Windows Terminal via winget? (y/N)"
                if ($choice -eq 'y') {
                    Write-Color "  [*] Installing Windows Terminal..." "Cyan"
                    winget install Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements
                    Write-Color "  [+] Windows Terminal installed" "Green"
                } else {
                    Pause
                    return
                }
            } else {
                Write-Color "  [+] Windows Terminal is installed" "Green"
            }

            $wtSettingsPaths = @(
                "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
                "$env:LOCALAPPDATA\Microsoft\WindowsTerminal\settings.json"
            )

            $settingsPath = $null
            foreach ($p in $wtSettingsPaths) {
                if (Test-Path $p) {
                    $settingsPath = $p
                    break
                }
            }

            $choice2 = Read-Host "  [?] Apply custom color scheme and profile settings? (y/N)"
            if ($choice2 -eq 'y') {
                if ($settingsPath -and (Test-Path $settingsPath)) {
                    $backupPath = "$settingsPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                    Copy-Item -Path $settingsPath -Destination $backupPath -Force
                    Write-Color "  [+] Existing settings backed up to $backupPath" "Green"
                }

                $customSettings = @"
{
    "profiles": {
        "defaults": {
            "fontFace": "Cascadia Code PL",
            "fontSize": 11,
            "useAcrylic": true,
            "acrylicOpacity": 0.8,
            "cursorShape": "bar",
            "colorScheme": "One Half Dark"
        },
        "list": [
            {
                "name": "PowerShell 7",
                "commandline": "pwsh.exe -NoLogo",
                "source": "Windows.Terminal.PowershellCore",
                "icon": "ms-appx:///ProfileIcons/{574e775e-4feb-4ea5-a3e7-9912b1ee997a}.png"
            },
            {
                "name": "PowerShell 5.1",
                "source": "Windows.Terminal.WindowsPowerShell",
                "hidden": false
            },
            {
                "name": "Command Prompt",
                "source": "Windows.Terminal.Cmd",
                "hidden": false
            }
        ]
    },
    "schemes": [
        {
            "name": "One Half Dark",
            "black": "#383838",
            "red": "#e06c75",
            "green": "#98c379",
            "yellow": "#e5c07b",
            "blue": "#61afef",
            "purple": "#c678dd",
            "cyan": "#56b6c2",
            "white": "#abb2bf",
            "brightBlack": "#5c6370",
            "brightRed": "#e06c75",
            "brightGreen": "#98c379",
            "brightYellow": "#e5c07b",
            "brightBlue": "#61afef",
            "brightPurple": "#c678dd",
            "brightCyan": "#56b6c2",
            "brightWhite": "#ffffff",
            "background": "#282c34",
            "foreground": "#abb2bf"
        }
    ],
    "launchMode": "maximized",
    "copyOnSelect": true,
    "tabWidthMode": "equal"
}
"@
                try {
                    if (-not (Test-Path $wtSettingsPaths[1])) {
                        $dir = Split-Path $wtSettingsPaths[1] -Parent
                        New-Item -ItemType Directory -Path $dir -Force | Out-Null
                    }
                    $customSettings | Out-File $wtSettingsPaths[1] -Encoding utf8 -Force
                    Write-Color "  [+] Custom settings applied to $($wtSettingsPaths[1])" "Green"
                } catch {
                    Write-Color "  [!] Could not write settings: $_" "Yellow"
                    Write-Color "  [i] You can manually apply the One Half Dark scheme" "Cyan"
                }
            }

            Write-Color "  [+] Windows Terminal ready" "Green"
        } catch {
            Write-Color "  [!] Windows Terminal setup failed: $_" "Red"
        }
        Pause
    }
}
