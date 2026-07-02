#!/bin/bash
# Tool: SRV-003 — DHCP Server
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SRV-003"
TOOL_NAME="DHCP Server"
TOOL_CATEGORY="SRV"
TOOL_DESC="Install ISC DHCP server"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Install ISC DHCP server?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}[+] Installing ISC DHCP Server...${NC}"
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu|mint|kali)
                apt-get install -y isc-dhcp-server
                local iface=$(ip route | grep default | awk '{print $5}' | head -1)
                if [[ -n "$iface" ]]; then
                    sed -i "s/INTERFACESv4=\"\"/INTERFACESv4=\"$iface\"/" /etc/default/isc-dhcp-server 2>/dev/null
                fi
                ;;
            fedora|rhel|centos|rocky|alma)
                dnf install -y dhcp-server
                ;;
            arch|manjaro)
                pacman -S --noconfirm dhcp
                ;;
            *)
                echo -e "  ${YELLOW}[!] Unsupported distro${NC}"
                return
                ;;
        esac
    fi
    if command -v dhcpd &>/dev/null; then
        echo -e "  ${GREEN}[+] DHCP server installed${NC}"
        echo -e "  ${GRAY}  Config: /etc/dhcp/dhcpd.conf${NC}"
        echo -e "  ${YELLOW}[!] Edit /etc/dhcp/dhcpd.conf to configure subnets${NC}"
        systemctl enable --now dhcpd 2>/dev/null || systemctl enable --now isc-dhcp-server 2>/dev/null
    else
        echo -e "  ${RED}[!!] DHCP server installation failed${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
