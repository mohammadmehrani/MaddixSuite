# MaddixSuite

**Created by Mohammad Mehrani (Maddix)** · [![License: MIT](https://img.shields.io/badge/License-MIT-2ea44f?style=flat-square)](LICENSE) [![PowerShell](https://img.shields.io/badge/PowerShell-3%2B-5391FE?style=flat-square&logo=PowerShell)](windows) [![Linux](https://img.shields.io/badge/Linux-Debian%2FRHEL%2FArch-E95420?style=flat-square&logo=Linux)](linux) [![فارسی](https://img.shields.io/badge/📖-%D9%81%D8%A7%D8%B1%D8%B3%DB%8C-1a73e8?style=flat-square)](README.fa.md)

> 🛠️ Cross-platform system administration toolkit — diagnostic, repair, backup, security, optimization for **Windows** and **Linux**.

---

## 🚀 One-Line Run

| Platform | Command |
|----------|---------|
| **Windows PowerShell** | `irm https://git.io/... \| iex` |
| **Linux Bash** | `bash <(curl -s https://git.io/...)` |

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/SysAdminSuite.ps1 | iex
```

### Linux (Bash)
```bash
bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/SysAdminSuite.sh)
```

---

## 📦 Script Catalog

### 🪟 Windows (8 scripts)

| Category | Script | Features |
|----------|--------|----------|
| **Main** | [`SysAdminSuite.ps1`](windows/SysAdminSuite.ps1) | 35 options: diagnostic, repair, backup, network, security, optimization |
| **CMD** | [`SysAdminSuite.cmd`](windows/SysAdminSuite.cmd) | 18 essential tools in CMD batch |
| **Backup** | [`Backup-Restore.ps1`](windows/Backup-Restore.ps1) | Full system state backup & restore |
| **Registry** | [`Maddix-RegistryTool.ps1`](windows/Registry/Maddix-RegistryTool.ps1) | Backup, restore, clean, optimize, search |
| **Network** | [`Maddix-NetworkPro.ps1`](windows/Network/Maddix-NetworkPro.ps1) | Diagnostics, WiFi, DNS changer, speed test |
| **Cleaner** | [`Maddix-SystemCleaner.ps1`](windows/Cleaner/Maddix-SystemCleaner.ps1) | Deep clean: temp, browser, logs, duplicates |
| **Security** | [`Maddix-SecurityAudit.ps1`](windows/Security/Maddix-SecurityAudit.ps1) | Port scan, firewall, user audit, Defender |
| **Optimization** | [`Maddix-PerformanceTuner.ps1`](windows/Optimization/Maddix-PerformanceTuner.ps1) | CPU, RAM, disk, GPU, startup, network tuning |
| **Docker** | [`Maddix-DockerSetup.ps1`](windows/Docker/Maddix-DockerSetup.ps1) | Install, manage, configure Docker Desktop |

### 🐧 Linux (5 scripts)

| Category | Script | Features |
|----------|--------|----------|
| **Main** | [`SysAdminSuite.sh`](linux/SysAdminSuite.sh) | 19 options: repair, network, clean, backup, security |
| **Firewall** | [`maddix-iptables.sh`](linux/firewall/maddix-iptables.sh) | Client/server profiles, NAT, rate limit, port scan |
| **DevTools** | [`maddix-devsetup.sh`](linux/devtools/maddix-devsetup.sh) | Install editors, languages, DBs, docker, cloud CLIs |
| **Docker** | [`maddix-docker.sh`](linux/docker/maddix-docker.sh) | Install, containers, images, compose, system prune |
| **Security** | [`maddix-hardener.sh`](linux/security/maddix-hardener.sh) | SSH harden, kernel sysctl, firewall, rootkit scan |

---

## 📁 Structure

```
MaddixSuite/
├── README.md / README.fa.md
├── windows/
│   ├── SysAdminSuite.ps1           # main toolkit
│   ├── Registry/                   # Maddix-RegistryTool.ps1
│   ├── Network/                    # Maddix-NetworkPro.ps1
│   ├── Cleaner/                    # Maddix-SystemCleaner.ps1
│   ├── Security/                   # Maddix-SecurityAudit.ps1
│   ├── Optimization/               # Maddix-PerformanceTuner.ps1
│   └── Docker/                     # Maddix-DockerSetup.ps1
└── linux/
    ├── SysAdminSuite.sh            # main toolkit
    ├── firewall/                   # maddix-iptables.sh
    ├── devtools/                   # maddix-devsetup.sh
    ├── docker/                     # maddix-docker.sh
    └── security/                   # maddix-hardener.sh
```

---

## ⚡ Requirements

| Platform | Requirements |
|----------|-------------|
| **Windows** | PowerShell 3+ · Windows 7/8/10/11/Server · **Run as Admin** |
| **Linux**  | bash · curl · sudo (some features) · Any major distro |

---

## 📜 License

MIT — see [LICENSE](LICENSE).

---

<p align="center"><strong>github.com/mohammadmehrani/MaddixSuite</strong></p>
