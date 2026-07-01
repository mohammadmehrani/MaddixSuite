#!/bin/bash
# =========================================================
# Maddix-SystemHardener - Linux Security Hardening Toolkit
# Part of MaddixSuite by Mohammad Mehrani (Maddix)
# https://github.com/mohammadmehrani/MaddixSuite
#
# Run: bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/security/maddix-hardener.sh)
# =========================================================

set -e

CYAN='\033[0;96m'; GREEN='\033[0;92m'; YELLOW='\033[0;93m'; RED='\033[0;91m'; MAGENTA='\033[0;95m'; GRAY='\033[0;90m'; RESET='\033[0m'

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Must run as root. Use: sudo $0${RESET}"
        exit 1
    fi
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release; OS_ID="$ID"
    elif [ -f /etc/debian_version ]; then
        OS_ID="debian"
    else
        OS_ID="unknown"
    fi
}

show_banner() {
    clear
    echo -e "${CYAN}================================================================${RESET}"
    echo -e "${CYAN}  Maddix-SystemHardener v1.0 - Linux Security Toolkit${RESET}"
    echo -e "${CYAN}  Created by Mohammad Mehrani (Maddix)${RESET}"
    echo -e "${CYAN}================================================================${RESET}"
    echo ""
}

audit_ports() {
    echo -e "\n${YELLOW}=== OPEN PORTS & SERVICES ===${RESET}"
    echo -e "Listening services:"
    ss -tlnp 2>/dev/null | column -t || netstat -tlnp 2>/dev/null
    echo ""
    echo -e "UDP ports:"
    ss -ulnp 2>/dev/null | column -t || true
    echo ""
    read -p "Close all non-essential ports via firewall? (y/n): " ans
    if [ "$ans" = "y" ]; then
        if command -v ufw &>/dev/null; then
            ufw default deny incoming
            ufw default allow outgoing
            ufw enable
            echo -e "${GREEN}UFW enabled: default deny incoming${RESET}"
        elif command -v firewall-cmd &>/dev/null; then
            firewall-cmd --set-default-zone=drop
            firewall-cmd --reload
            echo -e "${GREEN}FirewallD set to drop zone${RESET}"
        fi
    fi
}

audit_ssh() {
    echo -e "\n${YELLOW}=== SSH AUDIT ===${RESET}"
    local sshd_config="/etc/ssh/sshd_config"
    if [ -f "$sshd_config" ]; then
        echo "Current SSH settings:"
        grep -E "^(PermitRootLogin|PasswordAuthentication|Port |PubkeyAuthentication|AllowUsers|Protocol)" "$sshd_config" 2>/dev/null || true
        
        local insecure=0
        if grep -qi "PermitRootLogin yes" "$sshd_config" 2>/dev/null; then
            echo -e "  ${RED}✗ Root login: ENABLED (insecure)${RESET}"; insecure=1
        else
            echo -e "  ${GREEN}✓ Root login: Disabled/Key-only${RESET}"
        fi
        if grep -qi "PasswordAuthentication yes" "$sshd_config" 2>/dev/null; then
            echo -e "  ${RED}✗ Password auth: ENABLED (insecure)${RESET}"; insecure=1
        else
            echo -e "  ${GREEN}✓ Password auth: Disabled${RESET}"
        fi
        
        if [ "$insecure" -eq 1 ]; then
            read -p "Apply secure SSH settings? (y/n): " ans
            if [ "$ans" = "y" ]; then
                cp "$sshd_config" "${sshd_config}.backup"
                sed -i 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/' "$sshd_config"
                sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' "$sshd_config"
                sed -i 's/^#Port 22/Port 2222/' "$sshd_config"
                systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || true
                echo -e "${GREEN}SSH hardened. Changes backed up to ${sshd_config}.backup${RESET}"
                echo -e "${YELLOW}Warning: SSH now on port 2222, root login disabled, passwords disabled${RESET}"
            fi
        fi
    else
        echo -e "${YELLOW}No SSH server installed.${RESET}"
    fi
}

audit_users() {
    echo -e "\n${YELLOW}=== USER & PERMISSION AUDIT ===${RESET}"
    echo "Users with UID 0 (root privileges):"
    awk -F: '($3 == 0) {print $1}' /etc/passwd
    echo ""
    echo "Users with empty passwords:"
    awk -F: '($2 == "" || $2 == "!") {print $1}' /etc/shadow 2>/dev/null || echo "  Cannot read /etc/shadow (requires root)"
    echo ""
    echo "Sudo group members:"
    grep -Po '^sudo:.*:\K.*$' /etc/group 2>/dev/null | tr ',' '\n' | sed 's/^/  /' || true
    echo ""
    echo "Last logins (10):"
    last -10 2>/dev/null || true
    echo ""
    echo "Failed SSH attempts (last 20):"
    journalctl -u sshd -u ssh --no-pager -n 20 2>/dev/null | grep -i "failed\|invalid" || echo "  None found"
}

audit_updates() {
    echo -e "\n${YELLOW}=== SYSTEM UPDATES ===${RESET}"
    if command -v apt &>/dev/null; then
        apt list --upgradable 2>/dev/null | grep -v "Listing..." | head -20
    elif command -v dnf &>/dev/null; then
        dnf check-update --quiet 2>/dev/null | head -20
    elif command -v pacman &>/dev/null; then
        pacman -Qu 2>/dev/null | head -20
    fi
    echo ""
    read -p "Install all security updates? (y/n): " ans
    if [ "$ans" = "y" ]; then
        if command -v apt &>/dev/null; then
            apt update && apt upgrade -y
        elif command -v dnf &>/dev/null; then
            dnf upgrade --security -y
        elif command -v pacman &>/dev/null; then
            pacman -Syu --noconfirm
        fi
        echo -e "${GREEN}Updates installed.${RESET}"
    fi
}

harden_sysctl() {
    echo -e "\n${YELLOW}=== KERNEL HARDENING (sysctl) ===${RESET}"
    local sysctl_file="/etc/sysctl.d/99-security.conf"
    if [ -f "$sysctl_file" ]; then
        echo -e "${GRAY}Current settings in $sysctl_file:${RESET}"
        cat "$sysctl_file"
    else
        echo -e "${YELLOW}No custom sysctl security settings found.${RESET}"
    fi
    
    read -p "Apply recommended kernel hardening? (y/n): " ans
    if [ "$ans" = "y" ]; then
        cat > "$sysctl_file" << 'EOF'
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
# Ignore source routed packets
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
# Ignore ICMP echo requests
net.ipv4.icmp_echo_ignore_all = 1
# Disable IP forwarding
net.ipv4.ip_forward = 0
# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
# Disable IPv6 if unwanted
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
        sysctl --system
        echo -e "${GREEN}Kernel hardened.${RESET}"
    fi
}

harden_file_perms() {
    echo -e "\n${YELLOW}=== FILE PERMISSION HARDENING ===${RESET}"
    echo "Fixing critical file permissions..."
    chmod 640 /etc/shadow 2>/dev/null
    chmod 640 /etc/gshadow 2>/dev/null
    chmod 644 /etc/passwd 2>/dev/null
    chmod 644 /etc/group 2>/dev/null
    chmod 600 /etc/ssh/sshd_config 2>/dev/null
    chmod 700 /root 2>/dev/null
    find /etc/sudoers.d -type f -exec chmod 440 {} \; 2>/dev/null
    chmod 440 /etc/sudoers 2>/dev/null
    echo -e "${GREEN}Critical file permissions hardened.${RESET}"
}

harden_firewall() {
    echo -e "\n${YELLOW}=== FIREWALL SETUP ===${RESET}"
    if command -v ufw &>/dev/null; then
        echo "UFW is available."
        if ! ufw status | grep -q "active"; then
            read -p "Enable UFW? (y/n): " ans
            if [ "$ans" = "y" ]; then
                ufw default deny incoming
                ufw default allow outgoing
                ufw allow ssh
                ufw enable
                echo -e "${GREEN}UFW enabled and configured.${RESET}"
            fi
        else
            echo -e "${GREEN}UFW is active.${RESET}"
            ufw status numbered | head -20
        fi
    elif command -v firewall-cmd &>/dev/null; then
        echo "FirewallD is available."
        firewall-cmd --list-all
    else
        echo -e "${YELLOW}No firewall detected. Install ufw or firewalld.${RESET}"
        read -p "Install ufw? (y/n): " ans
        if [ "$ans" = "y" ]; then
            if command -v apt &>/dev/null; then apt install -y ufw
            elif command -v dnf &>/dev/null; then dnf install -y ufw
            elif command -v pacman &>/dev/null; then pacman -S --noconfirm ufw
            fi
            ufw default deny incoming
            ufw default allow outgoing
            ufw allow ssh
            ufw --force enable
            echo -e "${GREEN}UFW installed and enabled.${RESET}"
        fi
    fi
}

audit_malware() {
    echo -e "\n${YELLOW}=== MALWARE SCAN ===${RESET}"
    if command -v clamscan &>/dev/null; then
        echo -e "${GRAY}ClamAV found. Scan home directories? (can be slow)${RESET}"
        read -p "Run quick scan (/home, /tmp)? (y/n): " ans
        if [ "$ans" = "y" ]; then
            clamscan -r --quiet /home /tmp 2>/dev/null
            echo -e "${GREEN}Scan completed.${RESET}"
        fi
    else
        echo -e "${YELLOW}ClamAV not installed.${RESET}"
        read -p "Install ClamAV? (y/n): " ans
        if [ "$ans" = "y" ]; then
            if command -v apt &>/dev/null; then apt install -y clamav; freshclam
            elif command -v dnf &>/dev/null; then dnf install -y clamav
            elif command -v pacman &>/dev/null; then pacman -S --noconfirm clamav
            fi
            echo -e "${GREEN}ClamAV installed.${RESET}"
        fi
    fi

    echo ""
    echo -e "${YELLOW}Rootkit check:${RESET}"
    if command -v rkhunter &>/dev/null; then
        rkhunter --check --skip-keypress --quiet 2>/dev/null | tail -5
    elif command -v chkrootkit &>/dev/null; then
        chkrootkit -q 2>/dev/null | tail -5
    else
        echo -e "${YELLOW}No rootkit detector found. Install rkhunter or chkrootkit.${RESET}"
    fi
}

show_menu() {
    show_banner
    echo -e " ${MAGENTA}---- SECURITY ASSESSMENT ----${RESET}"
    echo "   1.  Scan Open Ports & Services"
    echo "   2.  SSH Security Audit"
    echo "   3.  User & Permission Audit"
    echo "   4.  System Updates Check"
    echo ""
    echo -e " ${MAGENTA}---- HARDENING ----${RESET}"
    echo "   5.  Kernel Hardening (sysctl)"
    echo "   6.  File Permission Hardening"
    echo "   7.  Firewall Setup"
    echo "   8.  Malware & Rootkit Scan"
    echo ""
    echo -e " ${MAGENTA}---- GENERAL ----${RESET}"
    echo "   9.  Run Full Harden"
    echo "   0.  Exit"
    echo ""
}

main() {
    check_root
    detect_distro
    while true; do
        show_menu
        read -p "Select option (0-9): " c
        case "$c" in
            1) audit_ports; read -p "Press Enter..." ;;
            2) audit_ssh; read -p "Press Enter..." ;;
            3) audit_users; read -p "Press Enter..." ;;
            4) audit_updates; read -p "Press Enter..." ;;
            5) harden_sysctl; read -p "Press Enter..." ;;
            6) harden_file_perms; read -p "Press Enter..." ;;
            7) harden_firewall; read -p "Press Enter..." ;;
            8) audit_malware; read -p "Press Enter..." ;;
            9)
                echo -e "\n${YELLOW}Running Full Harden...${RESET}"
                audit_ports; audit_ssh; audit_users; audit_updates
                harden_sysctl; harden_file_perms; harden_firewall; audit_malware
                echo -e "\n${GREEN}Full hardening completed!${RESET}"
                read -p "Press Enter..." ;;
            0) echo -e "${CYAN}Goodbye!${RESET}"; exit 0 ;;
            *) echo -e "${RED}Invalid.${RESET}"; read -p "Press Enter..." ;;
        esac
    done
}

main "$@"
