# Windows Scripts Guide

Complete guide to all Windows scripts in MaddixSuite.

---

## ⚡ SysAdminSuite.ps1 — Main Toolkit (35 Options)

**Path:** `windows/SysAdminSuite.ps1`

The flagship script. An all-in-one interactive tool organized into categories.

### Diagnostic & Repair (1-8)

| Option | Function | What It Does |
|--------|----------|-------------|
| 1 | Create Restore Point | Saves system state before making changes |
| 2 | Full Diagnostic | Runs SFC + DISM + CHKDSK + Event Log check |
| 3 | SFC Scan | Scans & repairs corrupted Windows system files |
| 4 | DISM Repair | Fixes Windows system image corruption |
| 5 | DISM Online | Same as 4, but downloads clean files from Windows Update |
| 6 | CHKDSK | Checks disk for filesystem errors and bad sectors |
| 7 | Boot Repair | Fixes MBR, BCD, and boot configuration |
| 8 | Reset WU | Resets Windows Update components completely |

### Driver Management (9-13)

| Option | Function | What It Does |
|--------|----------|-------------|
| 9 | List Drivers | Shows all installed drivers with versions |
| 10 | Update Drivers | Scans Windows Update for driver updates |
| 11 | Remove Problematic | Shows non-working drivers and offers removal |
| 12 | Backup Drivers | Exports all drivers using Export-WindowsDriver |
| 13 | Restore Drivers | Imports drivers from a previous backup |

### Cleanup & Performance (14-18)

| Option | Function | What It Does |
|--------|----------|-------------|
| 14 | Clean Caches | Removes Temp, Prefetch, DNS cache |
| 15 | Disk Cleanup | Runs built-in cleanmgr.exe utility |
| 16 | Clean Prefetch | Removes Prefetch files |
| 17 | Performance Optimize | Disables visual effects, Xbox services, sets High Performance |
| 18 | SSD Optimize | Runs ReTrim on all SSD drives |

### Backup & Restore (19-22)

| Option | Function | What It Does |
|--------|----------|-------------|
| 19 | Full Backup | Registry + Drivers + BCD + Tasks + Network + Hosts |
| 20 | Registry Backup | Exports all registry hives to .reg files |
| 21 | Registry Restore | Restores registry from backup (with confirmation) |
| 22 | List Restore Points | Shows all system restore points |

### Network & Security (23-26)

| Option | Function | What It Does |
|--------|----------|-------------|
| 23 | Network Diag | Ping, DNS resolution, traceroute, connection info |
| 24 | Reset Network | Resets Winsock, TCP/IP, Firewall, flushes DNS |
| 25 | Defender Scan | Runs Windows Defender Quick Scan |
| 26 | Firewall Status | Shows firewall profiles and inbound rules |

### System Tools (27-33)

| Option | Function | What It Does |
|--------|----------|-------------|
| 27 | System Info | CPU, RAM, GPU, Disk, BIOS serial |
| 28 | Health Check | Activation status, uptime, pending reboot |
| 29 | Service Manager | List, start/stop, enable/disable services |
| 30 | Startup Manager | Shows startup programs |
| 31 | Battery Report | Generates battery health report (laptops) |
| 32 | Disk Health | SMART status, wear level, read errors |
| 33 | Memory Diag | Schedules Windows Memory Diagnostic on next boot |

### General (34-35)

| Option | Function | What It Does |
|--------|----------|-------------|
| 34 | Generate Report | Creates HTML + TXT report of diagnostic |
| 35 | Run All | Executes every repair + optimization (recommended) |

---

## 🔍 SafeDiag.ps1 — Safe Diagnostic Tool

**Path:** `windows/SafeDiag.ps1`

A **read-only first** diagnostic tool. Designed for users experiencing crashes, freezes, or BSOD.

### Phases

| Phase | Description |
|-------|-------------|
| Phase 1 | **Diagnostic (Read-Only):** Scans Event Logs, minidumps, drivers, disk health, memory, startup, services |
| Phase 2 | **Report:** Displays every issue found with category, severity, suggestion, and consequence |
| Phase 3 | **Fixes:** Each issue presented with explanation — user confirms before any change |
| Phase 4 | **Optimization:** Safe optimizations (temp clean, startup, power plan) — each requires confirmation |
| Phase 5 | **Final Report:** Generates HTML/TXT report of everything |

### Key Features
- Creates a **System Restore Point** before ANY changes
- Each fix shows: "**If we do this, X may happen**"
- Issues categorized: CRITICAL (red) / WARNING (yellow) / INFO (blue)
- Checks minidumps for BSOD cause
- Detects problematic drivers and software
- Checks disk SMART health and SSD wear level

---

## 📦 Specialized Scripts

### Maddix-RegistryTool.ps1

**Path:** `windows/Registry/Maddix-RegistryTool.ps1`

| Option | Function |
|--------|----------|
| 1 | Backup: Exports all registry hives + PowerShell snapshot + checksums |
| 2 | Restore: Select a backup, imports with restore point pre-created |
| 3 | Clean: Removes orphaned Uninstall entries, MRU lists, broken CLSID |
| 4 | Optimize: Applies performance tweaks (disable Cortana, telemetry, Bing search, startup delay) |
| 5 | Search & Replace: Find registry entries by key/value |
| 6 | Export: Export specific hives to .reg files |
| 7 | Monitor: Takes before/after snapshots of startup areas |

### Maddix-NetworkPro.ps1

**Path:** `windows/Network/Maddix-NetworkPro.ps1`

| Option | Function |
|--------|----------|
| 1 | Quick Diagnostic: Ping test, DNS resolution, interface info, latency estimate |
| 2 | Advanced: Traceroute, PathPing, TCP connections, bandwidth usage |
| 3 | WiFi Manager: Scan networks, export profiles (with passwords), forget networks |
| 4 | DNS Changer: Switch between Google, Cloudflare, OpenDNS, Quad9, or custom |
| 5 | Network Repair: Full stack reset (Winsock, TCP/IP, Firewall, DNS) |
| 6 | Connection Monitor: Real-time TCP states, top remote IPs, interface stats |
| 7 | Speed Test: Downloads test files to estimate bandwidth |

### Maddix-SystemCleaner.ps1

**Path:** `windows/Cleaner/Maddix-SystemCleaner.ps1`

| Option | Function |
|--------|----------|
| 1 | Temp Files: System Temp, Prefetch, Windows logs |
| 2 | Browser Caches: Chrome, Firefox, Edge, Discord, Slack, Teams |
| 3 | System Logs: Windows logs, Panther, SoftwareDistribution |
| 4 | Old Windows: Detects and removes Windows.old + DISM component cleanup |
| 5 | Duplicates: Scans Desktop, Downloads, Documents for duplicate files |
| 6 | Empty Folders: Removes empty directories recursively |
| 7 | Privacy Traces: Recent documents, RunMRU, clipboard, thumbnails |
| 8 | Font Cache: Rebuilds Windows font cache |
| 9 | Run All: Executes all cleaners in sequence |

### Maddix-SecurityAudit.ps1

**Path:** `windows/Security/Maddix-SecurityAudit.ps1`

| Option | Function |
|--------|----------|
| 1 | Port Scanner: Scans 20 common ports on localhost |
| 2 | Firewall Audit: Shows profiles, inbound rules, blocked connections log |
| 3 | User Audit: Local users, admin group, disabled accounts, password policy |
| 4 | Service Audit: Running services, SYSTEM-level services, insecure services |
| 5 | Defender Status: Real-time protection, signatures, last scans, threats |
| 6 | Privacy Check: Telemetry level, location/camera/mic access, advertising ID |
| 7 | Full Audit: Runs all security checks in sequence |

### Maddix-PerformanceTuner.ps1

**Path:** `windows/Optimization/Maddix-PerformanceTuner.ps1`

| Option | Function |
|--------|----------|
| 1 | CPU: Priority separation, max processor state, core unparking |
| 2 | RAM: Memory compression, large system cache, paging executive, pool usage |
| 3 | Disk: 8.3 names, last access timestamp, SSD ReTrim |
| 4 | GPU: HAGS, performance workload, visual effects, transparency |
| 5 | Startup: Boot timeout, boot UX, startup programs |
| 6 | Power: Ultimate Performance plan, sleep/hibernate config |
| 7 | Network: TCP auto-tuning, chimney, RSS, throttling |
| 8 | Run All: Applies all optimizations |

### Maddix-DockerSetup.ps1

**Path:** `windows/Docker/Maddix-DockerSetup.ps1`

| Option | Function |
|--------|----------|
| 1 | Install Docker Desktop: Downloads + WSL2 setup + silent install |
| 2 | Install/Repair WSL2: Enables WSL feature, VM platform, kernel update |
| 3 | System Info: Docker version, containers, images, resource usage |
| 4 | Pull Image: Downloads Docker images |
| 5 | Run Container: Interactive container creation with port mapping |
| 6 | Docker Compose: Run docker-compose up from any directory |
| 7 | Reset Docker: Prunes all containers, images, volumes |
| 8 | Set Resources: Configure CPU/memory limits for Docker |
| 9 | Context Manager: Create/switch Docker contexts for remote hosts |

### Backup-Restore.ps1

**Path:** `windows/Backup-Restore.ps1`

| Option | Function |
|--------|----------|
| 1 | Full Backup: Registry + Drivers + BCD + Tasks + Network + Hosts + Env Vars |
| 2 | Restore: Select backup, choose what to restore (registry, drivers, or everything) |
| 3 | List Backups: Shows all backups with sizes |

---

## Report Locations

All reports and backups are saved to:
```
%USERPROFILE%\Desktop\MaddixSuite\
├── Reports\         ← Diagnostic reports (HTML + TXT)
├── Backups\         ← System backups
├── Registry\        ← Registry exports
└── Network\         ← WiFi exports, diagnostics
```
