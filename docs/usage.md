# MaddixSuite Usage Guide

## One-Line Run

| Platform | Command |
|----------|---------|
| **Windows PowerShell** | `irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/SysAdminSuite.ps1 \| iex` |
| **Windows CMD** | `powershell -NoProfile -Exec Bypass -Command "irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/SysAdminSuite.cmd \| iex"` |
| **Linux** | `bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/SysAdminSuite.sh)` |

## Scripts Quick Reference

### Windows — SysAdminSuite.ps1 (35 Options)

| # | Operation |
|---|-----------|
| 1-8 | **Repair**: Restore Point, Full Diagnostic, SFC, DISM, CHKDSK, Boot Repair, Reset WU |
| 9-13 | **Drivers**: List, Update, Remove, Backup, Restore |
| 14-18 | **Cleanup**: Caches, Disk Cleanup, Prefetch, Performance, SSD |
| 19-22 | **Backup**: System State, Registry backup/restore, List Restore Points |
| 23-26 | **Network/Security**: Diagnostics, Reset, Defender, Firewall |
| 27-33 | **System**: Info, Health, Services, Startup, Battery, SMART, Memory |
| 34-35 | **Report**: Generate, Run All |

### Windows — Other Scripts

| Script | Quick Start |
|--------|-------------|
| `Maddix-RegistryTool.ps1` | `irm .../Registry/Maddix-RegistryTool.ps1 \| iex` |
| `Maddix-NetworkPro.ps1` | `irm .../Network/Maddix-NetworkPro.ps1 \| iex` |
| `Maddix-SystemCleaner.ps1` | `irm .../Cleaner/Maddix-SystemCleaner.ps1 \| iex` |
| `Maddix-SecurityAudit.ps1` | `irm .../Security/Maddix-SecurityAudit.ps1 \| iex` |
| `Maddix-PerformanceTuner.ps1` | `irm .../Optimization/Maddix-PerformanceTuner.ps1 \| iex` |
| `Maddix-DockerSetup.ps1` | `irm .../Docker/Maddix-DockerSetup.ps1 \| iex` |
| `Backup-Restore.ps1` | `irm .../Backup-Restore.ps1 \| iex` |

### Linux — SysAdminSuite.sh (19 Options)

| # | Operation |
|---|-----------|
| 1-5 | **Repair**: Package Manager, Broken Packages, GRUB, Filesystem, Systemd |
| 6-7 | **Network**: Diagnostic, DNS |
| 8-11 | **Cleanup/Optimize**: System Clean, Journal, Swappiness, Kernel Params |
| 12-14 | **Backup/Restore**: Package List, Configs, Restore Packages |
| 15-17 | **Security/Health**: Audit, Health, System Info |
| 18-19 | **General**: Run All, Version |

### Linux — Other Scripts

| Script | Purpose |
|--------|---------|
| `maddix-iptables.sh` | Firewall profiles (client/server), NAT, port/rate management |
| `maddix-devsetup.sh` | Install dev tools by category (editors, languages, DBs, docker, cloud) |
| `maddix-docker.sh` | Docker install, containers, images, compose, system prune |
| `maddix-hardener.sh` | SSH hardening, kernel sysctl, firewall, ClamAV, rootkit scan |

## Locations

- **Reports**: `%USERPROFILE%\Desktop\MaddixSuite\Reports\`
- **Backups**: `%USERPROFILE%\Desktop\MaddixSuite\Backups\`
- **Linux logs**: `~/MaddixSuite/Reports/`
