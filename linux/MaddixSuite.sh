#!/bin/bash
# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
# Linux Unified Toolkit — System Admin Suite
# Run: bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/MaddixSuite.sh)

# ─── COLORS ───
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'
GRAY='\033[1;30m'; WHITE='\033[1;37m'; NC='\033[0m'
BOLD='\033[1m'

SCRIPT_VERSION="3.0"
PENDING_REBOOT=false

# ─── HELPERS ───
header() { echo -e "\n${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"; echo -e "${CYAN}║  $1${NC}"; echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"; }
info() { echo -e "  ${GRAY}$1${NC}"; }
ok() { echo -e "  ${GREEN}[+] $1${NC}"; }
warn() { echo -e "  ${YELLOW}[!] $1${NC}"; }
crit() { echo -e "  ${RED}[!!] $1${NC}"; }
log_msg=""
log() { local m="$1"; local t="${2:-INFO}"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$t] $m" >> "$log_file"; }

confirm() {
    echo -en "  ${YELLOW}$1 (Y/N): ${NC}"; read -r r
    [[ "$r" =~ ^[Yy]$ ]]
}

pause() { echo -e "\n  ${GRAY}Press Enter to continue...${NC}"; read -r; }

# ─── AUTO-ELEVATE ───
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}  Not root. Elevating...${NC}"
    exec sudo "$0" "$@"
    exit
fi

# ─── SYSTEM DETECTION ───
detect_system() {
    if [ -f /etc/os-release ]; then . /etc/os-release; OS_NAME="$PRETTY_NAME"; OS_ID="$ID"; OS_VERSION="$VERSION_ID"
    else OS_NAME="Unknown Linux"; OS_ID="unknown"; fi

    case "$OS_ID" in
        debian|ubuntu|mint|kali) PKG_MGR="apt"; INSTALL="apt-get install -y"; UPDATE="apt-get update" ;;
        fedora|rhel|centos) PKG_MGR="dnf"; INSTALL="dnf install -y"; UPDATE="dnf check-update" ;;
        arch|manjaro) PKG_MGR="pacman"; INSTALL="pacman -S --noconfirm"; UPDATE="pacman -Sy" ;;
        opensuse|suse) PKG_MGR="zypper"; INSTALL="zypper install -y"; UPDATE="zypper refresh" ;;
        *) PKG_MGR="apt"; INSTALL="apt-get install -y"; UPDATE="apt-get update" ;;
    esac

    CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs)
    CPU_CORES=$(nproc 2>/dev/null || echo "?")
    RAM_TOTAL=$(free -h | awk '/^Mem:/{print $2}')
    RAM_FREE=$(free -h | awk '/^Mem:/{print $7}')
    DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
    DISK_FREE=$(df -h / | awk 'NR==2{print $4}')
    KERNEL=$(uname -r)
    HOSTNAME=$(hostname)
    UPTIME=$(uptime -p | sed 's/up //')
    IP_ADDR=$(ip route get 1 2>/dev/null | grep -oP 'src \K\S+' || echo "N/A")
    IS_VM=$(grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null && echo "Yes" || echo "No")
    IS_SERVER=false
    [[ "$OS_NAME" =~ (Server|Red Hat|CentOS|Rocky|Alma|Debian.*server) ]] && IS_SERVER=true
}

# ─── LOGGING ───
BASE_DIR="$HOME/MaddixSuite"
LOG_DIR="$BASE_DIR/Reports"
BACKUP_DIR="$BASE_DIR/Backups"
mkdir -p "$LOG_DIR" "$BACKUP_DIR"
log_file="$LOG_DIR/MaddixSuite_$(date +%Y%m%d_%H%M%S).log"

# ─── BANNER ───
show_banner() {
    clear
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    4D 61 64 64 69 78 53 75 69 74 65                      ║${NC}"
    echo -e "${CYAN}║    M  a  d  d  i  x  S  u  i  t  e                      ║${NC}"
    echo -e "${CYAN}║    ${BOLD}Linux Edition v${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}║    https://iodeck.ir | https://github.com/...MaddixSuite ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
}

# ─── SYSTEM INFO DISPLAY ───
show_system_info() {
    header "SYSTEM INFORMATION"
    echo -e "  ${WHITE}Hostname:${NC}  ${GRAY}$HOSTNAME${NC}"
    echo -e "  ${WHITE}OS:${NC}        ${GRAY}$OS_NAME (Kernel: $KERNEL)${NC}"
    echo -e "  ${WHITE}CPU:${NC}       ${GRAY}$CPU_MODEL ($CPU_CORES cores)${NC}"
    echo -e "  ${WHITE}RAM:${NC}       ${GRAY}$RAM_TOTAL total / $RAM_FREE free${NC}"
    echo -e "  ${WHITE}Disk /:${NC}    ${GRAY}$DISK_TOTAL total / $DISK_FREE free${NC}"
    echo -e "  ${WHITE}IP:${NC}        ${GRAY}$IP_ADDR${NC}"
    echo -e "  ${WHITE}Uptime:${NC}    ${GRAY}$UPTIME${NC}"
    echo -e "  ${WHITE}Virtual:${NC}   ${GRAY}$IS_VM${NC}"
    echo -e "  ${WHITE}Log:${NC}       ${GRAY}$log_file${NC}"
    echo -e "  ${CYAN}  ──────────────────────────────${NC}"
    log "System info displayed"
}

# ─── MENU ───
show_menu() {
    show_banner
    local edition="CLIENT"
    $IS_SERVER && edition="SERVER"
    echo -e "  ${GRAY}Mode: $edition | Log: $log_file${NC}"
    echo ""
    echo -e " ${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e " ${BLUE}│${NC}  SYS-001  System Information Display                       ${NC}"
    echo -e " ${BLUE}│${NC}  SYS-002  System Update & Upgrade                          ${NC}"
    echo -e " ${BLUE}│${NC}  SYS-003  Package Manager Fix                              ${NC}"
    echo -e " ${BLUE}│${NC}  SYS-004  Broken Packages Fix                              ${NC}"
    echo -e " ${BLUE}│${NC}  SYS-005  Bootloader Repair (GRUB)                         ${NC}"
    echo -e " ${BLUE}│${NC}  SYS-006  Filesystem Check (fsck)                          ${NC}"
    echo -e " ${BLUE}│${NC}  SYS-007  Systemd Services Manager                         ${NC}"
    echo -e " ${BLUE}│${NC}  SYS-008  Kernel Parameters Tuning                         ${NC}"
    echo -e " ${BLUE}│${NC}  SYS-009  Service Status & Logs                            ${NC}"
    echo -e " ${BLUE}│${NC}  SYS-010  Disk Usage Analyzer (du/df)                      ${NC}"
    echo -e " ${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e " ${GREEN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e " ${GREEN}│${NC}  NET-001  Network Diagnostic (ping, DNS, interfaces)      ${NC}"
    echo -e " ${GREEN}│${NC}  NET-002  Firewall Manager (iptables/ufw)                 ${NC}"
    echo -e " ${GREEN}│${NC}  NET-003  DNS Config & Test                               ${NC}"
    echo -e " ${GREEN}│${NC}  NET-004  Port Scanner (netstat/ss)                       ${NC}"
    echo -e " ${GREEN}│${NC}  NET-005  WiFi Manager (nmcli)                            ${NC}"
    echo -e " ${GREEN}│${NC}  NET-006  Network Speed Test                              ${NC}"
    echo -e " ${GREEN}│${NC}  NET-007  Traceroute & Path Analysis                      ${NC}"
    echo -e " ${GREEN}│${NC}  NET-008  ARP Table & MAC Scanner                         ${NC}"
    echo -e " ${GREEN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e " ${RED}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e " ${RED}│${NC}  SEC-001  Security Audit (ports, SSH, users)             ${NC}"
    echo -e " ${RED}│${NC}  SEC-002  Anti-Hack Scanner (rootkits, keyloggers)       ${NC}"
    echo -e " ${RED}│${NC}  SEC-003  SSH Hardening                                  ${NC}"
    echo -e " ${RED}│${NC}  SEC-004  Firewall Setup (UFW/iptables profiles)         ${NC}"
    echo -e " ${RED}│${NC}  SEC-005  Malware Scan (ClamAV)                          ${NC}"
    echo -e " ${RED}│${NC}  SEC-006  File Integrity Check                           ${NC}"
    echo -e " ${RED}│${NC}  SEC-007  User & Group Audit                             ${NC}"
    echo -e " ${RED}│${NC}  SEC-008  SUID/SGID Scanner                              ${NC}"
    echo -e " ${RED}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e " ${YELLOW}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e " ${YELLOW}│${NC}  CLN-001  System Cleanup (packages, temp, journal)      ${NC}"
    echo -e " ${YELLOW}│${NC}  CLN-002  Journal Log Cleanup                           ${NC}"
    echo -e " ${YELLOW}│${NC}  CLN-003  Orphaned Package Removal                      ${NC}"
    echo -e " ${YELLOW}│${NC}  CLN-004  Docker Cleanup (prune)                        ${NC}"
    echo -e " ${YELLOW}│${NC}  CLN-005  Cache & Temp Files Cleaner                    ${NC}"
    echo -e " ${YELLOW}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e " ${MAGENTA}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e " ${MAGENTA}│${NC}  OPT-001  Swappiness Optimizer                          ${NC}"
    echo -e " ${MAGENTA}│${NC}  OPT-002  Kernel Performance Tuning                     ${NC}"
    echo -e " ${MAGENTA}│${NC}  OPT-003  I/O Scheduler Tuning                          ${NC}"
    echo -e " ${MAGENTA}│${NC}  OPT-004  CPU Governor Tuning                           ${NC}"
    echo -e " ${MAGENTA}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e " ${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e " ${CYAN}│${NC}  BAK-001  Package List Backup                            ${NC}"
    echo -e " ${CYAN}│${NC}  BAK-002  Config Backup (/etc, /home)                    ${NC}"
    echo -e " ${CYAN}│${NC}  BAK-003  Enhanced Backup (DB + Files + Archive + Upload)${NC}"
    echo -e " ${CYAN}│${NC}  BAK-004  Database Backup (MySQL/PostgreSQL)             ${NC}"
    echo -e " ${CYAN}│${NC}  BAK-005  Remote Upload (FTP/S3)                         ${NC}"
    echo -e " ${CYAN}│${NC}  BAK-006  Restore Packages from Backup                   ${NC}"
    echo -e " ${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e " ${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e " ${BLUE}│${NC}  DEV-001  Fish Shell Install                             ${NC}"
    echo -e " ${BLUE}│${NC}  DEV-002  Docker Install & Manager                       ${NC}"
    echo -e " ${BLUE}│${NC}  DEV-003  Development Tools Installer                    ${NC}"
    echo -e " ${BLUE}│${NC}  DEV-004  Git Repository Manager                         ${NC}"
    echo -e " ${BLUE}│${NC}  DEV-005  Node.js / Python / Language Setup              ${NC}"
    echo -e " ${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    if $IS_SERVER; then
    echo -e " ${RED}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e " ${RED}│${NC}  SRV-001  Samba AD Domain Controller Setup               ${NC}"
    echo -e " ${RED}│${NC}  SRV-002  DNS Server (Bind) Setup                         ${NC}"
    echo -e " ${RED}│${NC}  SRV-003  DHCP Server Setup                               ${NC}"
    echo -e " ${RED}│${NC}  SRV-004  Web Server (Nginx/Apache)                       ${NC}"
    echo -e " ${RED}│${NC}  SRV-005  Database Server (MySQL/PostgreSQL)              ${NC}"
    echo -e " ${RED}│${NC}  SRV-006  Mail Server (Postfix)                           ${NC}"
    echo -e " ${RED}│${NC}  SRV-007  Monitoring Server (Prometheus/Netdata)          ${NC}"
    echo -e " ${RED}│${NC}  SRV-008  Backup Server (Borg/Restic)                     ${NC}"
    echo -e " ${RED}└─────────────────────────────────────────────────────────────┘${NC}"
    fi
    echo ""
    echo -e "  ${YELLOW}Search: s <keyword> | Help: help | Page: n/p | Quit: q${NC}"
    echo -e "  ${GRAY}Type an ID (e.g., SYS-001) to run that tool.${NC}"
    echo ""
}

# ─── TOOL FUNCTIONS ───

# SYS-001: System Info
sys_info() { show_system_info; pause; }

# SYS-002: Update System
sys_update() {
    header "SYSTEM UPDATE"
    if confirm "Update package lists?"; then $UPDATE 2>&1 | tail -5; ok "Package lists updated"; fi
    if confirm "Upgrade all packages?"; then
        case "$PKG_MGR" in
            apt) apt-get upgrade -y; apt-get dist-upgrade -y ;;
            dnf) dnf upgrade -y ;;
            pacman) pacman -Su --noconfirm ;;
            zypper) zypper update -y ;;
        esac
        ok "System upgraded"; log "System upgraded" "SUCCESS"
    fi
    pause
}

# SYS-003: Package Manager Fix
sys_pkgfix() {
    header "PACKAGE MANAGER FIX"
    case "$PKG_MGR" in
        apt)
            dpkg --configure -a
            apt-get --fix-broken install -y
            apt-get update ;;
        dnf) dnf check ;;
        pacman) pacman -Sy ;;
        zypper) zypper refresh ;;
    esac
    ok "Package manager fixed"; log "Pkg manager fixed" "SUCCESS"
    pause
}

# SYS-004: Broken Packages
sys_broken() {
    header "BROKEN PACKAGES"
    case "$PKG_MGR" in
        apt) apt-get --fix-broken install -y; apt-get autoremove -y ;;
        dnf) dnf reinstall $(dnf repoquery --unsatisfied 2>/dev/null) ;;
        pacman) pacman -Qk 2>/dev/null | grep -v "0 missing" ;;
    esac
    ok "Broken packages fixed"; log "Broken packages fixed" "SUCCESS"
    pause
}

# SYS-005: Bootloader
sys_bootloader() {
    header "BOOTLOADER REPAIR"
    if confirm "Reinstall GRUB?"; then
        if [ -d /sys/firmware/efi ]; then
            case "$PKG_MGR" in
                apt) apt-get install --reinstall grub-efi -y; update-grub ;;
                dnf) dnf reinstall grub2-efi -y; grub2-mkconfig -o /boot/grub2/grub.cfg ;;
                pacman) pacman -S --noconfirm grub; grub-mkconfig -o /boot/grub/grub.cfg ;;
            esac
        else
            case "$PKG_MGR" in
                apt) apt-get install --reinstall grub-pc -y; update-grub ;;
                dnf) dnf reinstall grub2 -y; grub2-mkconfig -o /boot/grub2/grub.cfg ;;
                pacman) pacman -S --noconfirm grub; grub-mkconfig -o /boot/grub/grub.cfg ;;
            esac
        fi
        ok "GRUB reinstalled"; log "GRUB reinstalled" "SUCCESS"
    fi
    pause
}

# SYS-006: Filesystem Check
sys_fsck() {
    header "FILESYSTEM CHECK"
    if confirm "Schedule fsck on next boot?"; then
        touch /forcefsck
        ok "fsck scheduled on next boot"; log "fsck scheduled" "SUCCESS"
        PENDING_REBOOT=true
    fi
    pause
}

# SYS-007: Systemd Manager
sys_systemd() {
    header "SYSTEMD SERVICES"
    echo -e "  ${WHITE}Failed services:${NC}"
    systemctl --failed
    echo ""
    echo -e "  ${WHITE}Options:${NC}"
    echo -e "    ${GRAY}1) List all running services${NC}"
    echo -e "    ${GRAY}2) Restart a service${NC}"
    echo -e "    ${GRAY}3) View service logs${NC}"
    echo -e "    ${GRAY}4) Reset failed services${NC}"
    read -p "  Select: " sc
    case "$sc" in
        1) systemctl list-units --type=service --state=running ;;
        2) read -p "  Service name: " svc; systemctl restart "$svc"; ok "$svc restarted" ;;
        3) read -p "  Service name: " svc; journalctl -u "$svc" --no-pager -n 50 ;;
        4) systemctl reset-failed; ok "Failed services reset" ;;
    esac
    log "Systemd operation: $sc"
    pause
}

# NET-001: Network Diagnostic
net_diag() {
    header "NETWORK DIAGNOSTIC"
    echo -e "  ${WHITE}Interfaces:${NC}"
    ip addr show | grep -E "^[0-9]|inet " | head -20
    echo ""; echo -e "  ${WHITE}Routing:${NC}"
    ip route show | head -10
    echo ""; echo -e "  ${WHITE}DNS Test:${NC}"
    if command -v nslookup &>/dev/null; then
        nslookup google.com 2>/dev/null | head -6 || echo "  DNS resolution failed (offline?)"
    fi
    echo ""; echo -e "  ${WHITE}Connectivity:${NC}"
    ping -c 2 -W 2 8.8.8.8 2>/dev/null && echo "  Internet: OK" || echo "  Internet: FAIL"
    log "Network diagnostic run"
    pause
}

# NET-002: Firewall Manager
net_firewall() {
    header "FIREWALL MANAGER"
    if command -v ufw &>/dev/null; then
        ufw status verbose
        if confirm "Enable/configure UFW?"); then
            ufw default deny incoming
            ufw default allow outgoing
            ufw allow ssh
            read -p "  Additional port to allow (e.g., 80,443): " p
            [ -n "$p" ] && ufw allow "$p"
            ufw --force enable
            ok "UFW configured"; log "UFW configured" "SUCCESS"
        fi
    elif command -v iptables &>/dev/null; then
        iptables -L -n --line-numbers | head -30
        echo ""
        if confirm "Apply default secure rules?"); then
            iptables -P INPUT DROP
            iptables -P FORWARD DROP
            iptables -P OUTPUT ACCEPT
            iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
            iptables -A INPUT -i lo -j ACCEPT
            iptables -A INPUT -p tcp --dport 22 -j ACCEPT
            if command -v iptables-save &>/dev/null; then
                iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
            fi
            ok "iptables secure rules applied"; log "iptables configured" "SUCCESS"
        fi
    else
        warn "No firewall found. Install ufw or iptables."
        if confirm "Install ufw?"); then
            $INSTALL ufw
            ok "ufw installed"
        fi
    fi
    pause
}

# SEC-001: Security Audit
sec_audit() {
    header "SECURITY AUDIT"
    echo -e "  ${WHITE}Open Ports:${NC}"
    ss -tlnp 2>/dev/null | head -20 || netstat -tlnp 2>/dev/null | head -20
    echo ""; echo -e "  ${WHITE}Failed SSH Logins:${NC}"
    [ -f /var/log/auth.log ] && grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5 || true
    [ -f /var/log/secure ] && grep "Failed password" /var/log/secure 2>/dev/null | tail -5 || true
    echo ""; echo -e "  ${WHITE}Last Logins:${NC}"
    last -10 2>/dev/null || echo "  No login log"
    echo ""; echo -e "  ${WHITE}Root/Admin Users:${NC}"
    awk -F: '($3 == 0) {print}' /etc/passwd
    echo ""; echo -e "  ${WHITE}Sudoers:${NC}"
    grep -Po '^sudo:.*$' /etc/group | head -5
    log "Security audit run"
    pause
}

# SEC-002: Anti-Hack Scanner (launch external script)
sec_antihack() {
    header "ANTI-HACK SCANNER"
    local ah_path="$(dirname "$0")/maddix-antihack.sh"
    if [ -f "$ah_path" ]; then
        bash "$ah_path"
    else
        if confirm "Download and run Anti-Hack scanner?"); then
            bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/security/maddix-antihack.sh)
        fi
    fi
    log "Anti-Hack scanner run"
}

# CLN-001: System Cleanup
cln_system() {
    header "SYSTEM CLEANUP"
    case "$PKG_MGR" in
        apt)
            apt-get autoremove -y
            apt-get autoclean -y
            apt-get clean -y ;;
        dnf) dnf autoremove -y; dnf clean all ;;
        pacman) pacman -Sc --noconfirm; pacman -Rns $(pacman -Qdtq) --noconfirm 2>/dev/null ;;
        zypper) zypper clean -a ;;
    esac
    # Journal
    journalctl --vacuum-size=200M 2>/dev/null && ok "Journal cleaned to 200M" || true
    # Temp
    rm -rf /tmp/* 2>/dev/null; rm -rf /var/tmp/* 2>/dev/null
    ok "System cleaned"; log "System cleaned" "SUCCESS"
    pause
}

# OPT-001: Swappiness
opt_swappiness() {
    header "SWAPPINESS OPTIMIZER"
    local cur=$(cat /proc/sys/vm/swappiness)
    echo -e "  Current swappiness: ${YELLOW}$cur${NC}"
    if confirm "Set swappiness to 10 (better for SSD)?"; then
        sysctl vm.swappiness=10
        echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf 2>/dev/null || true
        ok "Swappiness set to 10"; log "Swappiness optimized" "SUCCESS"
    fi
    pause
}

# BAK-001: Package Backup
bak_packages() {
    header "PACKAGE LIST BACKUP"
    local f="$BACKUP_DIR/packages_$(date +%Y%m%d_%H%M%S).list"
    case "$PKG_MGR" in
        apt) dpkg --get-selections | grep -v deinstall > "$f" ;;
        dnf) dnf list installed > "$f" ;;
        pacman) pacman -Qqe > "$f" ;;
        zypper) zypper se --installed-only > "$f" ;;
    esac
    ok "Package list saved: $f"; log "Package list backed up" "SUCCESS"
    pause
}

# BAK-003: Enhanced Backup (from existing function)
bak_enhanced() {
    header "ENHANCED BACKUP"
    local ts=$(date +%Y%m%d_%H%M%S)
    local root="$BACKUP_DIR/enhanced_$ts"
    local tmp="/tmp/backup_$ts"
    mkdir -p "$tmp/files" "$tmp/db" "$tmp/archives" "$root"

    if confirm "Backup MySQL databases?"); then
        if command -v mysqldump &>/dev/null; then
            read -p "  MySQL user (root): " mu; mu=${mu:-root}
            read -s -p "  MySQL password: " mp; echo
            mysqldump -u"$mu" -p"$mp" --all-databases 2>/dev/null | gzip > "$tmp/db/mysql_$ts.sql.gz"
            ok "MySQL backup done" || warn "MySQL backup failed"
        else warn "mysqldump not found"; fi
    fi

    if confirm "Backup PostgreSQL?"); then
        if command -v pg_dumpall &>/dev/null; then
            read -p "  PG user (postgres): " pu; pu=${pu:-postgres}
            pg_dumpall -U "$pu" 2>/dev/null | gzip > "$tmp/db/postgres_$ts.psql.gz"
            ok "PostgreSQL backup done" || warn "PostgreSQL backup failed"
        else warn "pg_dumpall not found"; fi
    fi

    if confirm "Backup directories with rsync?"); then
        echo "  Enter paths (one per line, empty to finish):"
        while true; do read -p "  Path: " p; [ -z "$p" ] && break; [ -d "$p" ] && { rsync -aq "$p/" "$tmp/files/$(echo $p | tr '/' '_')/"; ok "Backed up $p"; } || warn "Not found: $p"; done
    fi

    if confirm "Compress?"); then
        tar -czf "$tmp/archives/backup_$ts.tar.gz" -C "$tmp" files db 2>/dev/null
        cp "$tmp/archives/backup_$ts.tar.gz" "$root/"
        ok "Archive: $(du -h "$root/backup_$ts.tar.gz" | cut -f1)"
    fi

    if confirm "Upload to remote?"); then
        read -p "  FTP server: " fs; read -p "  FTP user: " fu; read -s -p "  FTP pass: " fp; echo
        read -p "  Remote path: " fpath
        if command -v curl &>/dev/null; then
            curl -T "$root/backup_$ts.tar.gz" "ftp://$fs$fpath/" --user "$fu:$fp" 2>/dev/null && ok "Uploaded" || warn "Upload failed"
        fi
    fi

    ok "Enhanced backup completed: $root"; log "Enhanced backup done" "SUCCESS"
    pause
}

# DEV-001: Fish Shell Install
dev_fish() {
    header "FISH SHELL INSTALL"
    if command -v fish &>/dev/null; then
        echo -e "  Fish version: $(fish --version 2>/dev/null)"
        ok "Fish is already installed"
    else
        if confirm "Install Fish Shell (modern command-line shell)?"); then
            case "$PKG_MGR" in
                apt)
                    echo 'deb https://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_12/ /' | tee /etc/apt/sources.list.d/fish.list
                    curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_12/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/fish.gpg >/dev/null
                    apt-get update; apt-get install -y fish ;;
                dnf) dnf install -y fish ;;
                pacman) pacman -S --noconfirm fish ;;
                zypper) zypper install -y fish ;;
            esac
            ok "Fish Shell installed! Run: fish"; log "Fish Shell installed" "SUCCESS"
            echo -e "  ${GRAY}Fish Shell is a smart, user-friendly command line shell with:${NC}"
            echo -e "  ${GRAY}- Auto-suggestions based on history${NC}"
            echo -e "  ${GRAY}- Syntax highlighting${NC}"
            echo -e "  ${GRAY}- Web-based configuration (fish_config)${NC}"
            echo -e "  ${GRAY}- Tab completion for commands${NC}"
            echo -e "  ${GRAY}GitHub: https://github.com/fish-shell/fish-shell${NC}"
        fi
    fi
    pause
}

# ─── TOOL EXECUTOR ───
run_tool() {
    local id="$1"
    case "$id" in
        "SYS-001") sys_info ;;
        "SYS-002") sys_update ;;
        "SYS-003") sys_pkgfix ;;
        "SYS-004") sys_broken ;;
        "SYS-005") sys_bootloader ;;
        "SYS-006") sys_fsck ;;
        "SYS-007") sys_systemd ;;
        "SYS-008") opt_kernel ;;
        "SYS-009") header "SERVICE LOGS"; journalctl -p 3 -xb --no-pager -n 30; pause ;;
        "SYS-010") header "DISK USAGE"; df -h; echo ""; du -sh /* 2>/dev/null | sort -rh | head -20; pause ;;
        "NET-001") net_diag ;;
        "NET-002") net_firewall ;;
        "NET-003") header "DNS TEST"; cat /etc/resolv.conf; echo ""; nslookup google.com 2>/dev/null || host google.com 2>/dev/null; pause ;;
        "NET-004") header "PORT SCANNER"; ss -tlnp 2>/dev/null | head -30; pause ;;
        "NET-005") header "WIFI MANAGER"; command -v nmcli &>/dev/null && nmcli device wifi list 2>/dev/null || warn "nmcli not available"; pause ;;
        "NET-006") header "SPEED TEST"; curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py 2>/dev/null | python3 - 2>/dev/null || warn "Speed test failed"; pause ;;
        "NET-007") header "TRACEROUTE"; read -p "  Target: " t; traceroute -n "$t" 2>/dev/null || tracepath -n "$t" 2>/dev/null; pause ;;
        "NET-008") header "ARP TABLE"; arp -n 2>/dev/null || ip neigh show; pause ;;
        "SEC-001") sec_audit ;;
        "SEC-002") sec_antihack ;;
        "SEC-003") header "SSH HARDENING"; 
            if confirm "Disable root login and password auth?"; then
                sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config 2>/dev/null
                sed -i 's/#PermitRootLogin/PermitRootLogin no/' /etc/ssh/sshd_config 2>/dev/null
                sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config 2>/dev/null
                systemctl restart sshd; ok "SSH hardened"; log "SSH hardened" "SUCCESS"
            fi; pause ;;
        "SEC-004") net_firewall ;;
        "SEC-005") header "MALWARE SCAN"; 
            if ! command -v clamscan &>/dev/null; then
                if confirm "Install ClamAV?"; then $INSTALL clamav; freshclam; fi
            fi
            if command -v clamscan &>/dev/null; then
                read -p "  Path to scan (/home): " sp; sp=${sp:-/home}
                clamscan -r --quiet "$sp" 2>/dev/null | tail -5
            fi; pause ;;
        "SEC-006") header "FILE INTEGRITY"; 
            echo -e "  ${WHITE}Changed configs (last 24h):${NC}"
            find /etc -type f -mtime -1 2>/dev/null | head -20
            echo -e "  ${WHITE}World-writable files:${NC}"
            find / -type f -perm -o+w -not -path "/proc/*" -not -path "/sys/*" 2>/dev/null | head -10; pause ;;
        "SEC-007") header "USER AUDIT"; 
            echo -e "  ${WHITE}Users with UID 0 (root):${NC}"
            awk -F: '($3 == 0) {print $1}' /etc/passwd
            echo -e "  ${WHITE}Users with empty password:${NC}"
            awk -F: '($2 == "" || $2 == "!") {print $1}' /etc/shadow 2>/dev/null
            echo -e "  ${WHITE}Sudo group:${NC}"
            grep sudo /etc/group; pause ;;
        "SEC-008") header "SUID SCANNER"; 
            find / -type f -perm -4000 -not -path "/proc/*" -not -path "/sys/*" 2>/dev/null; pause ;;
        "CLN-001") cln_system ;;
        "CLN-002") header "JOURNAL CLEANUP"; journalctl --vacuum-size=100M 2>/dev/null; ok "Journal cleaned"; pause ;;
        "CLN-003") header "ORPHANED PACKAGES"; 
            case "$PKG_MGR" in
                apt) apt-get autoremove -y ;;
                pacman) pacman -Rns $(pacman -Qdtq) --noconfirm 2>/dev/null || echo "  No orphans" ;;
                dnf) dnf autoremove -y ;;
            esac; pause ;;
        "CLN-004") header "DOCKER CLEANUP"; docker system prune -af 2>/dev/null || warn "Docker not available"; pause ;;
        "CLN-005") header "CACHE CLEAN"; rm -rf ~/.cache/* 2>/dev/null; rm -rf /var/cache/* 2>/dev/null; ok "Caches cleaned"; pause ;;
        "OPT-001") opt_swappiness ;;
        "OPT-002") header "KERNEL PARAMS"; 
            sysctl -w net.core.rmem_max=134217728
            sysctl -w net.core.wmem_max=134217728
            sysctl -w vm.dirty_ratio=10
            sysctl -w vm.dirty_background_ratio=5
            ok "Kernel parameters optimized"; log "Kernel params tuned" "SUCCESS"; pause ;;
        "OPT-003") header "I/O SCHEDULER"; 
            echo "none" > /sys/block/sda/queue/scheduler 2>/dev/null || true
            echo "mq-deadline" > /sys/block/nvme0n1/queue/scheduler 2>/dev/null || true
            ok "I/O scheduler set"; pause ;;
        "OPT-004") header "CPU GOVERNOR"; 
            for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                echo "performance" > "$cpu" 2>/dev/null || true
            done
            ok "CPU governor set to performance"; pause ;;
        "BAK-001") bak_packages ;;
        "BAK-002") header "CONFIG BACKUP"; 
            local f="$BACKUP_DIR/configs_$(date +%Y%m%d_%H%M%S).tar.gz"
            tar -czf "$f" /etc /home 2>/dev/null || true
            ok "Config backup: $f"; pause ;;
        "BAK-003") bak_enhanced ;;
        "BAK-004") header "DB BACKUP"; 
            if confirm "MySQL backup?"); then
                read -p "  User: " u; read -s -p "  Pass: " p; echo
                mysqldump -u"$u" -p"$p" --all-databases 2>/dev/null | gzip > "$BACKUP_DIR/mysql_$(date +%Y%m%d).sql.gz"
                ok "MySQL backup done"
            fi
            if confirm "PostgreSQL backup?"); then
                read -p "  User: " u
                pg_dumpall -U "$u" 2>/dev/null | gzip > "$BACKUP_DIR/postgres_$(date +%Y%m%d).psql.gz"
                ok "PostgreSQL backup done"
            fi; pause ;;
        "BAK-005") header "REMOTE UPLOAD"; 
            read -p "  Source file: " src
            read -p "  FTP server: " srv
            read -p "  FTP user: " u; read -s -p "  FTP pass: " p; echo
            read -p "  Remote path: " rp
            curl -T "$src" "ftp://$srv$rp/" --user "$u:$p" 2>/dev/null && ok "Uploaded" || warn "Upload failed"; pause ;;
        "BAK-006") header "RESTORE PACKAGES"; 
            for f in "$BACKUP_DIR"/packages_*.list; do
                [ -f "$f" ] && echo "  $(basename $f)"
            done
            read -p "  Select file: " sf
            if [ -f "$BACKUP_DIR/$sf" ]; then
                case "$PKG_MGR" in
                    apt) dpkg --clear-selections; dpkg --set-selections < "$BACKUP_DIR/$sf"; apt-get dselect-upgrade -y ;;
                    pacman) pacman -S --needed - < "$BACKUP_DIR/$sf" ;;
                esac
                ok "Packages restored"
            fi; pause ;;
        "DEV-001") dev_fish ;;
        "DEV-002") header "DOCKER"; 
            if command -v docker &>/dev/null; then docker info --format '{{.ServerVersion}}' 2>/dev/null && ok "Docker running"
            else
                if confirm "Install Docker?"; then
                    curl -fsSL https://get.docker.com | sh
                    systemctl enable --now docker; ok "Docker installed"
                fi
            fi; pause ;;
        "DEV-003") header "DEV TOOLS"; bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/devtools/maddix-devsetup.sh); pause ;;
        "DEV-004") header "GIT MANAGER"; 
            if ! command -v git &>/dev/null; then $INSTALL git; fi
            git config --global user.name "$(read -p '  Git user name: ' n && echo $n)"
            git config --global user.email "$(read -p '  Git email: ' e && echo $e)"
            ok "Git configured"; pause ;;
        "DEV-005") header "LANGUAGE SETUP"; 
            if confirm "Install Node.js?"; then
                curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - 2>/dev/null
                $INSTALL nodejs
            fi
            if confirm "Install Python3 + pip?"; then $INSTALL python3 python3-pip; fi
            if confirm "Install Go?"; then $INSTALL golang; fi; pause ;;
        "SRV-001") header "SAMBA AD DC"; bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/security/maddix-hardener.sh); pause ;;
        "SRV-002") header "DNS SERVER"; 
            if confirm "Install Bind9?"); then
                $INSTALL bind9
                ok "Bind9 installed"; log "Bind9 installed" "SUCCESS"
            fi; pause ;;
        "SRV-003") header "DHCP SERVER"; 
            if confirm "Install DHCP server?"); then
                case "$PKG_MGR" in
                    apt) $INSTALL isc-dhcp-server ;;
                    dnf) $INSTALL dhcp-server ;;
                esac
                ok "DHCP server installed"
            fi; pause ;;
        "SRV-004") header "WEB SERVER"; 
            if confirm "Install Nginx?"); then $INSTALL nginx; systemctl enable --now nginx; fi
            if confirm "Install Apache?"); then $INSTALL apache2; systemctl enable --now apache2; fi; pause ;;
        "SRV-005") header "DATABASE SERVER"; 
            if confirm "Install MySQL?"); then $INSTALL mysql-server; systemctl enable --now mysql; fi
            if confirm "Install PostgreSQL?"); then $INSTALL postgresql; systemctl enable --now postgresql; fi; pause ;;
        "SRV-006") header "MAIL SERVER"; 
            if confirm "Install Postfix?"); then $INSTALL postfix; systemctl enable --now postfix; fi; pause ;;
        "SRV-007") header "MONITORING"; 
            if confirm "Install Netdata?"); then bash <(curl -Ss https://my-netdata.io/kickstart.sh); fi; pause ;;
        "SRV-008") header "BACKUP SERVER"; 
            if confirm "Install Borg Backup?"); then $INSTALL borgbackup; fi
            if confirm "Install Restic?"); then $INSTALL restic; fi; pause ;;
        "help") show_help ;;
        *) warn "Unknown tool: $id" ;;
    esac
    
    if $PENDING_REBOOT; then
        if confirm "Reboot now?"; then reboot; fi
        PENDING_REBOOT=false
    fi
}

show_help() {
    header "HELP"
    echo -e "  ${WHITE}COMMANDS:${NC}"
    echo -e "    ${GRAY}<ID>      Execute a tool (e.g., SYS-001)${NC}"
    echo -e "    ${GRAY}s <term>  Search tools${NC}"
    echo -e "    ${GRAY}help      Show this help${NC}"
    echo -e "    ${GRAY}q         Quit${NC}"
    echo ""
    echo -e "  ${WHITE}CATEGORIES:${NC}"
    echo -e "  ${BLUE}SYS${NC}  - System (info, updates, packages, bootloader)"
    echo -e "  ${GREEN}NET${NC}  - Network (diagnostics, firewall, DNS)"
    echo -e "  ${RED}SEC${NC}  - Security (audit, anti-hack, hardening)"
    echo -e "  ${YELLOW}CLN${NC}  - Cleaner (system, journal, cache)"
    echo -e "  ${MAGENTA}OPT${NC}  - Optimization (swappiness, kernel, I/O)"
    echo -e "  ${CYAN}BAK${NC}  - Backup (packages, configs, enhanced)"
    echo -e "  ${BLUE}DEV${NC}  - Development (fish, docker, git, languages)"
    if $IS_SERVER; then
    echo -e "  ${RED}SRV${NC}  - Server (Samba, DNS, DHCP, web, mail)"
    fi
    echo ""
    echo -e "  ${GRAY}MaddixSuite v${SCRIPT_VERSION} - https://github.com/mohammadmehrani/MaddixSuite${NC}"
    echo -e "  ${GRAY}Author: Mohammad Mehrani (Maddix) - https://iodeck.ir${NC}"
    pause
}

main() {
    detect_system
    mkdir -p "$BASE_DIR" "$LOG_DIR" "$BACKUP_DIR"

    clear
    show_banner
    show_system_info
    echo -e "\n  ${GRAY}Loaded tools: SYS(10) NET(8) SEC(8) CLN(5) OPT(4) BAK(6) DEV(5) SRV(8)${NC}"
    echo -e "  ${GRAY}Mode: $($IS_SERVER && echo 'SERVER' || echo 'CLIENT')${NC}"
    echo -e "  ${GRAY}Type 'help' for usage${NC}"
    echo -e ""
    pause

    while true; do
        show_menu
        echo -en "  ${CYAN}MaddixSuite> ${NC}"; read -r cmd
        cmd=$(echo "$cmd" | xargs)
        
        case "$cmd" in
            q|quit|exit) echo -e "  ${CYAN}Goodbye!${NC}"; log "Session ended"; exit 0 ;;
            help|h) show_help ;;
            n|next) continue ;;
            p|prev) continue ;;
            s\ *) local search="${cmd#s }"; info "Searching for: $search (use IDs like SYS-001)" ;;
            *) 
                local id=$(echo "$cmd" | tr '[:lower:]' '[:upper:]')
                if [[ "$id" =~ ^[A-Z]+-[0-9]{3}$ ]]; then
                    if [[ "$id" =~ ^SRV- ]] && ! $IS_SERVER; then
                        warn "SRV tools are Server-only"
                        pause
                        continue
                    fi
                    run_tool "$id"
                else
                    warn "Unknown: $cmd. Type 'help'"
                fi
                ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
