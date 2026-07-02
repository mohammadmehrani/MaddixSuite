Register-Tool @{
    ID          = 'BAK-010'
    Name        = 'Application Settings Backup'
    Category    = 'BAK'
    Description = 'Backup known app configs'
    DangerLevel = 'Safe'
    ConfirmMessage = 'Backup application settings from known locations?'
    ServerOnly  = $false
    ClientOnly  = $false
    Action      = {
        try {
            $backupDir = "C:\AppConfigBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Write-Color "  [+] Backing up app configs to $backupDir" "Cyan"

            $appConfigs = @(
                @{Name='VS Code'; Source="$env:APPDATA\Code\User\settings.json"; DestFile='vscode_settings.json'},
                @{Name='VS Code Keybindings'; Source="$env:APPDATA\Code\User\keybindings.json"; DestFile='vscode_keybindings.json'},
                @{Name='VS Code Extensions'; Source="$env:APPDATA\Code\User\extensions.json"; DestFile='vscode_extensions.json'},
                @{Name='Windows Terminal'; Source="$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"; DestFile='wt_settings.json'},
                @{Name='PowerShell Profile'; Source="$PROFILE.CurrentUserCurrentHost"; DestFile='powershell_profile.ps1'},
                @{Name='Git Config'; Source="$env:USERPROFILE\.gitconfig"; DestFile='gitconfig'},
                @{Name='SSH Config'; Source="$env:USERPROFILE\.ssh\config"; DestFile='ssh_config'},
                @{Name='NuGet Config'; Source="$env:APPDATA\NuGet\NuGet.Config"; DestFile='nuget.config'},
                @{Name='npm Config'; Source="$env:USERPROFILE\.npmrc"; DestFile='npmrc'},
                @{Name='Windows Terminal Tabs'; Source="$env:LOCALAPPDATA\Microsoft\WindowsTerminal\settings.json"; DestFile='wt2_settings.json'}
            )

            $exported = 0
            foreach ($cfg in $appConfigs) {
                if (Test-Path $cfg.Source) {
                    $dest = Join-Path $backupDir $cfg.DestFile
                    Copy-Item -Path $cfg.Source -Destination $dest -Force -ErrorAction SilentlyContinue
                    Write-Color "  [+] $($cfg.Name) backed up" "Green"
                    $exported++
                } else {
                    Write-Color "  [i] $($cfg.Name) not found, skipping" "Gray"
                }
            }

            $extList = Join-Path $backupDir "vscode_extension_list.txt"
            if (Get-Command code -ErrorAction SilentlyContinue) {
                code --list-extensions > $extList 2>$null
                Write-Color "  [+] VS Code extension list saved ($((Get-Content $extList).Count) installed)" "Green"
            }

            Get-ChildItem $env:APPDATA -Filter "*.psd1" -Recurse -Depth 2 -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -eq "ModuleManifest.psd1" } |
                Select-Object -First 5 | ForEach-Object {
                    Copy-Item $_.FullName (Join-Path $backupDir "module_$($_.BaseName).psd1") -Force
                }

            Write-Color "  [+] Backed up $exported app configs" "Green"
        } catch {
            Write-Color "  [!] App config backup failed: $_" "Red"
        }
        Pause
    }
}
