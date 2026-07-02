#!/bin/bash
# Tool: SRV-001 — Samba Setup
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SRV-001"
TOOL_NAME="Samba Setup"
TOOL_CATEGORY="SRV"
TOOL_DESC="Install samba, basic share config"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Install and configure Samba?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}[+] Installing Samba...${NC}"
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu|mint|kali) apt-get install -y samba samba-common ;;
            fedora|rhel|centos|rocky|alma) dnf install -y samba samba-common ;;
            arch|manjaro) pacman -S --noconfirm samba ;;
            opensuse|suse) zypper install -y samba ;;
        esac
    fi
    if command -v smbd &>/dev/null; then
        local share="/srv/samba/share"
        mkdir -p "$share"
        chmod 0777 "$share"
        cat >> /etc/samba/smb.conf << 'EOF'

[shared]
   path = /srv/samba/share
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0777
   directory mask = 0777
EOF
        systemctl enable --now smbd 2>/dev/null || systemctl enable --now smb 2>/dev/null
        echo -e "  ${GREEN}[+] Samba installed and configured${NC}"
        echo -e "  ${GRAY}  Share: //$(hostname)/shared${NC}"
        echo -e "  ${GRAY}  Path: /srv/samba/share${NC}"
        echo -e "  ${YELLOW}[!] Configure firewall: ufw allow samba${NC}"
    else
        echo -e "  ${RED}[!!] Samba installation failed${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
