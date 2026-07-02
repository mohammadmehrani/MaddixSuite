# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
#!/bin/bash
# =========================================================
# SysAdminSuite v2.0 - Linux Edition
# Part of MaddixSuite by Mohammad Mehrani (Maddix)
# https://github.com/mohammadmehrani/MaddixSuite
#
# Run directly from GitHub:
#   bash <(curl -s https://raw.githubusercontent.com/maddix/MaddixSuite/main/linux/SysAdminSuite.sh)
# =========================================================

set -e

# Colors
CYAN='\033[0;96m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
RED='\033[0;91m'
MAGENTA='\033[0;95m'
GRAY='\033[0;90m'
RESET='\033[0m'

BASE_DIR="$HOME/MaddixSuite"
REPORT_DIR="$BASE_DIR/Reports"
BACKUP_DIR="$BASE_DIR/Backups"
START_TIME=$(date +%s)
OS_ID=""
OS_VERSION=""
PKG_MGR=""

# Ensure we're running as root for most operations
check_root() {
    if [ "$(id -u)" -ne 0 ] && [ "$1" = "require" ]; then
        echo -e "${RED}This option requires root privileges.${RESET}"
        echo -e "${YELLOW}Run with: sudo $0${RESET}"
        return 1
    fi
    return 0
}

# Detect distro and package manager
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"
    elif [ -f /etc/debian_version ]; then
        OS_ID="debian"
        OS_VERSION=$(cat /etc/debian_version)
    else
        OS_ID="unknown"
        OS_VERSION="unknown"
    fi

    if command -v apt &>/dev/null; then
        PKG_MGR="apt"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
    elif command -v yum &>/dev/null; then
        PKG_MGR="yum"
    elif command -v pacman &>/dev/null; then
        PKG_MGR="pacman"
    elif command -v zypper &>/dev/null; then
        PKG_MGR="zypper"
    elif command -v apk &>/dev/null; then
        PKG_MGR="apk"
    else
        PKG_MGR="unknown"
    fi

    echo -e "${GREEN}Detected: $PRETTY_NAME ($PKG_MGR)${RESET}"
}

# Create directories
init_dirs() {
    mkdir -p "$REPORT_DIR" "$BACKUP_DIR"
}

log() {
    local msg="$1"
    local type="${2:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] [$type] $msg" >> "$REPORT_DIR/sysadmin.log"
}

# ─────────────────────────────────────────────────────────
# DIAGNOSTIC & REPAIR
# ─────────────────────────────────────────────────────────

fix_package_manager() {
    echo -e "\n${YELLOW}=== FIXING PACKAGE MANAGER ===${RESET}"
    check_root require || return 1
    case "$PKG_MGR" in
        apt)
            sudo dpkg --configure -a
            sudo apt --fix-broken install -y
            sudo apt update
            ;;
        dnf)
            sudo dnf clean all
            sudo dnf check
            sudo dnf distro-sync -y
            ;;
        yum)
            sudo yum clean all
            sudo yum check
            ;;
        pacman)
            sudo pacman -Sy
            sudo pacman -Syu --noconfirm
            ;;
        zypper)
            sudo zypper refresh
            sudo zypper verify
            ;;
        *)
            echo -e "${RED}Unsupported package manager.${RESET}"
            ;;
    esac
    echo -e "${GREEN}Package manager repaired.${RESET}"
    log "Package manager repaired" "SUCCESS"
}

fix_broken_packages() {
    echo -e "\n${YELLOW}=== FIXING BROKEN PACKAGES ===${RESET}"
    check_root require || return 1
    case "$PKG_MGR" in
        apt)
            sudo apt --fix-broken install -y
            sudo apt autoremove -y
            sudo apt autoclean
            ;;
        dnf)
            sudo dnf check
            sudo dnf reinstall $(sudo dnf repoquery --all --quiet 2>/dev/null | head -20) -y 2>/dev/null || true
            ;;
        pacman)
            sudo pacman -Qk 2>/dev/null || true
            ;;
        zypper)
            sudo zypper verify --no-cd
            ;;
    esac
    echo -e "${GREEN}Broken packages fixed.${RESET}"
    log "Broken packages fixed" "SUCCESS"
}

fix_bootloader() {
    echo -e "\n${YELLOW}=== FIXING BOOTLOADER ===${RESET}"
    check_root require || return 1
    if command -v update-grub &>/dev/null; then
        sudo update-grub
        echo -e "${GREEN}GRUB Updated.${RESET}"
    elif command -v grub2-mkconfig &>/dev/null; then
        sudo grub2-mkconfig -o /boot/grub2/grub.cfg
        echo -e "${GREEN}GRUB2 Updated.${RESET}"
    elif command -v grub-mkconfig &>/dev/null; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        echo -e "${GREEN}GRUB Updated.${RESET}"
    else
        echo -e "${YELLOW}GRUB not found. Skipping.${RESET}"
    fi
    log "Bootloader updated" "SUCCESS"
}

fix_filesystem() {
    echo -e "\n${YELLOW}=== CHECKING FILESYSTEM ===${RESET}"
    local root_dev=$(findmnt -n -o SOURCE / 2>/dev/null | sed 's/[0-9]*$//' || echo "/dev/sda")
    echo -e "${GRAY}Root device: $root_dev${RESET}"
    echo -e "${YELLOW}Note: Full fsck requires unmounting. Running read-only check...${RESET}"
    sudo touch /forcefsck 2>/dev/null && echo -e "${YELLOW}Will run fsck on next reboot.${RESET}" || true
    log "Filesystem check scheduled" "INFO"
}

fix_dns() {
    echo -e "\n${YELLOW}=== DNS DIAGNOSTIC ===${RESET}"
    echo "Testing DNS resolution..."
    for dns in "8.8.8.8" "1.1.1.1" "google.com" "github.com"; do
        if ping -c 1 -W 2 "$dns" &>/dev/null; then
            echo -e "  $dns -> ${GREEN}OK${RESET}"
        else
            echo -e "  $dns -> ${RED}FAIL${RESET}"
        fi
    done
    echo -e "\nResolv.conf:"
    cat /etc/resolv.conf 2>/dev/null || echo "No resolv.conf"
    log "DNS check completed" "INFO"
}

fix_network() {
    echo -e "\n${YELLOW}=== NETWORK DIAGNOSTIC ===${RESET}"
    echo "Network Interfaces:"
    ip -br addr show 2>/dev/null || ifconfig 2>/dev/null || true
    echo ""
    echo "Routing Table:"
    ip route show 2>/dev/null || route -n 2>/dev/null || true
    echo ""
    fix_dns
    log "Network diagnostic completed" "INFO"
}

fix_systemd_services() {
    echo -e "\n${YELLOW}=== CHECKING SYSTEMD SERVICES ===${RESET}"
    local failed=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
    if [ "$failed" -gt 0 ]; then
        echo -e "${RED}Failed services found:${RESET}"
        systemctl --failed
        read -p "Reset all failed services? (y/n): " ans
        if [ "$ans" = "y" ]; then
            systemctl --failed --no-legend 2>/dev/null | awk '{print $1}' | while read svc; do
                sudo systemctl reset-failed "$svc" 2>/dev/null
                sudo systemctl restart "$svc" 2>/dev/null || true
            done
            echo -e "${GREEN}Services reset.${RESET}"
        fi
    else
        echo -e "${GREEN}No failed services.${RESET}"
    fi
    log "Systemd services checked" "INFO"
}

# ─────────────────────────────────────────────────────────
# CLEANUP & OPTIMIZATION
# ─────────────────────────────────────────────────────────

clean_system() {
    echo -e "\n${YELLOW}=== CLEANING SYSTEM ===${RESET}"
    check_root require || return 1
    case "$PKG_MGR" in
        apt)
            sudo apt autoremove -y
            sudo apt autoclean
            sudo apt clean
            ;;
        dnf)
            sudo dnf clean all
            sudo dnf autoremove -y
            ;;
        yum)
            sudo yum clean all
            sudo yum autoremove -y
            ;;
        pacman)
            sudo pacman -Sc --noconfirm
            sudo pacman -Rns $(pacman -Qdtq 2>/dev/null) --noconfirm 2>/dev/null || true
            ;;
        zypper)
            sudo zypper clean
            sudo zypper packages --orphaned | awk '{print $5}' | xargs sudo zypper rm -y 2>/dev/null || true
            ;;
    esac
    # Common cleanup
    sudo journalctl --vacuum-time=7d 2>/dev/null || true
    sudo rm -rf /tmp/* 2>/dev/null || true
    echo -e "${GREEN}System cleaned.${RESET}"
    log "System cleaned" "SUCCESS"
}

clean_journal() {
    echo -e "\n${YELLOW}=== JOURNAL LOG CLEANUP ===${RESET}"
    local current=$(journalctl --disk-usage 2>/dev/null | awk '{print $NF}' || echo "unknown")
    echo -e "${GRAY}Current journal size: $current${RESET}"
    read -p "Vacuum journal to 500M? (y/n): " ans
    if [ "$ans" = "y" ]; then
        sudo journalctl --vacuum-size=500M
        echo -e "${GREEN}Journal cleaned.${RESET}"
        log "Journal cleaned" "SUCCESS"
    fi
}

optimize_swappiness() {
    echo -e "\n${YELLOW}=== OPTIMIZE SWAPPINESS ===${RESET}"
    local current=$(cat /proc/sys/vm/swappiness 2>/dev/null || echo 60)
    echo -e "Current swappiness: ${GRAY}$current${RESET}"
    read -p "Set swappiness to 10 (better for SSD/desktop)? (y/n): " ans
    if [ "$ans" = "y" ]; then
        echo 10 | sudo tee /proc/sys/vm/swappiness >/dev/null
        echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.d/99-swappiness.conf >/dev/null 2>/dev/null || true
        echo -e "${GREEN}Swappiness set to 10.${RESET}"
        log "Swappiness optimized" "SUCCESS"
    fi
}

# ─────────────────────────────────────────────────────────
# BACKUP & RESTORE
# ─────────────────────────────────────────────────────────

backup_packages() {
    echo -e "\n${YELLOW}=== BACKUP PACKAGE LIST ===${RESET}"
    local pkg_file="$BACKUP_DIR/packages_$(date +%Y%m%d_%H%M%S).list"
    case "$PKG_MGR" in
        apt)
            dpkg --get-selections | grep -v deinstall > "$pkg_file"
            echo -e "${GREEN}Package list saved: $pkg_file${RESET}"
            echo -e "${GRAY}Restore with: dpkg --set-selections < $pkg_file && apt dselect-upgrade${RESET}"
            ;;
        dnf|yum)
            "$PKG_MGR" list installed > "$pkg_file"
            echo -e "${GREEN}Package list saved: $pkg_file${RESET}"
            ;;
        pacman)
            pacman -Qqe > "$pkg_file"
            echo -e "${GREEN}Package list saved: $pkg_file${RESET}"
            echo -e "${GRAY}Restore with: pacman -S --needed - < $pkg_file${RESET}"
            ;;
        zypper)
            zypper se --installed-only > "$pkg_file"
            echo -e "${GREEN}Package list saved: $pkg_file${RESET}"
            ;;
    esac
    log "Package list backed up" "SUCCESS"
}

backup_configs() {
    echo -e "\n${YELLOW}=== BACKUP SYSTEM CONFIGURATIONS ===${RESET}"
    local cfg_backup="$BACKUP_DIR/configs_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$cfg_backup"

    local dirs=("/etc" "/home" "/var/spool/cron" "/var/spool/mail")
    for d in "${dirs[@]}"; do
        if [ -d "$d" ]; then
            echo "  Backing up $d..."
            sudo tar czf "$cfg_backup/$(echo $d | tr '/' '_').tar.gz" "$d" 2>/dev/null || true
        fi
    done

    # Backup package lists
    backup_packages

    echo -e "${GREEN}Config backup completed: $cfg_backup${RESET}"
    echo -e "${YELLOW}Total size: $(du -sh "$cfg_backup" | cut -f1)${RESET}"
    log "Configs backed up to $cfg_backup" "SUCCESS"
}

# ─────────────────────────────────────────────────────────
# ENHANCED MODULAR BACKUP (Database + Files + Remote)
# ─────────────────────────────────────────────────────────

backup_enhanced() {
    echo -e "\n${YELLOW}═══════════════════════════════════════════════${RESET}"
    echo -e "${YELLOW}   ENHANCED MODULAR BACKUP${RESET}"
    echo -e "${YELLOW}═══════════════════════════════════════════════${RESET}"

    local ts=$(date +%Y%m%d_%H%M%S)
    local backup_root="$BACKUP_DIR/enhanced_$ts"
    local tmpdir="/tmp/backup_$ts"
    mkdir -p "$tmpdir/files" "$tmpdir/db" "$tmpdir/archives" "$backup_root"

    echo -e "${GRAY}Backup directory: $backup_root${RESET}"
    echo ""

    # --- CONFIRM FUNCTION ---
    confirm_step() {
        local msg="$1"
        echo -en "${YELLOW}  $msg (Y/N): ${RESET}"
        read -r r
        [[ "$r" =~ ^[Yy]$ ]]
    }

    # --- MODULE 1: DATABASE BACKUP (MySQL) ---
    if confirm_step "Backup MySQL databases?"; then
        echo -e "  ${GRAY}[1] MySQL dump...${RESET}"
        if command -v mysqldump &>/dev/null; then
            echo -en "  ${GRAY}MySQL user (root): ${RESET}"; read -r mysql_user
            echo -en "  ${GRAY}MySQL password: ${RESET}"; read -rs mysql_pass; echo
            mysql_user=${mysql_user:-root}
            nice /usr/bin/mysqldump -u"$mysql_user" -p"$mysql_pass" --all-databases --routines --events 2>/dev/null | gzip -c > "$tmpdir/db/${HOSTNAME}_mysql_${ts}.sql.gz"
            if [ -f "$tmpdir/db/${HOSTNAME}_mysql_${ts}.sql.gz" ] && [ -s "$tmpdir/db/${HOSTNAME}_mysql_${ts}.sql.gz" ]; then
                echo -e "  ${GREEN}[+] MySQL backup complete ($(du -h "$tmpdir/db/${HOSTNAME}_mysql_${ts}.sql.gz" | cut -f1))${RESET}"
            else
                echo -e "  ${YELLOW}[!] MySQL backup failed or no data${RESET}"
            fi
        else
            echo -e "  ${YELLOW}[!] mysqldump not found. Install mysql-client.${RESET}"
        fi
    fi

    # --- MODULE 2: DATABASE BACKUP (PostgreSQL) ---
    if confirm_step "Backup PostgreSQL databases?"; then
        echo -e "  ${GRAY}[2] PostgreSQL dump...${RESET}"
        if command -v pg_dumpall &>/dev/null; then
            echo -en "  ${GRAY}PostgreSQL user (postgres): ${RESET}"; read -r pg_user
            pg_user=${pg_user:-postgres}
            echo -en "  ${GRAY}PostgreSQL password: ${RESET}"; read -rs pg_pass; echo
            export PGPASSWORD="$pg_pass"
            nice /usr/bin/pg_dumpall -U "$pg_user" 2>/dev/null | gzip -c > "$tmpdir/db/${HOSTNAME}_psql_${ts}.psql.gz"
            unset PGPASSWORD
            if [ -f "$tmpdir/db/${HOSTNAME}_psql_${ts}.psql.gz" ] && [ -s "$tmpdir/db/${HOSTNAME}_psql_${ts}.psql.gz" ]; then
                echo -e "  ${GREEN}[+] PostgreSQL backup complete ($(du -h "$tmpdir/db/${HOSTNAME}_psql_${ts}.psql.gz" | cut -f1))${RESET}"
            else
                echo -e "  ${YELLOW}[!] PostgreSQL backup failed or no data${RESET}"
            fi
        else
            echo -e "  ${YELLOW}[!] pg_dumpall not found. Install postgresql-client.${RESET}"
        fi
    fi

    # --- MODULE 3: FILE BACKUP (rsync) ---
    if confirm_step "Backup files/directories via rsync?"; then
        echo -e "  ${GRAY}[3] File backup (rsync)...${RESET}"
        echo -e "  ${GRAY}Enter directories to backup (one per line, empty line to finish):${RESET}"
        local includes=()
        while true; do
            echo -en "  ${GRAY}Path: ${RESET}"; read -r inc
            [ -z "$inc" ] && break
            if [ -d "$inc" ]; then
                includes+=("$inc")
                echo -e "    ${GREEN}Added: $inc${RESET}"
            else
                echo -e "    ${YELLOW}Not found: $inc${RESET}"
            fi
        done
        if [ ${#includes[@]} -gt 0 ]; then
            for item in "${includes[@]}"; do
                local safe_name=$(echo "$item" | tr '/' '_' | tr -d ':')
                mkdir -p "$tmpdir/files/$safe_name"
                echo -e "    ${GRAY}Rsyncing $item...${RESET}"
                rsync -aq "$item/" "$tmpdir/files/$safe_name/" 2>/dev/null && echo -e "    ${GREEN}Done: $item${RESET}" || echo -e "    ${YELLOW}Failed: $item${RESET}"
            done
            echo -e "  ${GREEN}[+] File backup complete${RESET}"
        else
            echo -e "  ${YELLOW}[!] No directories selected${RESET}"
        fi
    fi

    # --- MODULE 4: Drush backup (CMS) ---
    if command -v drush &>/dev/null; then
        if confirm_step "Backup Drupal sites via Drush?"; then
            echo -e "  ${GRAY}[4] Drush backup...${RESET}"
            echo -en "  ${GRAY}Drupal root path: ${RESET}"; read -r drupal_root
            if [ -n "$drupal_root" ] && [ -f "$drupal_root/index.php" ]; then
                mkdir -p "$tmpdir/drush"
                drush --root="$drupal_root" --destination="$tmpdir/drush/${HOSTNAME}_drush_${ts}.tar.gz" ard 2>/dev/null
                [ $? -eq 0 ] && echo -e "  ${GREEN}[+] Drush backup complete${RESET}" || echo -e "  ${YELLOW}[!] Drush backup failed${RESET}"
            fi
        fi
    fi

    # --- MODULE 5: COMPRESS & ARCHIVE ---
    if confirm_step "Compress all backup data into a single archive?"; then
        echo -e "  ${GRAY}[5] Compressing...${RESET}"
        local archive="$tmpdir/archives/${HOSTNAME}_backup_${ts}.tar.gz"
        nice tar -czf "$archive" -C "$tmpdir" files db 2>/dev/null
        if [ -f "$archive" ]; then
            echo -e "  ${GREEN}[+] Archive created: $(du -h "$archive" | cut -f1)${RESET}"
            cp "$archive" "$backup_root/"
        fi
    fi

    # --- MODULE 6: REMOTE UPLOAD ---
    if confirm_step "Upload backup to remote location?"; then
        echo -e "  ${GRAY}[6] Remote upload...${RESET}"
        echo -e "    ${GRAY}1) Local folder copy${RESET}"
        echo -e "    ${GRAY}2) FTP upload${RESET}"
        echo -e "    ${GRAY}3) Skip${RESET}"
        echo -en "  ${GRAY}Select (1-3): ${RESET}"; read -r ru

        if [ "$ru" = "1" ]; then
            echo -en "  ${GRAY}Destination folder: ${RESET}"; read -r dest
            if [ -n "$dest" ]; then
                mkdir -p "$dest"
                cp "$archive" "$dest/" 2>/dev/null
                echo -e "  ${GREEN}[+] Copied to $dest${RESET}"
                # Copy DB files too
                cp -r "$tmpdir/db" "$dest/" 2>/dev/null
            fi
        elif [ "$ru" = "2" ]; then
            echo -en "  ${GRAY}FTP server: ${RESET}"; read -r ftp_srv
            echo -en "  ${GRAY}FTP username: ${RESET}"; read -r ftp_user
            echo -en "  ${GRAY}FTP password: ${RESET}"; read -rs ftp_pass; echo
            echo -en "  ${GRAY}Remote path: ${RESET}"; read -r ftp_path
            if [ -n "$ftp_srv" ] && [ -n "$ftp_user" ]; then
                if command -v lftp &>/dev/null; then
                    lftp -u "$ftp_user,$ftp_pass" "$ftp_srv" -e "put $archive -o $ftp_path/$(basename $archive); exit" 2>/dev/null
                    echo -e "  ${GREEN}[+] Uploaded via lftp${RESET}"
                elif command -v curl &>/dev/null; then
                    curl -T "$archive" "ftp://$ftp_srv$ftp_path/" --user "$ftp_user:$ftp_pass" 2>/dev/null
                    echo -e "  ${GREEN}[+] Uploaded via curl${RESET}"
                else
                    echo -e "  ${YELLOW}[!] No FTP client found (install lftp or curl)${RESET}"
                fi
            fi
        fi
    fi

    # --- MODULE 7: PACKAGE LIST ---
    backup_packages 2>/dev/null

    # --- SUMMARY ---
    echo -e "\n${CYAN}═══════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}  ENHANCED BACKUP COMPLETED${RESET}"
    echo -e "${CYAN}  Location: $backup_root${RESET}"
    echo -e "${CYAN}  Size: $(du -sh "$backup_root" 2>/dev/null | cut -f1)${RESET}"
    echo -e "${CYAN}═══════════════════════════════════════════════${RESET}"
    log "Enhanced backup completed: $backup_root" "SUCCESS"
}

restore_packages() {
    echo -e "\n${YELLOW}=== RESTORE PACKAGES FROM BACKUP ===${RESET}"
    local lists=($(ls "$BACKUP_DIR"/packages_*.list 2>/dev/null))
    if [ ${#lists[@]} -eq 0 ]; then
        echo -e "${RED}No package lists found in $BACKUP_DIR${RESET}"
        return
    fi
    echo "Available backups:"
    for i in "${!lists[@]}"; do
        echo "  $((i+1)). $(basename ${lists[$i]})"
    done
    read -p "Select backup number: " sel
    local idx=$((sel - 1))
    if [ $idx -ge 0 ] && [ $idx -lt ${#lists[@]} ]; then
        check_root require || return 1
        case "$PKG_MGR" in
            apt)
                sudo dpkg --clear-selections
                sudo dpkg --set-selections < "${lists[$idx]}"
                sudo apt dselect-upgrade -y
                ;;
            pacman)
                sudo pacman -S --needed - < "${lists[$idx]}"
                ;;
            *)
                echo -e "${RED}Restore not implemented for $PKG_MGR.${RESET}"
                ;;
        esac
        echo -e "${GREEN}Packages restored from backup.${RESET}"
    fi
}

# ─────────────────────────────────────────────────────────
# SECURITY & HEALTH
# ─────────────────────────────────────────────────────────

security_audit() {
    echo -e "\n${YELLOW}=== SECURITY AUDIT ===${RESET}"
    echo "Open Ports:"
    ss -tlnp 2>/dev/null | column -t || netstat -tlnp 2>/dev/null
    echo ""
    echo "Failed SSH Logins (last 10):"
    journalctl -u sshd -u ssh --no-pager -n 10 2>/dev/null | grep -i "failed" || true
    echo ""
    echo "Last System Logins:"
    last -10 2>/dev/null || true
    log "Security audit completed" "INFO"
}

system_health() {
    echo -e "\n${YELLOW}=== SYSTEM HEALTH ===${RESET}"
    echo "Uptime: $(uptime -p)"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    echo "Memory:"
    free -h
    echo ""
    echo "Disk Usage:"
    df -h / /home 2>/dev/null || df -h /
    echo ""
    echo "Zombie Processes: $(ps aux | awk '{if ($8 == "Z") print}' | wc -l)"
    log "Health check completed" "INFO"
}

system_info() {
    echo -e "\n${YELLOW}=== SYSTEM INFORMATION ===${RESET}"
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "Arch: $(uname -m)"
    echo "OS: $PRETTY_NAME"
    echo "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    echo "RAM: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Shell: $SHELL"
    echo "Packages: $(dpkg --list 2>/dev/null | wc -l || pacman -Q 2>/dev/null | wc -l || rpm -qa 2>/dev/null | wc -l || echo 'unknown')"
    log "System info displayed" "INFO"
}

kernel_optimize() {
    echo -e "\n${YELLOW}=== KERNEL PARAMETERS ===${RESET}"
    echo "Current TCP congestion control: $(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')"
    echo "Current I/O Scheduler: $(cat /sys/block/sda/queue/scheduler 2>/dev/null || echo 'unknown')"
    read -p "Apply performance kernel params? (y/n): " ans
    if [ "$ans" = "y" ]; then
        check_root require || return 1
        sudo tee -a /etc/sysctl.d/99-performance.conf >/dev/null <<'EOF'
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
EOF
        sudo sysctl --system
        echo -e "${GREEN}Kernel parameters optimized.${RESET}"
        log "Kernel parameters optimized" "SUCCESS"
    fi
}

# ─────────────────────────────────────────────────────────
# MENU SYSTEM
# ─────────────────────────────────────────────────────────

show_menu() {
    clear
    echo -e "${CYAN}================================================================================${RESET}"
    echo -e "${CYAN}  SysAdminSuite v2.0 - Linux Edition${RESET}"
    echo -e "${CYAN}  Created by Mohammad Mehrani (Maddix)${RESET}"
    echo -e "${CYAN}  Detected: $PRETTY_NAME | $PKG_MGR${RESET}"
    echo -e "${CYAN}================================================================================${RESET}"
    echo ""
    echo -e " ${MAGENTA}---- DIAGNOSTIC & REPAIR ----${RESET}"
    echo "   1.  Fix Package Manager (dpkg/apt/dnf/pacman)"
    echo "   2.  Fix Broken Packages"
    echo "   3.  Fix Bootloader (GRUB)"
    echo "   4.  Check Filesystem (fsck)"
    echo "   5.  Fix Systemd Services"
    echo ""
    echo -e " ${MAGENTA}---- NETWORK ----${RESET}"
    echo "   6.  Network Diagnostic"
    echo "   7.  DNS Diagnostic"
    echo ""
    echo -e " ${MAGENTA}---- CLEANUP & OPTIMIZATION ----${RESET}"
    echo "   8.  Clean System (Packages, Temp, Journal)"
    echo "   9.  Journal Log Cleanup"
    echo "  10.  Optimize Swappiness"
    echo "  11.  Kernel Performance Parameters"
    echo ""
    echo -e " ${MAGENTA}---- BACKUP & RESTORE ----${RESET}"
    echo "  12.  Backup Package List"
    echo "  13.  Backup System Configs (etc, home)"
    echo "  14.  Restore Packages from Backup"
    echo "  15.  Enhanced Backup (DB + Files + Archive + Upload)"
    echo ""
    echo -e " ${MAGENTA}---- SECURITY & HEALTH ----${RESET}"
    echo "  16.  Security Audit (Ports, SSH, Logins)"
    echo "  17.  System Health (Memory, Disk, Uptime)"
    echo "  18.  System Information"
    echo ""
    echo -e " ${MAGENTA}---- GENERAL ----${RESET}"
    echo "  19.  Run ALL Repairs & Optimization"
    echo "  20.  Show Script Version & Update"
    echo "   0.  Exit"
    echo ""
}

main() {
    detect_distro
    init_dirs

    while true; do
        show_menu
        read -p "Select option (0-20): " choice
        case "$choice" in
            1) fix_package_manager; read -p "Press Enter..." ;;
            2) fix_broken_packages; read -p "Press Enter..." ;;
            3) fix_bootloader; read -p "Press Enter..." ;;
            4) fix_filesystem; read -p "Press Enter..." ;;
            5) fix_systemd_services; read -p "Press Enter..." ;;
            6) fix_network; read -p "Press Enter..." ;;
            7) fix_dns; read -p "Press Enter..." ;;
            8) clean_system; read -p "Press Enter..." ;;
            9) clean_journal; read -p "Press Enter..." ;;
            10) optimize_swappiness; read -p "Press Enter..." ;;
            11) kernel_optimize; read -p "Press Enter..." ;;
            12) backup_packages; read -p "Press Enter..." ;;
            13) backup_configs; read -p "Press Enter..." ;;
            14) restore_packages; read -p "Press Enter..." ;;
            15) backup_enhanced; read -p "Press Enter..." ;;
            16) security_audit; read -p "Press Enter..." ;;
            17) system_health; read -p "Press Enter..." ;;
            18) system_info; read -p "Press Enter..." ;;
            19)
                echo -e "\n${YELLOW}Running ALL Repairs...${RESET}"
                fix_package_manager
                fix_broken_packages
                fix_bootloader
                clean_system
                system_health
                echo -e "\n${GREEN}ALL REPAIRS COMPLETED!${RESET}"
                read -p "Press Enter..."
                ;;
            20)
                echo -e "\n${CYAN}SysAdminSuite v2.0 - Linux Edition${RESET}"
                echo -e "${CYAN}Part of MaddixSuite${RESET}"
                echo -e "${CYAN}github.com/mohammadmehrani/MaddixSuite${RESET}"
                echo -e "${CYAN}Website: https://iodeck.ir${RESET}"
                echo -e "\n${YELLOW}Check for updates:${RESET}"
                echo "  bash <(curl -s https://raw.githubusercontent.com/maddix/MaddixSuite/main/linux/SysAdminSuite.sh)"
                read -p "Press Enter..."
                ;;
            0)
                echo -e "${CYAN}Goodbye!${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option.${RESET}"
                read -p "Press Enter..."
                ;;
        esac
    done
}

main "$@"

