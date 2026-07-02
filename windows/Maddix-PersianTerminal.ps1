#Requires -RunAsAdministrator
# Maddix-PersianTerminal.ps1 — Persian/Farsi Encoding & Font Fix for Terminal
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# GitHub: https://github.com/mohammadmehrani/MaddixSuite
# Run: irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Maddix-PersianTerminal.ps1 | iex

param(
    [switch]$LinuxMode,
    [switch]$Auto
)

$Host.UI.RawUI.WindowTitle = "MaddixSuite — Persian Terminal Fix"

function Write-Color { param([string]$Text, [string]$Color = "White") Write-Host $Text -ForegroundColor $Color }
function Confirm-Step {
    param([string]$Title, [string]$Desc)
    if ($Auto) { return $true }
    Write-Color "`n  $Title" "Yellow"; Write-Color "  $Desc" "DarkGray"
    $r = Read-Host "  Continue? (Y/N)"
    return ($r -match '^[Yy]')
}

function Test-Admin {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
    }
}

# ===========================================================================
# WINDOWS MODE
# ===========================================================================
function Fix-WindowsTerminal {
    Write-Color "  [*] Windows Persian Terminal Fix" "Cyan"

    # 1. Set code page to UTF-8
    if (Confirm-Step "Set UTF-8 Code Page" "Set console to UTF-8 (chcp 65001) for Persian character support.") {
        try {
            chcp 65001 | Out-Null
            # Make persistent via registry
            $regPath = "HKCU:\Software\Microsoft\Command Processor"
            if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
            Set-ItemProperty -Path $regPath -Name "AutoRun" -Value "chcp 65001>NUL" -ErrorAction SilentlyContinue
            Write-Color "    [+] UTF-8 code page set (65001)" "Green"
        } catch { Write-Color "    [!] Failed: $_" "Red" }
    }

    # 2. Install Persian-capable font
    if (Confirm-Step "Install Persian Fonts" "Download and install Vazir Code (Persian programming font) + set console font.") {
        try {
            $fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
            New-Item -ItemType Directory -Path $fontDir -Force | Out-Null

            # Download Vazir Code font
            $vazirUrl = "https://github.com/rastikerdar/vazir-code-font/releases/download/v1.1.2/Vazir-Code-1.1.2.zip"
            $zipPath = "$env:TEMP\vazir.zip"
            Write-Color "    Downloading Vazir Code font..." "Gray"
            try {
                Invoke-WebRequest -Uri $vazirUrl -OutFile $zipPath -ErrorAction Stop
                Expand-Archive -Path $zipPath -DestinationPath "$env:TEMP\vazir-font" -Force
                Get-ChildItem "$env:TEMP\vazir-font" -Filter "*.ttf" | ForEach-Object {
                    Copy-Item $_.FullName "$fontDir\$($_.Name)" -Force
                    Write-Color "    Installed: $($_.Name)" "Green"
                }
                # Register font
                $shell = New-Object -ComObject Shell.Application
                $fonts = $shell.Namespace(0x14)
                Get-ChildItem "$fontDir\*.ttf" | ForEach-Object {
                    $fonts.CopyHere($_.FullName, 0x10) | Out-Null
                }
                Write-Color "    [+] Vazir Code font installed" "Green"
            } catch {
                Write-Color "    [!] Download failed: $_" "Yellow"
                Write-Color "    Manual: https://github.com/rastikerdar/vazir-code-font" "Gray"
            }
        } catch { Write-Color "    [!] Error: $_" "Red" }
    }

    # 3. Configure PowerShell profile for Persian
    if (Confirm-Step "Configure PowerShell Profile" "Add Persian support to PowerShell profile (UTF-8, font, prompt).")) {
        try {
            $profileDir = Split-Path $PROFILE -Parent
            New-Object -ItemType Directory -Path $profileDir -Force | Out-Null
            $utf8Block = @"
`$OutputEncoding = [System.Text.UTF8Encoding]::new(`$true)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new(`$true)
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new(`$true)
chcp 65001 >`$null
"@
            Add-Content -Path $PROFILE -Value "`n# Persian Terminal Support" -ErrorAction SilentlyContinue
            Add-Content -Path $PROFILE -Value $utf8Block -ErrorAction SilentlyContinue
            Write-Color "    [+] PowerShell profile updated" "Green"
        } catch { Write-Color "    [!] Failed: $_" "Red" }
    }

    # 4. Set Windows Terminal settings if available
    if (Confirm-Step "Configure Windows Terminal" "Set Cascadia Code as font in Windows Terminal for Persian support.") {
        try {
            $wtSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
            $wtPreview = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
            $sources = @($wtSettings, $wtPreview)

            foreach ($s in $sources) {
                if (Test-Path $s) {
                    $config = Get-Content $s -Raw | ConvertFrom-Json
                    if ($config.profiles -and $config.profiles.list) {
                        foreach ($p in $config.profiles.list) {
                            $p.font | Add-Member -NotePropertyName "face" -NotePropertyValue "Cascadia Code" -Force -ErrorAction SilentlyContinue
                        }
                        $config | ConvertTo-Json -Depth 10 | Set-Content $s -Force
                        Write-Color "    [+] Windows Terminal font set to Cascadia Code" "Green"
                    }
                }
            }
        } catch { Write-Color "    [!] Skipped (may not have Windows Terminal)" "Gray" }
    }

    # 5. Enable Unicode support in registry
    if (Confirm-Step "Enable Unicode UTF-8 System-Wide" "Set system locale to UTF-8 (Beta). May affect legacy apps.") {
        try {
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage"
            Set-ItemProperty -Path $regPath -Name "ACP" -Value "65001" -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $regPath -Name "OEMCP" -Value "65001" -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $regPath -Name "MACCP" -Value "65001" -ErrorAction SilentlyContinue
            Write-Color "    [+] System codepage set to UTF-8 (reboot may be required)" "Green"
        } catch { Write-Color "    [!] Failed: $_" "Red" }
    }

    Write-Color "  [+] Windows Persian Terminal setup complete" "Green"
    Write-Color "  [i] Restart your terminal for changes to take effect" "Yellow"
}

# ===========================================================================
# LINUX MODE
# ===========================================================================
function Fix-LinuxTerminal {
    Write-Color "  [*] Linux Persian Terminal Fix" "Cyan"
    Write-Color "  [i] Detecting distro..." "Gray"

    $osRelease = ""
    if (Test-Path "/etc/os-release") { $osRelease = Get-Content "/etc/os-release" -Raw }

    $distro = if ($osRelease -match '(?i)ID_LIKE=([\w]+)') { $matches[1] }
              elseif ($osRelease -match '(?i)ID=([\w]+)') { $matches[1] }
              else { "unknown" }

    $pkgMgr = if ($distro -match "debian|ubuntu|mint") { "apt" }
              elseif ($distro -match "fedora|rhel|centos") { "dnf" }
              elseif ($distro -match "arch|manjaro") { "pacman" }
              elseif ($distro -match "suse") { "zypper" }
              else { "unknown" }

    Write-Color "    Distro: $distro | Package Manager: $pkgMgr" "Gray"

    # 1. Check locale
    if (Confirm-Step "Install Persian Locale" "Generate and set Persian locale (fa_IR.UTF-8) for proper encoding.") {
        try {
            switch ($pkgMgr) {
                "apt" {
                    sudo locale-gen fa_IR.UTF-8 2>/dev/null
                    sudo apt-get install -y locales 2>/dev/null
                }
                "dnf" { localedef -i fa_IR -f UTF-8 fa_IR.UTF-8 2>/dev/null }
                "pacman" { sudo pacman -S --noconfirm glibc-locales 2>/dev/null }
            }
            sudo update-locale LANG=fa_IR.UTF-8 2>/dev/null
            Write-Color "    [+] Persian locale installed. Run: 'export LANG=fa_IR.UTF-8'" "Green"
        } catch { Write-Color "    [!] Failed: $_" "Red" }
    }

    # 2. Install Persian fonts
    if (Confirm-Step "Install Persian Fonts" "Install Persian/CJK fonts for terminal and GUI.") {
        try {
            $fontPkgs = @()
            switch ($pkgMgr) {
                "apt" { $fontPkgs = @("fonts-farsi", "fonts-noto", "fonts-noto-color-emoji", "fonts-vazir", "xfonts-base") }
                "dnf" { $fontPkgs = @("vazir-fonts", "google-noto-fonts-common", "xorg-x11-fonts-base") }
                "pacman" { $fontPkgs = @("vazir-fonts", "noto-fonts", "xorg-fonts-100dpi") }
                "zypper" { $fontPkgs = @("vazir-fonts", "google-noto-fonts") }
            }
            if ($fontPkgs.Count -gt 0) {
                $pkgCmd = switch ($pkgMgr) {
                    "apt" { "sudo apt-get install -y $($fontPkgs -join ' ')" }
                    "dnf" { "sudo dnf install -y $($fontPkgs -join ' ')" }
                    "pacman" { "sudo pacman -S --noconfirm $($fontPkgs -join ' ')" }
                    "zypper" { "sudo zypper install -y $($fontPkgs -join ' ')" }
                }
                Invoke-Expression $pkgCmd 2>$null
                Write-Color "    [+] Persian fonts installed" "Green"
            }
        } catch { Write-Color "    [!] Failed: $_" "Red" }
    }

    # 3. Configure input method
    if (Confirm-Step "Install Persian Input Method" "Install Fcitx + Persian input for typing Farsi in terminal.") {
        try {
            $imPkgs = switch ($pkgMgr) {
                "apt" { @("fcitx", "fcitx-fa", "fcitx-ui-classic") }
                "dnf" { @("fcitx", "fcitx-m17n") }
                "pacman" { @("fcitx", "fcitx-qt5", "fcitx-qt6", "fcitx-configtool") }
                default { @("fcitx") }
            }
            if ($imPkgs.Count -gt 0) {
                $pkgCmd = switch ($pkgMgr) {
                    "apt" { "sudo apt-get install -y $($imPkgs -join ' ')" }
                    "dnf" { "sudo dnf install -y $($imPkgs -join ' ')" }
                    "pacman" { "sudo pacman -S --noconfirm $($imPkgs -join ' ')" }
                    "zypper" { "sudo zypper install -y $($imPkgs -join ' ')" }
                }
                Invoke-Expression $pkgCmd 2>$null
                # Configure fcitx
                $fcitxEnv = @'
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export LANG=fa_IR.UTF-8
'@
                Add-Content -Path "$env:HOME/.xprofile" -Value $fcitxEnv -ErrorAction SilentlyContinue
                Add-Content -Path "$env:HOME/.bashrc" -Value "`n# Persian input" -ErrorAction SilentlyContinue
                Add-Content -Path "$env:HOME/.bashrc" -Value $fcitxEnv -ErrorAction SilentlyContinue
                Write-Color "    [+] Fcitx + Persian input installed" "Green"
            }
        } catch { Write-Color "    [!] Failed: $_" "Red" }
    }

    Write-Color "  [+] Linux Persian Terminal setup complete" "Green"
}

# ===========================================================================
# MAIN
# ===========================================================================
Clear-Host
Write-Color "╔═══════════════════════════════════════════════════════════╗" "Cyan"
Write-Color "║      MaddixSuite — Persian Terminal Encoding Fix          ║" "Cyan"
Write-Color "╚═══════════════════════════════════════════════════════════╝" "Cyan"
Write-Color "  GitHub: https://github.com/mohammadmehrani/MaddixSuite" "DarkGray"
Write-Color "  Website: https://iodeck.ir" "DarkGray"
Write-Color ""

if ($LinuxMode -or $IsLinux -or (-not $IsWindows -and [Environment]::OSVersion.Platform -eq [PlatformID]::Unix)) {
    Fix-LinuxTerminal
} elseif ($IsWindows -or [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
    Test-Admin
    Fix-WindowsTerminal
} else {
    Write-Color "  [!] Unsupported platform" "Red"
}

Write-Color "`n  Done. Visit https://iodeck.ir for more tools." "DarkGray"
