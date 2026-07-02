# Linux Scripts Guide

Complete guide to all Linux scripts in MaddixSuite.

---

## ⚡ SysAdminSuite.sh — Main Toolkit (19 Options)

**Path:** `linux/SysAdminSuite.sh`

The universal Linux toolkit. Auto-detects your distro and uses the appropriate package manager (apt/dnf/pacman/zypper).

### Diagnostic & Repair (1-5)

| Option | Function | What It Does |
|--------|----------|-------------|
| 1 | Fix Package Manager | Runs dpkg --configure, apt --fix-broken, apt update / dnf check / pacman -Syu |
| 2 | Fix Broken Packages | apt --fix-broken install, dnf reinstall, pacman -Qk |
| 3 | Fix Bootloader | Runs update-grub or grub2-mkconfig |
| 4 | Check Filesystem | Schedules fsck on next boot |
| 5 | Fix Systemd Services | Lists failed services, resets and restarts them |

### Network (6-7)

| Option | Function | What It Does |
|--------|----------|-------------|
| 6 | Network Diagnostic | Shows interfaces, routing table, DNS test |
| 7 | DNS Diagnostic | Pings 8.8.8.8, 1.1.1.1, google.com, github.com, shows resolv.conf |

### Cleanup & Optimization (8-11)

| Option | Function | What It Does |
|--------|----------|-------------|
| 8 | Clean System | Package cache, orphaned packages, journal (7 days), /tmp |
| 9 | Clean Journal | Vacuums systemd journal to 500MB |
| 10 | Optimize Swappiness | Sets vm.swappiness to 10 (better for SSD) |
| 11 | Kernel Parameters | Applies performance sysctl (TCP buffers, vfs cache, dirty ratio) |

### Backup & Restore (12-14)

| Option | Function | What It Does |
|--------|----------|-------------|
| 12 | Backup Packages | Saves list of installed packages |
| 13 | Backup Configs | Archives /etc, /home, crontab, mail + package list |
| 14 | Restore Packages | Reinstalls packages from saved list (apt dpkg/pacman) |

### Security & Health (15-17)

| Option | Function | What It Does |
|--------|----------|-------------|
| 15 | Security Audit | Shows open ports, failed SSH logins, last logins |
| 16 | System Health | Uptime, load, memory, disk, zombie processes |
| 17 | System Info | Kernel, CPU, RAM, shell, package count |

### General (18-19)

| Option | Function |
|--------|----------|
| 18 | Run All: Executes all repairs + cleanup + health check |
| 19 | Version: Shows script version, GitHub link, update command |

---

## 🔥 maddix-iptables.sh — Firewall Manager

**Path:** `linux/firewall/maddix-iptables.sh`

Full iptables firewall management with built-in profiles.

### Profiles

| Profile | Description | Rules |
|---------|-------------|-------|
| Client | Desktop safe | Allows outgoing everything, blocks incoming except established + ping |
| Server | Hardened | Blocks incoming + SSH brute-force protection + syn flood + port scan |
| Minimal | Block all incoming | Allow loopback + established + ping |

### Manual Rules

| Option | Function |
|--------|----------|
| Custom Port | Add any port/protocol/direction with ACCEPT or DROP |
| Block IP | Blocks an IP on both INPUT and OUTPUT |
| Rate Limit | Limits connections per second on a port |
| NAT/Port Forward | Forward external port to internal IP:port |

### Additional Features
- SSH brute-force protection (5 attempts in 60s = block)
- Syn flood protection (1/s limit)
- Port scan detection (NULL flag, XMAS flag)
- Docker bridge auto-allow
- Persistent save to `/etc/iptables/rules.v4`

---

## 🛠️ maddix-devsetup.sh — Dev Tools Installer

**Path:** `linux/devtools/maddix-devsetup.sh`

Installs developer tools by category. Auto-detects distro and uses correct package manager.

### Categories

| Category | Tools |
|----------|-------|
| Editors | vim, neovim, nano, emacs, VSCode |
| Languages | gcc, g++, python3, pip, nodejs, npm, rustc, go, openjdk-17, php, ruby, perl |
| Shell Tools | curl, wget, git, htop, tmux, zsh, fish, tree, jq, yq, ripgrep, fd-find, fzf |
| Databases | mysql-server, postgresql, redis, mongodb, sqlite3 |
| Network | nmap, net-tools, tcpdump, wireshark, iperf3, openssh, dnsutils |
| Docker | docker.io, docker-compose |
| Cloud CLIs | awscli, azure-cli, doctl, kubectl |
| Media | ffmpeg, imagemagick, vlc, gimp, inkscape |

Each category shows which tools are already installed vs missing, then asks before installing.

---

## 🐳 maddix-docker.sh — Docker Manager

**Path:** `linux/docker/maddix-docker.sh`

Complete Docker management for Linux.

### Features

| Option | Function |
|--------|----------|
| 1 | Install Docker: Auto-detects distro and installs Docker Engine |
| 2 | Container Manager: Start, stop, restart, remove, logs, exec |
| 3 | Image Manager: Pull, remove, build, search Docker Hub |
| 4 | System Manager: Prune, volumes, networks, docker compose |
| 5 | Quick Stats: Shows CPU/memory/network usage per container |

### Supported Distros for Installation
- Debian, Ubuntu, Linux Mint
- Fedora, RHEL, CentOS
- Arch Linux, Manjaro
- openSUSE

---

## 🔒 maddix-hardener.sh — Security Hardening

**Path:** `linux/security/maddix-hardener.sh`

Linux security hardening toolkit.

### Security Audits

| Option | Function |
|--------|----------|
| 1 | Open Ports: Scans listening services, optionally enables firewall |
| 2 | SSH Audit: Checks root login, password auth, applies secure config |
| 3 | User Audit: UID 0 users, empty passwords, sudo group, failed logins |
| 4 | System Updates: Checks available updates, installs security updates |

### Hardening Actions

| Option | Function |
|--------|----------|
| 5 | Kernel Hardening: Applies sysctl settings (IP spoofing, ICMP redirects, SYN cookies, disable IPv6) |
| 6 | File Permissions: Hardens /etc/shadow, /etc/passwd, /etc/ssh, /root, sudoers |
| 7 | Firewall Setup: Installs/configure UFW with default-deny incoming |
| 8 | Malware Scan: Installs ClamAV + freshclam, scans /home and /tmp |

---

## Report & Backup Locations

```
~/MaddixSuite/
├── Reports/         ← Diagnostic logs
├── Backups/         ← Package lists, config archives
```
