# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
# Maddix-AD.ps1 — Active Directory Management Suite LOADER
# This script loads all AD tools from ToolLib/AD/ directory
# For: Windows Server 2012 R2 / 2016 / 2019 / 2022 / 2025
# Run: irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/SRV/Maddix-AD.ps1 | iex

param([switch]$Auto)

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

$Host.UI.RawUI.WindowTitle = "MaddixSuite — Active Directory Manager"
$script:LogPath = "$env:USERPROFILE\Desktop\MaddixSuite\AD_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $script:LogPath -Force -ErrorAction SilentlyContinue | Out-Null

function Write-Color { param([string]$Text, [string]$C = "Gray") Write-Host $Text -ForegroundColor $C }
function Log { param([string]$M, [string]$T="INFO") Add-Content "$($script:LogPath)\AD.log" "[$(Get-Date 'g')] [$T] $M" }

# ─── LOAD AD TOOLS FROM ToolLib ───
$adToolPath = Join-Path $PSScriptRoot "..\ToolLib\AD"
if (-not (Test-Path $adToolPath)) {
    $adToolPath = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "..\ToolLib\AD"
}
$adToolPath = Resolve-Path $adToolPath

$script:ADTools = @()
if (Test-Path $adToolPath) {
    $files = Get-ChildItem $adToolPath -Filter "AD-*.ps1" -ErrorAction SilentlyContinue | Sort-Object Name
    foreach ($file in $files) {
        try {
            . $file.FullName
            if ($script:ToolInfo) {
                $script:ADTools += $script:ToolInfo
                Remove-Variable -Name ToolInfo -Scope Script -ErrorAction SilentlyContinue
            }
        } catch { Write-Color "  [!] Failed to load $($file.Name): $_" "Red" }
    }
}
Write-Color "  Loaded $($script:ADTools.Count) Active Directory tools." "Green"

# ─── HELPERS ───
function Register-Tool {
    param($Config)
    $script:ToolInfo = $Config
}

function Confirm-Step {
    param([string]$Q)
    if ($Auto) { return $true }
    Write-Color "  $Q (Y/N): " "Yellow" -NoNewline
    $r = Read-Host
    return ($r -match '^[Yy]')
}

function Show-Banner {
    Clear-Host
    Write-Color "╔═══════════════════════════════════════════════════════════╗" "Cyan"
    Write-Color "║    4D 61 64 64 69 78 53 75 69 74 65                      ║" "Cyan"
    Write-Color "║    M  a  d  d  i  x  S  u  i  t  e                      ║" "Cyan"
    Write-Color "║    Active Directory Management Suite                      ║" "Cyan"
    Write-Color "║    https://iodeck.ir / https://github.com/...MaddixSuite ║" "DarkGray"
    Write-Color "╚═══════════════════════════════════════════════════════════╝" "Cyan"
}

function Show-Menu {
    Show-Banner
    Write-Color "`n  ─── AD MANAGEMENT MENU ───" "Cyan"
    $lastCat = ""
    foreach ($t in $script:ADTools) {
        Write-Color "  $($t.ID)  $($t.Name)" "White"
    }
    Write-Color "  0.  Back to Main Menu" "Red"
    Write-Color ""
}

# ─── MAIN LOOP ───
while ($true) {
    Show-Menu
    $c = Read-Host "  Select option (ID or number)"
    Write-Color ""
    if ($c -eq '0') { Write-Color "  Returning." "Cyan"; break }
    $tool = $script:ADTools | Where-Object { $_.ID -eq $c } | Select-Object -First 1
    if ($tool) {
        Write-Color "  Executing $($tool.ID): $($tool.Name)..." "Cyan"
        try {
            & $tool.Action
            Write-Color "  [+] $($tool.ID) completed." "Green"
            Log "$($tool.ID) completed" "SUCCESS"
        } catch {
            Write-Color "  [!] $($tool.ID) failed: $_" "Red"
            Log "$($tool.ID) failed: $_" "ERROR"
        }
        Write-Color ""; Pause
    } else {
        Write-Color "  [!] Unknown option: $c" "Red"; Pause
    }
}
