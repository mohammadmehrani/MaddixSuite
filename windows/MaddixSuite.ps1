# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
# Run: irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/MaddixSuite.ps1 | iex

param(
    [switch]$Auto
)

#Requires -Version 5.1

#region AUTO-ELEVATE
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    $arg = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($MyInvocation.InvocationName -eq '.') { $arg = "-NoProfile -ExecutionPolicy Bypass -Command `"& `'$PSCommandPath`'`"" }
    Start-Process powershell -Verb RunAs -ArgumentList $arg; exit
}
#endregion

$Host.UI.RawUI.WindowTitle = "MaddixSuite — Ultimate Windows Toolkit"

#region GLOBALS
$script:StartTime = Get-Date
$script:BasePath = "$env:USERPROFILE\Desktop\MaddixSuite"
$script:LogPath = "$script:BasePath\Reports\MaddixSuite_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$script:ReportLog = "$script:LogPath\Report.txt"
$script:ToolLibPath = Join-Path $PSScriptRoot "ToolLib"
if (-not (Test-Path $script:ToolLibPath)) { $script:ToolLibPath = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "ToolLib" }
$script:AllTools = @()
$script:IsServer = $false
$script:LastAction = $null
$script:PendingReboot = $false

New-Item -ItemType Directory -Path $script:LogPath -Force -ErrorAction SilentlyContinue | Out-Null
#endregion

#region HELPERS
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [$Type] $Message"
    Add-Content -Path $script:ReportLog -Value $line -ErrorAction SilentlyContinue
    switch ($Type) {
        "ERROR"   { Write-Host $line -ForegroundColor Red }
        "WARNING" { Write-Host $line -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $line -ForegroundColor Green }
        "ACTION"  { Write-Host $line -ForegroundColor Magenta }
        default   { Write-Host $line -ForegroundColor Cyan }
    }
}

function Write-Color {
    param([string]$Text, [string]$Color = "Gray", [switch]$NoNewline)
    if ($NoNewline) { Write-Host $Text -ForegroundColor $Color -NoNewline } else { Write-Host $Text -ForegroundColor $Color }
}

function Get-ConsoleWidth { try { return $Host.UI.RawUI.WindowSize.Width } catch { return 120 } }
#endregion

#region SYSTEM DETECTION
function Get-SystemInfo {
    $info = @{}
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        $ram = Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction SilentlyContinue
        $gpu = Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
        $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
        $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue

        $osName = $os.Caption
        $isServer = $osName -match "Server"
        $edition = if ($isServer) { "Server" } else { "Client" }

        $info.OSName = $osName
        $info.OSVersion = $os.Version
        $info.OSBuild = $os.BuildNumber
        $info.OSEdition = $edition
        $info.IsServer = $isServer
        $info.CPUModel = $cpu.Name
        $info.CPUCores = $cpu.NumberOfCores
        $info.CPUThreads = $cpu.NumberOfLogicalProcessors
        $ramTotal = ($ram | Measure-Object -Property Capacity -Sum).Sum
        $info.RAMTotal = [math]::Round($ramTotal / 1GB, 2)
        $osFree = $os.FreePhysicalMemory * 1KB
        $info.RAMFree = [math]::Round($osFree / 1GB, 2)
        if ($disk) {
            $info.DiskTotal = [math]::Round($disk.Size / 1GB, 2)
            $info.DiskFree = [math]::Round($disk.FreeSpace / 1GB, 2)
        }
        if ($gpu) {
            $info.GPUName = $gpu.Name
            $info.GPUVRAM = if ($gpu.AdapterRAM) { "$([math]::Round($gpu.AdapterRAM / 1MB, 0)) MB" } else { "Unknown" }
        }
        $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" }
        $adapter = $adapters | Select-Object -First 1
        if ($adapter) {
            $ipInfo = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            $dnsInfo = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            $mac = $adapter.MacAddress
            $info.IP = if ($ipInfo) { $ipInfo.IPAddress } else { "N/A" }
            $info.MAC = if ($mac) { $mac } else { "N/A" }
            $info.DNS = if ($dnsInfo -and $dnsInfo.ServerAddresses) { ($dnsInfo.ServerAddresses -join ", ") } else { "N/A" }
        }
        $uptime = (Get-Date) - $os.LastBootUpTime
        $info.Uptime = "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
        $info.NETVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -Name Release -ErrorAction SilentlyContinue).Release
        if ($info.NETVersion) {
            $info.NETVersion = switch ($info.NETVersion) {
                {$_ -ge 528040} {"4.8 or later"}; {$_ -ge 461808} {"4.7.2"}; {$_ -ge 461308} {"4.7.1"}
                {$_ -ge 460798} {"4.7"}; {$_ -ge 394802} {"4.6.2"}; {$_ -ge 394254} {"4.6.1"}
                {$_ -ge 393295} {"4.6"}; default {"4.x"}
            }
        } else { $info.NETVersion = "Unknown" }
        $info.PSVersion = $PSVersionTable.PSVersion.ToString()
        $info.Serial = $bios.SerialNumber
    } catch { $info.OSName = "Unknown"; $info.OSEdition = "Unknown" }
    $script:IsServer = $info.IsServer
    return $info
}

function Show-SystemInfo {
    $si = Get-SystemInfo
    Write-Color "╔══════════════════════════════════════════════════════════════════════════╗" "Cyan"
    Write-Color "║                         SYSTEM INFORMATION                              ║" "Cyan"
    Write-Color "╚══════════════════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Color "  OS:      $($si.OSName) (Build $($si.OSBuild))" "White"
    Write-Color "  Edition: $($si.OSEdition) | Version: $($si.OSVersion)" "Gray"
    Write-Color "  CPU:     $($si.CPUModel)" "White"
    Write-Color "           Cores: $($si.CPUCores) | Threads: $($si.CPUThreads)" "Gray"
    Write-Color "  RAM:     $($si.RAMTotal) GB total | $($si.RAMFree) GB free" "White"
    Write-Color "  Disk C:  $($si.DiskTotal) GB total | $($si.DiskFree) GB free" "White"
    Write-Color "  GPU:     $($si.GPUName) ($($si.GPUVRAM))" "White"
    Write-Color "  Network: IP: $($si.IP) | MAC: $($si.MAC)" "White"
    Write-Color "           DNS: $($si.DNS)" "Gray"
    Write-Color "  Uptime:  $($si.Uptime)" "White"
    Write-Color "  .NET:    $($si.NETVersion)" "Gray"
    Write-Color "  PS:      $($si.PSVersion)" "Gray"
    Write-Color "  Serial:  $($si.Serial)" "Gray"
    Write-Color "╚══════════════════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Log "System info displayed" "INFO"
    return $si
}
#endregion

#region ENCODED BANNER
function Show-Banner {
    Clear-Host
    $w = [math]::Max(70, [math]::Min(120, (Get-ConsoleWidth)))
    $line = "═" * ($w - 2)
    $pad = " " * [math]::Max(0, ($w - 38) / 2)

    Write-Color "╔$line╗" "Cyan"
    Write-Color "║$pad   4D 61 64 64 69 78 53 75 69 74 65$pad  ║" "Green"
    Write-Color "║$pad   M  a  d  d  i  x  S  u  i  t  e$pad   ║" "Green"
    Write-Color "╠$line╣" "Cyan"
    Write-Color "║$pad  MaddixSuite — Ultimate Windows Toolkit$pad ║" "Cyan"
    Write-Color "║$pad  Author: Mohammad Mehrani (Maddix)$pad   ║" "Cyan"
    Write-Color "║$pad  https://github.com/mohammadmehrani/MaddixSuite$pad ║" "Gray"
    Write-Color "╚$line╝" "Cyan"
    Write-Color ""
}

function Show-HexBanner {
    $w = [math]::Max(70, [math]::Min(120, (Get-ConsoleWidth)))
    $line = "═" * ($w - 2)
    Write-Color "╔$line╗" "Cyan"
    Write-Color "║$(" " * ($w - 3 - 42)) 4D 61 64 64 69 78 53 75 69 74 65$(" " * 0)║" "Green"
    Write-Color "║$(" " * ($w - 3 - 42)) M  a  d  d  i  x  S  u  i  t  e$(" " * 0) ║" "Green"
    Write-Color "╠$line╣" "Cyan"
}
#endregion

#region TOOL LOADING SYSTEM
function Get-ToolCategory {
    param([string]$CatCode)
    switch ($CatCode) {
        "SYS" { return "System Tools" }
        "NET" { return "Network Tools" }
        "SEC" { return "Security Tools" }
        "CLN" { return "Cleaner Tools" }
        "OPT" { return "Optimization Tools" }
        "BAK" { return "Backup Tools" }
        "DEV" { return "Development Tools" }
        "SRV" { return "Server Tools" }
        "AD"  { return "Active Directory" }
        default { return "Unknown" }
    }
}

function Get-CategoryColor {
    param([string]$CatCode)
    switch ($CatCode) {
        "SYS" { return "Cyan" }
        "NET" { return "Blue" }
        "SEC" { return "Red" }
        "CLN" { return "Yellow" }
        "OPT" { return "Green" }
        "BAK" { return "Magenta" }
        "DEV" { return "DarkYellow" }
        "SRV" { return "DarkRed" }
        "AD"  { return "DarkMagenta" }
        default { return "Gray" }
    }
}

function Get-DangerColor {
    param([string]$Level)
    switch ($Level) {
        "Safe" { return "Green" }
        "Caution" { return "Yellow" }
        "Dangerous" { return "Red" }
        default { return "Gray" }
    }
}

function Load-Tools {
    $script:AllTools = @()
    $catDirs = @("SYS","NET","SEC","CLN","OPT","BAK","DEV","SRV","AD")
    foreach ($cat in $catDirs) {
        $catDir = Join-Path $script:ToolLibPath $cat
        if (-not (Test-Path $catDir)) { New-Item -ItemType Directory -Path $catDir -Force | Out-Null }
        $files = Get-ChildItem -Path $catDir -Filter "*.ps1" -ErrorAction SilentlyContinue | Sort-Object Name
        foreach ($file in $files) {
            try {
                . $file.FullName
                if ($script:ToolInfo) {
                    $script:AllTools += $script:ToolInfo
                    Remove-Variable -Name ToolInfo -Scope Script -ErrorAction SilentlyContinue
                }
            } catch { Write-Log "Failed to load $($file.Name): $_" "ERROR" }
        }
    }
    if ($script:AllTools.Count -eq 0) { Load-BuiltInTools }
}

function Load-BuiltInTools {
    Write-Log "No tool files found, using built-in tools" "INFO"
    $placeholder = @()
    1..50 | ForEach-Object {
        $num = "{0:D3}" -f $_
        $id = "SYS-$num"
        $real = $null
        switch ($_) {
            1  { $real = Get-Tool-SYS001 }
            2  { $real = Get-Tool-SYS002 }
            3  { $real = Get-Tool-SYS003 }
            4  { $real = Get-Tool-SYS004 }
            5  { $real = Get-Tool-SYS005 }
            6  { $real = Get-Tool-SYS006 }
            7  { $real = Get-Tool-SYS007 }
            8  { $real = Get-Tool-SYS008 }
            9  { $real = Get-Tool-SYS009 }
            10 { $real = Get-Tool-SYS010 }
            11 { $real = Get-Tool-SYS011 }
            12 { $real = Get-Tool-SYS012 }
            13 { $real = Get-Tool-SYS013 }
            14 { $real = Get-Tool-SYS014 }
            15 { $real = Get-Tool-SYS015 }
            16 { $real = Get-Tool-SYS016 }
            17 { $real = Get-Tool-SYS017 }
            18 { $real = Get-Tool-SYS018 }
            19 { $real = Get-Tool-SYS019 }
            20 { $real = Get-Tool-SYS020 }
            default { $real = $null }
        }
        if ($real) { $placeholder += $real }
        else {
            $placeholder += @{
                ID = $id; Name = "SYS Tool #$_"; Category = "SYS"
                Description = "Coming soon — will be implemented in a future update"
                ServerOnly = $false; ClientOnly = $false; DangerLevel = "Safe"
                Action = { Write-Color "  [!] This tool is not yet implemented. Coming in a future update." "Yellow"; Pause }
                ConfirmMessage = "This tool is a placeholder."
            }
        }
    }
    $netTools = @(
        @{ID="NET-001";Name="Quick Network Diagnostic";Category="NET";Description="Ping key hosts, check DNS, show interfaces";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={(Get-Tool-NET001).Action};ConfirmMessage="Read-only network check"},
        @{ID="NET-002";Name="Advanced Network Scan";Category="NET";Description="Traceroute, PathPing, TCP stats, bandwidth";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={(Get-Tool-NET002).Action};ConfirmMessage="Read-only advanced scan"},
        @{ID="NET-003";Name="WiFi Manager";Category="NET";Description="Scan networks, export profiles, manage";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={(Get-Tool-NET003).Action};ConfirmMessage="WiFi management"},
        @{ID="NET-004";Name="DNS Changer";Category="NET";Description="Switch DNS to Google, Cloudflare, OpenDNS, custom";ServerOnly=$false;ClientOnly=$false;DangerLevel="Caution";Action={(Get-Tool-NET004).Action};ConfirmMessage="Changing DNS may temporarily disrupt internet"},
        @{ID="NET-005";Name="Network Reset";Category="NET";Description="Reset Winsock, TCP/IP, firewall, flush DNS";ServerOnly=$false;ClientOnly=$false;DangerLevel="Caution";Action={(Get-Tool-NET005).Action};ConfirmMessage="Network will be interrupted. Reboot recommended."},
        @{ID="NET-006";Name="Connection Monitor";Category="NET";Description="Real-time TCP connection monitoring";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={(Get-Tool-NET006).Action};ConfirmMessage="Read-only monitoring"},
        @{ID="NET-007";Name="Speed Test";Category="NET";Description="Estimate download speed via test files";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={(Get-Tool-NET007).Action};ConfirmMessage="Downloads small test files to estimate speed"},
        @{ID="NET-008";Name="Port Scanner";Category="NET";Description="Scan remote host for open ports";ServerOnly=$false;ClientOnly=$false;DangerLevel="Caution";Action={(Get-Tool-NET008).Action};ConfirmMessage="Scanning external hosts may be flagged"},
        @{ID="NET-013";Name="Flush DNS";Category="NET";Description="Clear DNS resolver cache";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={ipconfig /flushdns; Write-Color "  DNS cache flushed." "Green"; Pause};ConfirmMessage="Safe operation"}
    )
    $placeholder += $netTools

    1..20 | ForEach-Object { $placeholder += @{ID="NET-$("{0:D3}"-f($_+20))";Name="NET Tool #$($_+20)";Category="NET";Description="Coming soon";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={Write-Color "  Coming soon." "Yellow";Pause};ConfirmMessage="Placeholder"} }

    $secTools = @(
        @{ID="SEC-001";Name="Port Scanner (Local)";Category="SEC";Description="Scan localhost for open ports";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={(Get-Tool-SEC001).Action};ConfirmMessage="Read-only scan"},
        @{ID="SEC-002";Name="Firewall Audit";Category="SEC";Description="Check firewall profiles, rules, blocked events";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={(Get-Tool-SEC002).Action};ConfirmMessage="Read-only audit"},
        @{ID="SEC-003";Name="User Account Audit";Category="SEC";Description="List users, admins, password policy";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={(Get-Tool-SEC003).Action};ConfirmMessage="Read-only audit"},
        @{ID="SEC-004";Name="Service Security Audit";Category="SEC";Description="Check running services, insecure services";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={(Get-Tool-SEC004).Action};ConfirmMessage="Read-only audit"},
        @{ID="SEC-005";Name="Defender Status";Category="SEC";Description="Check Windows Defender status and signatures";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={(Get-Tool-SEC005).Action};ConfirmMessage="Read-only check"},
        @{ID="SEC-014";Name="Full Anti-Hack Scan";Category="SEC";Description="Complete security scan (network, keyloggers, persistence)";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={(Get-Tool-SEC014).Action};ConfirmMessage="Comprehensive read-only scan"}
    )
    $placeholder += $secTools
    $clnTools = @(
        @{ID="CLN-001";Name="Temp Files Cleaner";Category="CLN";Description="Delete Windows temp, prefetch, logs";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={(Get-Tool-CLN001).Action};ConfirmMessage="Deletes temporary files"},
        @{ID="CLN-002";Name="Browser Cache Cleaner";Category="CLN";Description="Clear Chrome, Firefox, Edge caches";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={(Get-Tool-CLN002).Action};ConfirmMessage="You may need to re-login to websites"},
        @{ID="CLN-009";Name="Run All Cleaners";Category="CLN";Description="Execute all cleaning operations";ServerOnly=$false;ClientOnly=$false;DangerLevel="Caution";Action={(Get-Tool-CLN009).Action};ConfirmMessage="Will clean all temp files, caches, and logs"}
    )
    $placeholder += $clnTools
    $optTools = @(
        @{ID="OPT-001";Name="CPU Optimizer";Category="OPT";Description="Scheduling, core parking, power management";ServerOnly=$false;ClientOnly=$false;DangerLevel="Caution";Action={(Get-Tool-OPT001).Action};ConfirmMessage="Changes CPU scheduling and power settings"},
        @{ID="OPT-002";Name="RAM Optimizer";Category="OPT";Description="Memory compression, cache, paging config";ServerOnly=$false;ClientOnly=$false;DangerLevel="Caution";Action={(Get-Tool-OPT002).Action};ConfirmMessage="Changes memory management settings"},
        @{ID="OPT-008";Name="Run All Optimizers";Category="OPT";Description="Apply all performance optimizations";ServerOnly=$false;ClientOnly=$false;DangerLevel="Caution";Action={(Get-Tool-OPT008).Action};ConfirmMessage="Will change multiple system settings"}
    )
    $placeholder += $optTools
    $bakTools = @(
        @{ID="BAK-001";Name="System State Backup";Category="BAK";Description="Backup registry, drivers, BCD, tasks, network";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={(Get-Tool-BAK001).Action};ConfirmMessage="Creates system state backup"},
        @{ID="BAK-002";Name="Registry Backup";Category="BAK";Description="Export all registry hives";ServerOnly=$false;ClientOnly=$false;DangerLevel="Safe";Action={(Get-Tool-BAK002).Action};ConfirmMessage="Creates registry backup"}
    )
    $placeholder += $bakTools
    $devTools = @(
        @{ID="DEV-001";Name="Docker Install";Category="DEV";Description="Install Docker Desktop with WSL2";ServerOnly=$false;ClientOnly=$false;DangerLevel="Caution";Action={(Get-Tool-DEV001).Action};ConfirmMessage="Downloads and installs Docker Desktop"},
        @{ID="DEV-002";Name="WSL2 Setup";Category="DEV";Description="Enable WSL2, install Linux kernel";ServerOnly=$false;ClientOnly=$false;DangerLevel="Caution";Action={(Get-Tool-DEV002).Action};ConfirmMessage="Enables WSL2 feature"}
    )
    $placeholder += $devTools
    $script:AllTools = $placeholder
}

function Get-FilteredTools {
    $tools = $script:AllTools
    if (-not $script:IsServer) { $tools = $tools | Where-Object { -not $_.ServerOnly -and $_.Category -notin @("SRV","AD") } }
    else { $tools = $tools | Where-Object { -not $_.ClientOnly } }
    return $tools
}

function Find-Tool {
    param([string]$Id)
    return $script:AllTools | Where-Object { $_.ID -eq $Id } | Select-Object -First 1
}
#endregion

#region BUILT-IN TOOL DEFINITIONS (fallback)
function Get-Tool-SYS001 { return $null }
function Get-Tool-SYS002 { return $null }
function Get-Tool-SYS003 { return $null }
function Get-Tool-SYS004 { return $null }
function Get-Tool-SYS005 { return $null }
function Get-Tool-SYS006 { return $null }
function Get-Tool-SYS007 { return $null }
function Get-Tool-SYS008 { return $null }
function Get-Tool-SYS009 { return $null }
function Get-Tool-SYS010 { return $null }
function Get-Tool-SYS011 { return $null }
function Get-Tool-SYS012 { return $null }
function Get-Tool-SYS013 { return $null }
function Get-Tool-SYS014 { return $null }
function Get-Tool-SYS015 { return $null }
function Get-Tool-SYS016 { return $null }
function Get-Tool-SYS017 { return $null }
function Get-Tool-SYS018 { return $null }
function Get-Tool-SYS019 { return $null }
function Get-Tool-SYS020 { return $null }
function Get-Tool-NET001 { return $null }
function Get-Tool-NET002 { return $null }
function Get-Tool-NET003 { return $null }
function Get-Tool-NET004 { return $null }
function Get-Tool-NET005 { return $null }
function Get-Tool-NET006 { return $null }
function Get-Tool-NET007 { return $null }
function Get-Tool-NET008 { return $null }
function Get-Tool-SEC001 { return $null }
function Get-Tool-SEC002 { return $null }
function Get-Tool-SEC003 { return $null }
function Get-Tool-SEC004 { return $null }
function Get-Tool-SEC005 { return $null }
function Get-Tool-SEC014 { return $null }
function Get-Tool-CLN001 { return $null }
function Get-Tool-CLN002 { return $null }
function Get-Tool-CLN009 { return $null }
function Get-Tool-OPT001 { return $null }
function Get-Tool-OPT002 { return $null }
function Get-Tool-OPT008 { return $null }
function Get-Tool-BAK001 { return $null }
function Get-Tool-BAK002 { return $null }
function Get-Tool-DEV001 { return $null }
function Get-Tool-DEV002 { return $null }
#endregion

#region CONFIRMATION SYSTEM
function Get-UserConfirm {
    param([string]$Id)
    $tool = Find-Tool -Id $Id
    if (-not $tool) { Write-Color "  [!] Tool not found: $Id" "Red"; return $false }

    Write-Color "╔══════════════════════════════════════════════════════════════╗" "Yellow"
    Write-Color "║                    TOOL CONFIRMATION                        ║" "Yellow"
    Write-Color "╚══════════════════════════════════════════════════════════════╝" "Yellow"
    Write-Color "  ID:     $($tool.ID)" "White"
    Write-Color "  Name:   $($tool.Name)" "White"
    Write-Color "  Cat:    $(Get-ToolCategory $tool.Category)" "Gray"
    Write-Color "  Risk:   $($tool.DangerLevel)" (Get-DangerColor $tool.DangerLevel)
    Write-Color "  Desc:   $($tool.Description)" "Gray"
    Write-Color "  Confirm: $($tool.ConfirmMessage)" "Gray"
    Write-Color ""
    $ans = Read-Host "  Execute [$Id]? (Y/N/?)"
    if ($ans -eq '?') {
        Write-Color "`n  ─── DETAILS ───" "Cyan"
        Write-Color "  $($tool.Description)" "White"
        Write-Color "  Risk Level: $($tool.DangerLevel)" (Get-DangerColor $tool.DangerLevel)
        Write-Color "  What happens: $($tool.ConfirmMessage)" "Yellow"
        if ($tool.DangerLevel -eq "Dangerous") { Write-Color "  ⚠ WARNING: This operation can destabilize your system!" "Red" }
        Write-Color "  ───────────────" "Cyan"
        Write-Color ""
        $ans = Read-Host "  Execute [$Id]? (Y/N)"
    }
    return ($ans -eq 'y' -or $ans -eq 'Y')
}

function Invoke-Tool {
    param([string]$Id)
    $tool = Find-Tool -Id $Id
    if (-not $tool) { Write-Color "  [!] Tool not found: $Id" "Red"; Pause; return }

    if (-not (Get-UserConfirm -Id $Id)) { Write-Color "  Cancelled." "Gray"; return }

    Write-Color "  Executing $($tool.ID): $($tool.Name)..." "Cyan"
    Write-Log "Executing $($tool.ID): $($tool.Name)" "ACTION"

    try {
        & $tool.Action
        Write-Color "  ✓ $($tool.ID) completed." "Green"
        Write-Log "$($tool.ID) completed successfully" "SUCCESS"
    } catch {
        Write-Color "  ✗ $($tool.ID) failed: $_" "Red"
        Write-Log "$($tool.ID) failed: $_" "ERROR"
    }

    if ($script:PendingReboot) {
        Write-Color "`n  ⚠ A system reboot is required for changes to take effect." "Yellow"
        $r = Read-Host "  Reboot now? (y/n)"
        if ($r -eq 'y') { Restart-Computer -Force }
        $script:PendingReboot = $false
    }
    Write-Color ""
    Write-Color "  Press any key to return to menu..." "Gray"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 2>$null
}
#endregion

#region UI
function Show-MenuHeader {
    Show-HexBanner
    $w = [math]::Max(70, [math]::Min(120, (Get-ConsoleWidth)))
    $line = "═" * ($w - 2)
    $toolCount = (Get-FilteredTools).Count
    $edition = if ($script:IsServer) { "SERVER EDITION" } else { "CLIENT EDITION" }
    Write-Color "║  Tools: $toolCount loaded | Mode: $edition                                           ║" "Cyan"
    Write-Color "║  Type 'help' for usage | 'q' to quit | Search: 's keyword' or 's ID'               ║" "Gray"
    Write-Color "╚$line╝" "Cyan"
    Write-Color ""
}

function Show-ToolMenu {
    param([int]$Page = 1, [string]$Filter = "")
    $tools = Get-FilteredTools
    if ($Filter) {
        $tools = $tools | Where-Object {
            $_.ID -like "*$Filter*" -or $_.Name -like "*$Filter*" -or $_.Description -like "*$Filter*" -or $_.Category -like "*$Filter*"
        }
    }
    if ($tools.Count -eq 0) { Write-Color "  No tools match your filter." "Yellow"; return }

    $perPage = 10
    $totalPages = [math]::Ceiling($tools.Count / $perPage)
    if ($Page -gt $totalPages) { $Page = $totalPages }
    if ($Page -lt 1) { $Page = 1 }
    $start = ($Page - 1) * $perPage
    $pageTools = $tools[$start..([math]::Min($start + $perPage - 1, $tools.Count - 1))]

    $catOrder = @("SYS","NET","SEC","CLN","OPT","BAK","DEV")
    if ($script:IsServer) { $catOrder += @("SRV","AD") }
    $grouped = $pageTools | Group-Object { [array]::IndexOf($catOrder, $_.Category) }
    $sorted = $pageTools | Sort-Object { [array]::IndexOf($catOrder, $_.Category) }, ID

    $w = [math]::Max(70, [math]::Min(120, (Get-ConsoleWidth)))
    $currentCat = ""
    foreach ($tool in $sorted) {
        if ($tool.Category -ne $currentCat) {
            $currentCat = $tool.Category
            $catName = Get-ToolCategory $currentCat
            $catColor = Get-CategoryColor $currentCat
            Write-Color "  ── [$currentCat] $catName ──" $catColor
        }
        $dangerColor = Get-DangerColor $tool.DangerLevel
        $status = if ($tool.DangerLevel -eq "Safe") { "Ready" } elseif ($tool.DangerLevel -eq "Caution") { "⚠ Caution" } else { "!! Dangerous" }
        $idColor = if ($tool.ServerOnly -or $tool.ClientOnly) { "DarkGray" } else { "White" }
        Write-Color "    $($tool.ID) | $($tool.Name)" "White" -NoNewline
        Write-Color "  | $($tool.Description)" "Gray" -NoNewline
        Write-Color "  | [$status]" $dangerColor
    }
    Write-Color ""
    Write-Color "  Page $Page of $totalPages | Tools: $($tools.Count)" "Gray"
    Write-Color "  [N]ext | [P]rev | [G]## | [S]earch | [Q]uit | [ID] to run" "Gray"
}

function Show-Help {
    Show-Banner
    $w = [math]::Max(70, [math]::Min(120, (Get-ConsoleWidth)))
    $line = "═" * ($w - 2)
    Write-Color "╔$line╗" "Cyan"
    Write-Color "║$(" " * (($w - 22)/2))MADDIXSUITE HELP$(" " * (($w - 22)/2))║" "Cyan"
    Write-Color "╚$line╝" "Cyan"
    Write-Color ""
    Write-Color "  COMMANDS:" "Yellow"
    Write-Color "    <ID>      Execute a tool by ID (e.g., SYS-001)" "White"
    Write-Color "    s <term>  Search tools by keyword, ID, or description" "White"
    Write-Color "    n         Next page" "White"
    Write-Color "    p         Previous page" "White"
    Write-Color "    g <num>   Go to page number" "White"
    Write-Color "    ? <ID>    Show details about a specific tool" "White"
    Write-Color "    help      Show this help screen" "White"
    Write-Color "    q         Quit MaddixSuite" "White"
    Write-Color ""
    Write-Color "  CATEGORIES:" "Yellow"
    Write-Color "    SYS  - System Tools (info, repair, diagnostics)" "Cyan"
    Write-Color "    NET  - Network Tools (diagnostics, WiFi, DNS)" "Blue"
    Write-Color "    SEC  - Security Tools (audit, scanner, defender)" "Red"
    Write-Color "    CLN  - Cleaner Tools (temp files, caches, logs)" "Yellow"
    Write-Color "    OPT  - Optimization Tools (performance, tuning)" "Green"
    Write-Color "    BAK  - Backup Tools (system state, registry, files)" "Magenta"
    Write-Color "    DEV  - Development Tools (Docker, WSL, git)" "DarkYellow"
    if ($script:IsServer) {
        Write-Color "    SRV  - Server Tools (AD, DNS, DHCP, roles)" "DarkRed"
        Write-Color "    AD   - Active Directory (domains, GPO, replication)" "DarkMagenta"
    }
    Write-Color ""
    Write-Color "  DANGER LEVELS:" "Yellow"
    Write-Color "    Safe      - Read-only or safe operations" "Green"
    Write-Color "    Caution   - Modifies settings, may require reboot" "Yellow"
    Write-Color "    Dangerous - Can destabilize system, use with care" "Red"
    Write-Color ""
    Write-Color "  All actions are logged to: $($script:LogPath)" "Gray"
    Write-Color "  Reports are saved for later review." "Gray"
    Write-Color ""
    Pause
}
#endregion

#region MAIN LOOP
function Start-MainLoop {
    $page = 1
    $filter = ""
    $filtered = $false

    while ($true) {
        Show-MenuHeader
        Show-ToolMenu -Page $page -Filter $filter

        Write-Color ""
        if ($filtered) { Write-Color "  [Filter: '$filter'] [C]lear filter" "Yellow" }
        $input = Read-Host "  MaddixSuite [$([math]::Max(1,$page))]"
        $input = $input.Trim()

        if ($input -eq 'q' -or $input -eq 'quit' -or $input -eq 'exit') {
            Write-Color "  Thank you for using MaddixSuite. Goodbye!" "Cyan"
            Write-Log "Session ended" "INFO"
            exit
        }
        elseif ($input -eq 'help' -or $input -eq 'h') { Show-Help; continue }
        elseif ($input -eq 'n' -or $input -eq 'next') { $page++; if ($filtered) { $filtered = $false; $filter = "" }; continue }
        elseif ($input -eq 'p' -or $input -eq 'prev') { $page = [math]::Max(1, $page - 1); if ($filtered) { $filtered = $false; $filter = "" }; continue }
        elseif ($input -eq 'c' -or $input -eq 'clear') { $filter = ""; $filtered = $false; $page = 1; continue }
        elseif ($input -match '^g\s+(\d+)$') { $page = [math]::Max(1, [int]$matches[1]); if ($filtered) { $filtered = $false; $filter = "" }; continue }
        elseif ($input -match '^s\s+(.+)$') {
            $filter = $matches[1].Trim()
            $filtered = $true; $page = 1; continue
        }
        elseif ($input -match '^\?\s*(\S+)$') {
            $tid = $matches[1]
            $tool = Find-Tool -Id $tid
            if ($tool) {
                Write-Color "`n  ─── TOOL: $($tool.ID) ───" "Cyan"
                Write-Color "  Name:        $($tool.Name)" "White"
                Write-Color "  Category:    $(Get-ToolCategory $tool.Category)" "Gray"
                Write-Color "  Description: $($tool.Description)" "White"
                Write-Color "  Risk Level:  $($tool.DangerLevel)" (Get-DangerColor $tool.DangerLevel)
                Write-Color "  Consequence: $($tool.ConfirmMessage)" "Yellow"
                Write-Color "  ───────────────────" "Cyan"
            } else { Write-Color "  [!] Tool not found: $tid" "Red" }
            Write-Color ""; Pause; continue
        }
        elseif ($input -match '^([A-Za-z]+-\d+)$') {
            $tid = $input.ToUpper()
            $tool = Find-Tool -Id $tid
            if ($tool) {
                if ($tool.ServerOnly -and -not $script:IsServer) { Write-Color "  [!] $tid is Server-only." "Yellow"; Pause; continue }
                if ($tool.ClientOnly -and $script:IsServer) { Write-Color "  [!] $tid is Client-only." "Yellow"; Pause; continue }
                Invoke-Tool -Id $tid
            } else { Write-Color "  [!] Tool not found: $tid" "Red"; Pause }
            $filter = ""; $filtered = $false; $page = 1; continue
        }
        else { Write-Color "  [!] Unknown command. Type 'help' for usage." "Yellow"; Start-Sleep -Milliseconds 800 }
    }
}
#endregion

#region INVOKE
function Invoke-MaddixSuite {
    Show-Banner
    Write-Color "  Loading tools..." "Gray"
    Load-Tools
    Write-Color "  Loaded $($script:AllTools.Count) tools." "Green"
    Start-Sleep -Milliseconds 500
    Show-SystemInfo | Out-Null
    Write-Color "`n  Press any key to enter the main menu..." "Gray"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 2>$null
    Start-MainLoop
}
#endregion

# Source-safe entry point
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-MaddixSuite
}
