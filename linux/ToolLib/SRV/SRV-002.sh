#!/bin/bash
# Tool: SRV-002 — DNS Server
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SRV-002"
TOOL_NAME="DNS Server"
TOOL_CATEGORY="SRV"
TOOL_DESC="Install and configure bind9"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Install and configure Bind9 DNS server?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}[+] Installing Bind9...${NC}"
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu|mint|kali) apt-get install -y bind9 bind9utils ;;
            fedora|rhel|centos|rocky|alma) dnf install -y bind bind-utils ;;
            arch|manjaro) pacman -S --noconfirm bind ;;
            opensuse|suse) zypper install -y bind ;;
        esac
    fi
    if command -v named &>/dev/null; then
        echo -e "  ${GREEN}[+] Bind9 installed${NC}"
        echo -e "  ${GRAY}  Config: /etc/bind/named.conf${NC}"
        echo -e "  ${GRAY}  Zones: /etc/bind/zones/${NC}"
        mkdir -p /etc/bind/zones
        systemctl enable --now named 2>/dev/null || systemctl enable --now bind9 2>/dev/null
        echo -e "  ${GREEN}[+] Bind9 service started${NC}"
        echo -e "  ${GRAY}  Test: nslookup example.com localhost${NC}"
    else
        echo -e "  ${RED}[!!] Bind9 installation failed${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
