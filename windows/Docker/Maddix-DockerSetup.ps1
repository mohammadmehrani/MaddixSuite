<#
.SYNOPSIS
    Maddix-DockerSetup - Docker Desktop Installer & Manager for Windows
.DESCRIPTION
    Installing, configuring and managing Docker on Windows by Mohammad Mehrani (Maddix).
    Features: download & install Docker Desktop, WSL2 setup, container management,
    resource limits, context switching, and troubleshooting.
.NOTES
    Version: 1.0
    Author: Mohammad Mehrani (Maddix)
    Part of MaddixSuite: https://github.com/mohammadmehrani/MaddixSuite
    One-liner: irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Docker/Maddix-DockerSetup.ps1 | iex
#>

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
    Write-Host "  Maddix-DockerSetup v1.0 · Docker for Windows" -ForegroundColor Cyan
    Write-Host "  Created by Mohammad Mehrani (Maddix)" -ForegroundColor Cyan
    Write-Host "████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host ""
}

function Check-Docker {
    try {
        $v = docker --version 2>$null
        if ($v) { return $true }
    } catch {}
    return $false
}

function Check-WSL2 {
    try {
        $k = wsl -l -v 2>$null
        return ($k -match "2")
    } catch { return $false }
}

function Install-WSL2 {
    Write-Host "`n=== INSTALLING WSL2 ===" -ForegroundColor Cyan
    Write-Host "[1/3] Enable WSL feature..." -ForegroundColor Yellow
    dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /quiet /norestart 2>$null | Out-Null
    Write-Host "  WSL feature enabled" -ForegroundColor Green
    
    Write-Host "[2/3] Enable Virtual Machine Platform..." -ForegroundColor Yellow
    dism /online /enable-feature /featurename:VirtualMachinePlatform /all /quiet /norestart 2>$null | Out-Null
    Write-Host "  VM Platform enabled" -ForegroundColor Green
    
    Write-Host "[3/3] Download WSL2 kernel..." -ForegroundColor Yellow
    try {
        $kernelUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
        $kernelPath = "$env:TEMP\wsl_update_x64.msi"
        Invoke-WebRequest -Uri $kernelUrl -OutFile $kernelPath -UseBasicParsing
        Start-Process msiexec.exe -ArgumentList "/i $kernelPath /quiet /norestart" -Wait
        wsl --set-default-version 2
        Write-Host "  WSL2 ready" -ForegroundColor Green
    } catch { Write-Host "  Failed: $_" -ForegroundColor Red }
}

function Install-DockerDesktop {
    Write-Host "`n=== INSTALLING DOCKER DESKTOP ===" -ForegroundColor Cyan
    
    if (Check-Docker) {
        Write-Host "Docker already installed: $(docker --version)" -ForegroundColor Green
        return
    }
    
    Write-Host "[1/2] Checking WSL2..." -ForegroundColor Yellow
    if (-not (Check-WSL2)) {
        Write-Host "  WSL2 not ready. Setting up..." -ForegroundColor Yellow
        Install-WSL2
    } else {
        Write-Host "  WSL2 OK" -ForegroundColor Green
    }
    
    Write-Host "[2/2] Downloading Docker Desktop..." -ForegroundColor Yellow
    $url = "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
    $installer = "$env:TEMP\DockerDesktopInstaller.exe"
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing
        Write-Host "  Downloaded. Installing (silent)..." -ForegroundColor Gray
        Start-Process $installer -ArgumentList "install --quiet --accept-license" -Wait
        Write-Host "  Docker Desktop installed!" -ForegroundColor Green
        Write-Host "  Please log out and back in to complete setup." -ForegroundColor Yellow
    } catch {
        Write-Host "  Failed: $_" -ForegroundColor Red
        Write-Host "  Download manually: https://desktop.docker.com/win/stable/Docker Desktop Installer.exe" -ForegroundColor Yellow
    }
    Pause
}

function Docker-Info {
    if (-not (Check-Docker)) { Write-Host "Docker not installed." -ForegroundColor Red; return }
    
    Write-Host "`n=== DOCKER SYSTEM INFO ===" -ForegroundColor Cyan
    docker info --format "OS/Arch: {{.OSType}}/{{.Architecture}}" 2>$null
    docker info --format "Server: {{.ServerVersion}}" 2>$null
    docker info --format "Containers: {{.Containers}}" 2>$null
    docker info --format "Images: {{.Images}}" 2>$null
    docker info --format "Storage: {{.Driver}}" 2>$null
    
    Write-Host "`nResource Usage:" -ForegroundColor Yellow
    docker system df 2>$null
    
    Write-Host "`nRunning Containers:" -ForegroundColor Yellow
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>$null
    
    Write-Host "`nCPU/Memory Limits:" -ForegroundColor Yellow
    $settings = "$env:APPDATA\Docker\settings.json"
    if (Test-Path $settings) {
        $j = Get-Content $settings | ConvertFrom-Json
        Write-Host "  CPUs: $($j.cpus)" -ForegroundColor Gray
        Write-Host "  Memory: $($j.memoryMiB) MB" -ForegroundColor Gray
    }
}

function Docker-PullImage {
    $img = Read-Host "Image name (e.g., nginx:latest)"
    if ($img) {
        Write-Host "Pulling $img..." -ForegroundColor Yellow
        docker pull $img
    }
}

function Docker-RunContainer {
    $img = Read-Host "Image name"
    $name = Read-Host "Container name"
    $port = Read-Host "Port mapping (e.g., 8080:80)"
    $detach = Read-Host "Run in background? (y/n)"
    $d = if ($detach -eq 'y') { "-d" } else { "" }
    
    if ($img -and $port) {
        docker run $d --name $name -p $port $img
    }
}

function Docker-ComposeUp {
    $path = Read-Host "Path to docker-compose.yml (or . for current)"
    if (-not $path) { $path = "." }
    Push-Location $path
    docker compose up -d 2>$null || docker-compose up -d 2>$null
    Pop-Location
}

function Docker-Reset {
    Write-Host "`n=== DOCKER RESET ===" -ForegroundColor Cyan
    Write-Host "WARNING: This removes ALL containers, images, volumes" -ForegroundColor Red
    $confirm = Read-Host "Type RESET to confirm"
    if ($confirm -eq "RESET") {
        docker system prune -a -f --volumes
        Write-Host "Docker reset completed." -ForegroundColor Green
    }
    Pause
}

function Docker-SetResource {
    Write-Host "`n=== SET DOCKER RESOURCES ===" -ForegroundColor Cyan
    $settings = "$env:APPDATA\Docker\settings.json"
    if (-not (Test-Path $settings)) { Write-Host "Settings not found. Start Docker Desktop first." -ForegroundColor Red; Pause; return }
    
    $cpu = Read-Host "CPU cores (default: all)"
    $mem = Read-Host "Memory in MB (e.g., 4096)"
    
    $j = Get-Content $settings | ConvertFrom-Json
    if ($cpu) { $j.cpus = [int]$cpu }
    if ($mem) { $j.memoryMiB = [int]$mem }
    $j | ConvertTo-Json | Set-Content $settings
    
    Write-Host "Settings updated. Restart Docker Desktop." -ForegroundColor Yellow
    Pause
}

function Docker-Context {
    Write-Host "`n=== DOCKER CONTEXT MANAGER ===" -ForegroundColor Cyan
    docker context ls 2>$null
    Write-Host ""
    $name = Read-Host "Create new context? (name or Enter to skip)"
    if ($name) {
        $host = Read-Host "Docker host (e.g., tcp://192.168.1.100:2375)"
        docker context create $name --docker "host=$host"
        docker context use $name
        Write-Host "Context '$name' created and selected." -ForegroundColor Green
    }
    Pause
}

function Show-Menu {
    Show-Banner
    if (Check-Docker) {
        Write-Host "  Status: $(docker --version)" -ForegroundColor Green
    } else {
        Write-Host "  Status: NOT INSTALLED" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host " ──── SETUP ────" -ForegroundColor Magenta
    Write-Host "   1.  Install Docker Desktop (with WSL2)"
    Write-Host "   2.  Install/Repair WSL2"
    Write-Host ""
    Write-Host " ──── MANAGEMENT ────" -ForegroundColor Magenta
    Write-Host "   3.  Docker System Info & Usage"
    Write-Host "   4.  Pull Docker Image"
    Write-Host "   5.  Run a Container"
    Write-Host "   6.  Docker Compose Up"
    Write-Host "   7.  Reset Docker (prune all)"
    Write-Host "   8.  Set CPU/Memory Limits"
    Write-Host "   9.  Docker Context Manager"
    Write-Host ""
    Write-Host " ──── GENERAL ────" -ForegroundColor Magenta
    Write-Host "   0.  Exit"
    Write-Host ""
}

function Main {
    while ($true) {
        Show-Menu
        $c = Read-Host "Select (0-9)"
        switch ($c) {
            "1" { Install-DockerDesktop }
            "2" { Install-WSL2; Pause }
            "3" { Docker-Info; Pause }
            "4" { Docker-PullImage; Pause }
            "5" { Docker-RunContainer; Pause }
            "6" { Docker-ComposeUp; Pause }
            "7" { Docker-Reset }
            "8" { Docker-SetResource }
            "9" { Docker-Context }
            "0" { Write-Host "Goodbye!" -ForegroundColor Cyan; exit }
            default { Write-Host "Invalid." -ForegroundColor Red; Pause }
        }
    }
}

Main
