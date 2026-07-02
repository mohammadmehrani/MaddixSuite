# Quick Start Guide

Get started with MaddixSuite in under a minute.

---

## Windows (PowerShell)

### Recommended: Run directly from GitHub

1. Press **Win + X** and select **Windows PowerShell (Admin)**
2. Paste this command and press Enter:

```powershell
irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/SysAdminSuite.ps1 | iex
```

3. The interactive menu will appear. Select options by number.

### Run Safe Diagnostic (if experiencing crashes)

```powershell
irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/SafeDiag.ps1 | iex
```

### Download & Run Locally

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/SysAdminSuite.ps1" -OutFile "$env:USERPROFILE\Desktop\SysAdminSuite.ps1"
```
Then right-click the file → **Run with PowerShell**.

### Run Any Specialized Script

```powershell
# Registry Tool
irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Registry/Maddix-RegistryTool.ps1 | iex

# Network Pro
irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Network/Maddix-NetworkPro.ps1 | iex

# System Cleaner
irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Cleaner/Maddix-SystemCleaner.ps1 | iex

# Security Audit
irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Security/Maddix-SecurityAudit.ps1 | iex

# Performance Tuner
irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Optimization/Maddix-PerformanceTuner.ps1 | iex

# Docker Setup
irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Docker/Maddix-DockerSetup.ps1 | iex

# Backup & Restore
irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/Backup-Restore.ps1 | iex
```

---

## Linux (Bash)

### Run Directly from GitHub

```bash
bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/SysAdminSuite.sh)
```

### Run Specialized Scripts

```bash
# Firewall (iptables)
sudo bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/firewall/maddix-iptables.sh)

# Dev Tools Setup
sudo bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/devtools/maddix-devsetup.sh)

# Docker Management
bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/docker/maddix-docker.sh)

# Security Hardening
sudo bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/security/maddix-hardener.sh)
```

### Download & Run Locally

```bash
curl -O https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/SysAdminSuite.sh
chmod +x SysAdminSuite.sh
sudo ./SysAdminSuite.sh
```

---

## First Time? Do This

### Windows
1. Run `SafeDiag.ps1` — scans your system, finds issues, generates a report
2. Run `SysAdminSuite.ps1` option **35** (Run All) — applies all repairs
3. Run `Maddix-PerformanceTuner.ps1` — optimize for speed

### Linux
1. Run `SysAdminSuite.sh` option **18** (Run All)
2. Run `maddix-hardener.sh` option **9** (Full Harden)
3. Run `maddix-devsetup.sh` to install development tools
