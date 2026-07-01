# MaddixSuite

**Created by Mohammad Mehrani (Maddix)**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-3%2B-blueviolet)]()
[![Windows](https://img.shields.io/badge/Windows-7%2F8%2F10%2F11-success)]()
[![Linux](https://img.shields.io/badge/Linux-Debian%2FRHEL%2FArch%2FSUSE-yellow)]()

[![Persian](https://img.shields.io/badge/🇮🇷-%D9%81%D8%A7%D8%B1%D8%B3%DB%8C-1a73e8?style=for-the-badge&labelColor=1a1a2e)](README.fa.md)

A comprehensive multi-platform system administration and optimization toolkit.

---

## Scripts Overview

| Script | Platform | Description |
|--------|----------|-------------|
| `windows os/SysAdminSuite.ps1` | Windows (PowerShell) | All-in-one toolkit: 35 features — diagnostic, repair, backup, network, security, optimization |
| `windows os/SysAdminSuite.cmd` | Windows (CMD/Batch) | Lightweight batch version with 18 essential tools |
| `windows os/Backup-Restore.ps1` | Windows (PowerShell) | Standalone system state backup & restore (Registry, Drivers, BCD, Network, Tasks) |
| `linux/SysAdminSuite.sh` | Linux (Bash) | Universal Linux toolkit — auto-detects Debian/Ubuntu/RHEL/Arch/openSUSE |

---

## One-Line Run (from GitHub)

### Windows (PowerShell) — SysAdminSuite
```powershell
# Full toolkit (35 options)
irm https://raw.githubusercontent.com/maddix/MaddixSuite/main/windows%20os/SysAdminSuite.ps1 | iex

# Backup & Restore tool
irm https://raw.githubusercontent.com/maddix/MaddixSuite/main/windows%20os/Backup-Restore.ps1 | iex
```

### Windows (CMD) — SysAdminSuite
```batch
@powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/maddix/MaddixSuite/main/windows%20os/SysAdminSuite.cmd | iex"
```

### Linux — SysAdminSuite
```bash
bash <(curl -s https://raw.githubusercontent.com/maddix/MaddixSuite/main/linux/SysAdminSuite.sh)
```

---

## Features by Script

### SysAdminSuite.ps1 (Windows — 35 Options)

| # | Category | Feature |
|---|----------|---------|
| 1 | Restore | Create System Restore Point |
| 2 | Diagnostic | Full Diagnostic (SFC + DISM + CHKDSK + Event Logs) |
| 3 | Repair | System File Checker (SFC) |
| 4 | Repair | DISM Image Repair |
| 5 | Repair | DISM with Online Windows Update |
| 6 | Repair | CHKDSK Disk Scan |
| 7 | Repair | Boot Records Repair (MBR/BCD) |
| 8 | Repair | Reset Windows Update Components |
| 9 | Drivers | List All Drivers |
| 10 | Drivers | Update Drivers |
| 11 | Drivers | Remove Problematic Drivers |
| 12 | Drivers | Backup All Drivers |
| 13 | Drivers | Restore Drivers from Backup |
| 14 | Cleanup | Clean Caches (Temp, Prefetch, DNS) |
| 15 | Cleanup | Disk Cleanup (cleanmgr) |
| 16 | Cleanup | Clean Prefetch |
| 17 | Performance | Apply Performance Optimizations |
| 18 | Performance | SSD Optimization (ReTrim) |
| 19 | Backup | Full System State Backup |
| 20 | Backup | Registry Backup |
| 21 | Restore | Registry Restore |
| 22 | Restore | List Restore Points |
| 23 | Network | Network Diagnostics (Ping, DNS, Trace) |
| 24 | Network | Reset Network Stack |
| 25 | Security | Windows Defender Quick Scan |
| 26 | Security | Firewall Status & Rules |
| 27 | System | System Information |
| 28 | System | System Health Check |
| 29 | System | Service Manager |
| 30 | System | Startup Manager |
| 31 | System | Battery Health Report |
| 32 | System | Disk Health (SMART) |
| 33 | System | Memory Diagnostic |
| 34 | Report | Generate Diagnostic Report |
| 35 | All | Run ALL Repairs & Optimizations |

### SysAdminSuite.cmd (Windows — 18 Options)
Lightweight CMD version: Restore Point, SFC, DISM, CHKDSK, Boot Repair, Windows Update Reset, Driver Management, Temp Cleanup, Disk Cleanup, Network Tools, Diagnostics.

### SysAdminSuite.sh (Linux — 19 Options)

| # | Category | Feature |
|---|----------|---------|
| 1 | Repair | Fix Package Manager (apt/dnf/pacman/zypper) |
| 2 | Repair | Fix Broken Packages |
| 3 | Repair | Fix Bootloader (GRUB) |
| 4 | Repair | Check Filesystem (fsck) |
| 5 | Repair | Fix Systemd Services |
| 6 | Network | Network Diagnostic |
| 7 | Network | DNS Diagnostic |
| 8 | Cleanup | Clean System (Packages, Temp, Journal) |
| 9 | Cleanup | Journal Log Cleanup |
| 10 | Optimize | Optimize Swappiness |
| 11 | Optimize | Kernel Performance Parameters |
| 12 | Backup | Backup Package List |
| 13 | Backup | Backup System Configs |
| 14 | Restore | Restore Packages |
| 15 | Security | Security Audit |
| 16 | Health | System Health |
| 17 | System | System Information |
| 18 | All | Run ALL Repairs |
| 19 | Info | Version & Update Check |

---

## Requirements

### Windows
- **OS**: Windows 7, 8, 8.1, 10, 11, Server 2012+
- **PowerShell**: Version 3.0+ (for .ps1 scripts)
- **Privileges**: **Must run as Administrator**

### Linux
- **OS**: Any major distro (Debian, Ubuntu, RHEL, CentOS, Fedora, Arch, openSUSE)
- **Dependencies**: bash, curl (for one-liner), sudo
- **Privileges**: Some features require root

---

## Project Structure

```
MaddixSuite/
├── README.md
├── LICENSE
├── run.cmd                          # Local Windows launcher
├── run-online.cmd                   # Online Windows launcher
├── windows os/
│   ├── SysAdminSuite.ps1            # Main toolkit (35 options)
│   ├── SysAdminSuite.cmd            # CMD version (18 options)
│   └── Backup-Restore.ps1           # Standalone backup tool
├── linux/
│   └── SysAdminSuite.sh             # Universal Linux toolkit
└── docs/
    └── usage.md                     # Detailed usage guide
```

---

## License

MIT License — see [LICENSE](LICENSE).

---

## Connect

- **GitHub**: [github.com/maddix](https://github.com/maddix)
- **Repository**: [github.com/mohammadmehrani/MaddixSuite](https://github.com/mohammadmehrani/MaddixSuite)
