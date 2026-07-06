# MaddixSuite

**Created by Mohammad Mehrani (Maddix)** · [![License: MIT](https://img.shields.io/badge/License-MIT-2ea44f?style=flat-square)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=flat-square&logo=PowerShell)](windows)
[![Bash](https://img.shields.io/badge/Bash-4%2B-4EAA25?style=flat-square&logo=GNU-Bash)](linux)
[![Windows CI](https://img.shields.io/github/actions/workflow/status/mohammadmehrani/MaddixSuite/test-windows.yml?label=Windows&logo=windows)](https://github.com/mohammadmehrani/MaddixSuite/actions)
[![Linux CI](https://img.shields.io/github/actions/workflow/status/mohammadmehrani/MaddixSuite/test-linux.yml?label=Linux&logo=linux)](https://github.com/mohammadmehrani/MaddixSuite/actions)
[![Lint](https://img.shields.io/github/actions/workflow/status/mohammadmehrani/MaddixSuite/lint.yml?label=Lint)](https://github.com/mohammadmehrani/MaddixSuite/actions)
[![فارسی](https://img.shields.io/badge/📖-%D9%81%D8%A7%D8%B1%D8%B3%DB%8C-1a73e8?style=flat-square)](README.fa.md)

> 🛠️ Cross-platform system administration toolkit — 300+ ID-based tools, diagnostic, repair, backup, security, optimization for **Windows** and **Linux**.
> 📖 [**Wiki & User Guide** →](wiki/Home.md)

---

## 🚀 One-Line Run

| Platform | Command |
|----------|---------|
| **Windows PowerShell** | `irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/MaddixSuite.ps1 \| iex` |
| **Linux Bash** | `bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/MaddixSuite.sh)` |

---

## 📊 CI/CD Status

| Workflow | Status |
|----------|--------|
| **Windows Tests** (Pester) | [![Windows CI](https://img.shields.io/github/actions/workflow/status/mohammadmehrani/MaddixSuite/test-windows.yml?label=Windows%20Tests)](https://github.com/mohammadmehrani/MaddixSuite/actions/workflows/test-windows.yml) |
| **Linux Tests** (BATS) | [![Linux CI](https://img.shields.io/github/actions/workflow/status/mohammadmehrani/MaddixSuite/test-linux.yml?label=Linux%20Tests)](https://github.com/mohammadmehrani/MaddixSuite/actions/workflows/test-linux.yml) |
| **Lint** (PSScriptAnalyzer + ShellCheck) | [![Lint](https://img.shields.io/github/actions/workflow/status/mohammadmehrani/MaddixSuite/lint.yml?label=Lint)](https://github.com/mohammadmehrani/MaddixSuite/actions/workflows/lint.yml) |
| **Security** (Trivy + Gitleaks) | [![Security](https://img.shields.io/github/actions/workflow/status/mohammadmehrani/MaddixSuite/security.yml?label=Security)](https://github.com/mohammadmehrani/MaddixSuite/actions/workflows/security.yml) |

---

## 📦 Script Catalog

### 🔧 BSOD 0xD1 Finder & Fixer

| Script | Description |
|--------|-------------|
| [`BSOD-Fix.ps1`](windows/BSOD-Fix.ps1) | Interactive fix for **DRIVER_IRQL_NOT_LESS_OR_EQUAL (0xD1)** caused by Intel RST (iaStorAC.sys) on hibernation resume. Auto-detects the crash pattern, offers 3 indexed solutions with recommendations, optimizes system, and supports post-reboot continuation. [![Stack Overflow](https://img.shields.io/badge/Stack%20Overflow-F58025?style=flat-square&logo=stackoverflow)](https://stackoverflow.com/questions/79974989/driver-irql-not-less-or-equal-0xd1-crash-with-null0xc8-pattern-on-hibernation-r) |
| [`BSOD-Fix.cmd`](windows/BSOD-Fix.cmd) | CMD launcher (auto-elevates PowerShell). One-liner: `irm https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/windows/BSOD-Fix.ps1 \| iex` |
| [`bsod-fix.sh`](linux/bsod-fix.sh) | Linux counterpart: kernel crash diagnostic + journal trim + temp cleanup. |

### 🪟 Windows — 200+ ID-based tools

| Category | Prefix | Description | Tools |
|----------|--------|-------------|-------|
| **Main Framework** | [`MaddixSuite.ps1`](windows/MaddixSuite.ps1) | ID-based tool loader with paginated UI, filtering, confirmation | 300+ slot |
| **System Tools** | `SYS-` | Disk health, processes, services, updates, event logs, USB, boot | 12+ |
| **Network Tools** | `NET-` | Diagnostics, WiFi, DNS, firewall, ports, VPN, bandwidth | 25+ |
| **Security Tools** | `SEC-` | Defender, firewall audit, BitLocker, anti-hack, ransomware check | 20+ |
| **Cleaner Tools** | `CLN-` | Temp files, browser cache, logs, dups, disk cleanup | 10+ |
| **Optimization** | `OPT-` | CPU, RAM, disk, startup, power, visual effects, network tuning | 10+ |
| **Backup Tools** | `BAK-` | System state, registry, files, scheduled backup, cloud upload | 10+ |
| **Dev Tools** | `DEV-` | Docker, WSL2, Git, Node, Python, VS Code, PowerShell 7 | 10+ |
| **Server Tools** | `SRV-` | Hyper-V, IIS, WSUS, RDP, Storage Spaces, Server Backup | 10+ |
| **Active Directory** | `AD-` | Domains, GPO, replication, FSMO, DNS, DHCP, certs, LAPS | 60+ |
| **Specialized** | Separate | SafeDiag, BSOD-Fix, AntiHack, Backup-Restore, RegistryTool | 9 |

### 🐧 Linux — 50+ ID-based tools

| Category | Prefix | Description | Tools |
|----------|--------|-------------|-------|
| **Main Framework** | [`MaddixSuite.sh`](linux/MaddixSuite.sh) | ID-based tool loader, cross-distro support | 50+ |
| **Specialized** | Separate | AntiHack, Hardener, Firewall, DevSetup, Docker | 5 |

---

## ⚡ Requirements

| Platform | Requirements |
|----------|-------------|
| **Windows** | PowerShell 5.1+ · Windows 10/11/Server 2016+ · **Run as Admin** |
| **Linux**  | bash 4+ · curl · sudo (some features) · Any major distro |

---

## 🧪 Test Structure

```
tests/
├── windows/                         Pester v5 tests
│   ├── MaddixSuite.Tests.ps1        Framework tests
│   ├── SafeDiag.Tests.ps1           Diagnostic tests
│   ├── Maddix-AD.Tests.ps1          AD management tests
│   ├── Maddix-AntiHack.Tests.ps1    Security scanner tests
│   ├── Maddix-Mystery.Tests.ps1     Game tests
│   ├── Backup-Restore.Tests.ps1     Backup tests
│   ├── ToolLib/SYS/                 Individual tool tests
│   ├── ToolLib/AD/                  AD tool tests
│   └── helpers/                     Test helpers and mock data
└── linux/                           BATS tests
    ├── MaddixSuite.Tests.bats       Framework tests
    ├── maddix-antihack.Tests.bats   Anti-hack tests
    ├── maddix-hardener.Tests.bats   Hardener tests
    ├── maddix-iptables.Tests.bats   Firewall tests
    ├── maddix-docker.Tests.bats     Docker tests
    ├── maddix-devsetup.Tests.bats   Dev setup tests
    └── helpers/                     Test helpers
```

---

## 📜 License

MIT — see [LICENSE](LICENSE).

---

<p align="center"><strong>github.com/mohammadmehrani/MaddixSuite</strong> · <strong>https://iodeck.ir</strong></p>
