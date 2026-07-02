#!/bin/bash
# Tool: SRV-004 — Web Server
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SRV-004"
TOOL_NAME="Web Server"
TOOL_CATEGORY="SRV"
TOOL_DESC="Install nginx/apache"
TOOL_DANGER="Moderate"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${CYAN}Web Server Installer${NC}"
    echo -e "  ${GRAY}1) Install Nginx${NC}"
    echo -e "  ${GRAY}2) Install Apache${NC}"
    echo -e "  ${GRAY}0) Back${NC}"
    echo -en "  ${CYAN}Select: ${NC}"; read -r sc
    case "$sc" in
        1)
            echo -e "  ${GREEN}[+] Installing Nginx...${NC}"
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                case "$ID" in
                    debian|ubuntu|mint|kali) apt-get install -y nginx ;;
                    fedora|rhel|centos|rocky|alma) dnf install -y nginx ;;
                    arch|manjaro) pacman -S --noconfirm nginx ;;
                    opensuse|suse) zypper install -y nginx ;;
                esac
            fi
            systemctl enable --now nginx 2>/dev/null
            echo -e "  ${GREEN}[+] Nginx installed and running${NC}"
            echo -e "  ${GRAY}  Default root: /var/www/html${NC}"
            echo -e "  ${GRAY}  Config: /etc/nginx/nginx.conf${NC}"
            ;;
        2)
            echo -e "  ${GREEN}[+] Installing Apache...${NC}"
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                case "$ID" in
                    debian|ubuntu|mint|kali) apt-get install -y apache2 ;;
                    fedora|rhel|centos|rocky|alma) dnf install -y httpd ;;
                    arch|manjaro) pacman -S --noconfirm apache ;;
                    opensuse|suse) zypper install -y apache2 ;;
                esac
            fi
            systemctl enable --now apache2 2>/dev/null || systemctl enable --now httpd 2>/dev/null
            echo -e "  ${GREEN}[+] Apache installed and running${NC}"
            echo -e "  ${GRAY}  Default root: /var/www/html${NC}"
            ;;
        0) return ;;
        *) echo -e "  ${YELLOW}[!] Invalid option${NC}" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
