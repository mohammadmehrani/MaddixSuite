# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
<#
.SYNOPSIS
    Maddix-SecurityAudit - Windows Security Assessment & Hardening Tool
.DESCRIPTION
    Comprehensive security utility by Mohammad Mehrani (Maddix) featuring:
    Open port scanning, firewall audit, user account analysis, service audit,
    Windows Defender status, privacy check, and security hardening.
.NOTES
    Version: 1.0
    Author: Mohammad Mehrani (Maddix)
    Part of MaddixSuite: https://github.com/mohammadmehrani/MaddixSuite
    One-liner: irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Security/Maddix-SecurityAudit.ps1 | iex
#>

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: Administrator privileges required." -ForegroundColor Red
    Pause; Exit
}

function Show-Banner {
    Clear-Host
    Write-Host "████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host "  ███╗   ███╗ █████╗ ██████╗ ██████╗ ██╗██╗  ██╗" -ForegroundColor Cyan
    Write-Host "  ████╗ ████║██╔══██╗██╔══██╗██╔══██╗██║╚██╗██╔╝" -ForegroundColor Cyan
    Write-Host "  ██╔████╔██║███████║██║  ██║██║  ██║██║ ╚███╔╝ " -ForegroundColor Cyan
    Write-Host "  ██║╚██╔╝██║██╔══██║██║  ██║██║  ██║██║ ██╔██╗ " -ForegroundColor Cyan
    Write-Host "  ██║ ╚═╝ ██║██║  ██║██████╔╝██████╔╝██║██╔╝ ██╗" -ForegroundColor Cyan
    Write-Host "  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═╝" -ForegroundColor Cyan
    Write-Host "████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host "  Maddix-SecurityAudit v1.0 · Security Assessment" -ForegroundColor Cyan
    Write-Host "  Created by Mohammad Mehrani (Maddix)" -ForegroundColor Cyan
    Write-Host "████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host ""
}

function Scan-Ports {
    Write-Host "`n=== PORT SCANNER (Local) ===" -ForegroundColor Cyan
    Write-Host "Scanning common ports on localhost..." -ForegroundColor Yellow
    $ports = @{21="FTP";22="SSH";23="Telnet";25="SMTP";53="DNS";80="HTTP";110="POP3";
               135="RPC";139="NetBIOS";143="IMAP";443="HTTPS";445="SMB";1433="MSSQL";
               3306="MySQL";3389="RDP";5432="PostgreSQL";5900="VNC";6379="Redis";
               8080="HTTP-Alt";8443="HTTPS-Alt";27017="MongoDB"}
    
    $openPorts = @()
    foreach ($p in $ports.Keys) {
        try {
            $conn = New-Object System.Net.Sockets.TcpClient
            $async = $conn.BeginConnect("127.0.0.1", $p, $null, $null)
            $wait = $async.AsyncWaitHandle.WaitOne(200)
            if ($conn.Connected) {
                $openPorts += [PSCustomObject]@{Port=$p; Service=$ports[$p]; Status="OPEN"}
                Write-Host "  PORT $p ($($ports[$p])): OPEN" -ForegroundColor Red
            }
            $conn.Close()
        } catch {}
    }
    
    if ($openPorts.Count -eq 0) {
        Write-Host "  No common open ports found on localhost." -ForegroundColor Green
    }
    
    $scanExternal = Read-Host "`nScan external IP? (y/n)"
    if ($scanExternal -eq 'y') {
        $extIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -ErrorAction SilentlyContinue).Content
        Write-Host "External IP: $extIP" -ForegroundColor Gray
        Write-Host "Note: Scanning external IP requires firewall exceptions." -ForegroundColor Yellow
    }
    Pause
}

function Audit-Firewall {
    Write-Host "`n=== FIREWALL AUDIT ===" -ForegroundColor Cyan
    
    Write-Host "Firewall Profiles:" -ForegroundColor Yellow
    Get-NetFirewallProfile -ErrorAction SilentlyContinue | Format-Table Name, Enabled, DefaultInboundAction, DefaultOutboundAction -AutoSize
    
    Write-Host "`nInbound Rules (enabled):" -ForegroundColor Yellow
    $inRules = Get-NetFirewallRule -Direction Inbound -Enabled True -ErrorAction SilentlyContinue | Select-Object DisplayName, Action, Profile, LocalPort
    if ($inRules) {
        $inRules | Format-Table DisplayName, Action, Profile, LocalPort -AutoSize
        Write-Host "Total inbound rules: $(($inRules | Measure-Object).Count)" -ForegroundColor Cyan
    }
    
    Write-Host "`nBlocked connections log (last 24h):" -ForegroundColor Yellow
    $blocked = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=5152} -MaxEvents 20 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Message
    if ($blocked) {
        $blocked | ForEach-Object { Write-Host "  $($_.TimeCreated): Blocked" -ForegroundColor Gray }
    } else {
        Write-Host "  No blocked events found in security log." -ForegroundColor Gray
    }
    Pause
}

function Audit-Users {
    Write-Host "`n=== USER ACCOUNT AUDIT ===" -ForegroundColor Cyan
    
    Write-Host "Local Users & Groups:" -ForegroundColor Yellow
    $users = Get-LocalUser -ErrorAction SilentlyContinue
    $users | ForEach-Object {
        $admin = if ($_.Enabled) { "Enabled" } else { "Disabled" }
        $password = if ($_.PasswordRequired) { "Yes" } else { "No" }
        $color = if (-not $_.Enabled) { "Red" } else { "Green" }
        Write-Host "  $($_.Name) [$admin, Password: $password, LastLogon: $($_.LastLogon)]" -ForegroundColor $color
    }
    
    Write-Host "`nAdministrator Group Members:" -ForegroundColor Yellow
    $admins = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue
    $admins | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor $(if ($_.Name -match $env:USERNAME) { "Green" } else { "Yellow" }) }
    
    Write-Host "`nDisabled Users:" -ForegroundColor Yellow
    $disabled = $users | Where-Object { -not $_.Enabled }
    if ($disabled) {
        $disabled | ForEach-Object { Write-Host "  WARNING: $($_.Name) is disabled but still exists" -ForegroundColor Red }
    } else {
        Write-Host "  All enabled users are active." -ForegroundColor Green
    }
    
    Write-Host "`nPassword Policy:" -ForegroundColor Yellow
    net accounts | Write-Host
    Pause
}

function Audit-Services {
    Write-Host "`n=== SERVICE SECURITY AUDIT ===" -ForegroundColor Cyan
    
    Write-Host "Non-Microsoft Services (Running):" -ForegroundColor Yellow
    $services = Get-Service | Where-Object { $_.Status -eq 'Running' -and $_.StartType -ne 'Disabled' } | Sort-Object Name
    $services | Format-Table Name, DisplayName, StartType -AutoSize
    
    Write-Host "`nServices Running as SYSTEM (elevated):" -ForegroundColor Yellow
    $svcPaths = @()
    foreach ($svc in $services) {
        $path = (Get-CimInstance -ClassName Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue).PathName
        if ($path) { $svcPaths += [PSCustomObject]@{Name=$svc.Name; Path=$path} }
    }
    $svcPaths | Format-Table Name, Path -AutoSize
    
    Write-Host "`nPotentially Insecure Services:" -ForegroundColor Yellow
    $insecure = @("RemoteRegistry", "RemoteAccess", "Telnet", "Ftpsvc", "SSHServer")
    foreach ($is in $insecure) {
        $svc = Get-Service -Name $is -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq 'Running') {
            Write-Host "  WARNING: $is is running!" -ForegroundColor Red
        }
    }
    Pause
}

function Check-Defender {
    Write-Host "`n=== WINDOWS DEFENDER STATUS ===" -ForegroundColor Cyan
    try {
        $status = Get-MpComputerStatus -ErrorAction Stop
        
        Write-Host "Real-time Protection:" -ForegroundColor Yellow
        $rtp = if ($status.RealTimeProtectionEnabled) { "✓ ENABLED" } else { "✗ DISABLED" }
        Write-Host "  $rtp" -ForegroundColor $(if ($status.RealTimeProtectionEnabled) { "Green" } else { "Red" })
        
        Write-Host "`nSignature Versions:" -ForegroundColor Yellow
        Write-Host "  Antivirus: $($status.AntivirusSignatureVersion) (age: $($status.AntivirusSignatureAge) days)" -ForegroundColor Gray
        Write-Host "  Antispyware: $($status.AntispywareSignatureVersion) (age: $($status.AntispywareSignatureAge) days)" -ForegroundColor Gray
        
        Write-Host "`nLast Scans:" -ForegroundColor Yellow
        Write-Host "  Quick: $($status.QuickScanEndTime)" -ForegroundColor Gray
        Write-Host "  Full: $($status.FullScanEndTime)" -ForegroundColor Gray
        
        Write-Host "`nThreat History:" -ForegroundColor Yellow
        $threats = Get-MpThreat -ErrorAction SilentlyContinue
        if ($threats) {
            $threats | Format-Table Name, Severity, Category, ThreatStatus -AutoSize
        } else {
            Write-Host "  No active threats detected." -ForegroundColor Green
        }
        
        # Quick actions
        Write-Host "`nQuick Actions:" -ForegroundColor Cyan
        $update = Read-Host "  Update signatures? (y/n)"
        if ($update -eq 'y') { Update-MpSignature -ErrorAction SilentlyContinue; Write-Host "  Signatures updated." -ForegroundColor Green }
        
    } catch {
        Write-Host "  Windows Defender not available or inaccessible." -ForegroundColor Red
    }
    Pause
}

function Check-Privacy {
    Write-Host "`n=== PRIVACY & TELEMETRY CHECK ===" -ForegroundColor Cyan
    
    Write-Host "Telemetry Settings:" -ForegroundColor Yellow
    try {
        $telemetry = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
        $level = if ($telemetry) { $telemetry.AllowTelemetry } else { "Default (3 - Full)" }
        Write-Host "  Telemetry level: $level" -ForegroundColor $(if ($level -eq 0) { "Green" } elseif ($level -le 2) { "Yellow" } else { "Red" })
    } catch {
        Write-Host "  Telemetry: Default (3 - Full)" -ForegroundColor Red
    }
    
    Write-Host "`nLocation Tracking:" -ForegroundColor Yellow
    $loc = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\Location" -Name "Value" -ErrorAction SilentlyContinue
    Write-Host "  Location: $(if($loc){$loc.Value}else{'Allow'})" -ForegroundColor Gray
    
    Write-Host "`nCamera Access:" -ForegroundColor Yellow
    $cam = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\Webcam" -Name "Value" -ErrorAction SilentlyContinue
    Write-Host "  Camera: $(if($cam){$cam.Value}else{'Allow'})" -ForegroundColor Gray
    
    Write-Host "`nMicrophone Access:" -ForegroundColor Yellow
    $mic = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\Microphone" -Name "Value" -ErrorAction SilentlyContinue
    Write-Host "  Microphone: $(if($mic){$mic.Value}else{'Allow'})" -ForegroundColor Gray
    
    Write-Host "`nAdvertising ID:" -ForegroundColor Yellow
    $adv = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -ErrorAction SilentlyContinue
    if ($adv -and $adv.Enabled -eq 0) { Write-Host "  Advertising ID: Disabled" -ForegroundColor Green }
    else { Write-Host "  Advertising ID: Enabled" -ForegroundColor Red }
    
    $disableAll = Read-Host "`nDisable telemetry & privacy-invasive features? (y/n)"
    if ($disableAll -eq 'y') {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Write-Host "  Telemetry & Advertising ID disabled." -ForegroundColor Green
    }
    Pause
}

function Run-FullAudit {
    Write-Host "`n=== RUNNING FULL SECURITY AUDIT ===" -ForegroundColor Cyan
    
    Write-Host "[1/6] Scanning open ports..." -ForegroundColor Yellow
    Scan-Ports > $null 2>&1
    
    Write-Host "[2/6] Auditing firewall..." -ForegroundColor Yellow
    Audit-Firewall > $null 2>&1
    
    Write-Host "[3/6] Auditing user accounts..." -ForegroundColor Yellow
    Audit-Users > $null 2>&1
    
    Write-Host "[4/6] Checking services..." -ForegroundColor Yellow
    Audit-Services > $null 2>&1
    
    Write-Host "[5/6] Checking Defender..." -ForegroundColor Yellow
    Check-Defender > $null 2>&1
    
    Write-Host "[6/6] Checking privacy..." -ForegroundColor Yellow
    Check-Privacy > $null 2>&1
    
    Write-Host "`n✓ Full security audit completed!" -ForegroundColor Green
    Pause
}

function Show-Menu {
    Show-Banner
    Write-Host " ──── SECURITY ASSESSMENT ────" -ForegroundColor Magenta
    Write-Host "   1.  Port Scanner (Localhost)"
    Write-Host "   2.  Firewall Audit"
    Write-Host "   3.  User Account Audit"
    Write-Host "   4.  Service Security Audit"
    Write-Host ""
    Write-Host " ──── PROTECTION ────" -ForegroundColor Magenta
    Write-Host "   5.  Windows Defender Status"
    Write-Host "   6.  Privacy & Telemetry Check"
    Write-Host ""
    Write-Host " ──── GENERAL ────" -ForegroundColor Magenta
    Write-Host "   7.  Run Full Security Audit"
    Write-Host "   0.  Exit"
    Write-Host ""
}

function Main {
    while ($true) {
        Show-Menu
        $c = Read-Host "Select option (0-7)"
        switch ($c) {
            "1" { Scan-Ports }
            "2" { Audit-Firewall; Pause }
            "3" { Audit-Users; Pause }
            "4" { Audit-Services; Pause }
            "5" { Check-Defender }
            "6" { Check-Privacy; Pause }
            "7" { Run-FullAudit }
            "0" { Write-Host "Goodbye!" -ForegroundColor Cyan; exit }
            default { Write-Host "Invalid." -ForegroundColor Red; Pause }
        }
    }
}

Main

