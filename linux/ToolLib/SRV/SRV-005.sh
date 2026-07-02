#!/bin/bash
# Tool: SRV-005 — Database Server
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SRV-005"
TOOL_NAME="Database Server"
TOOL_CATEGORY="SRV"
TOOL_DESC="Install MySQL/PostgreSQL"
TOOL_DANGER="Moderate"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${CYAN}Database Server Installer${NC}"
    echo -e "  ${GRAY}1) Install MySQL${NC}"
    echo -e "  ${GRAY}2) Install PostgreSQL${NC}"
    echo -e "  ${GRAY}3) Install both${NC}"
    echo -e "  ${GRAY}0) Back${NC}"
    echo -en "  ${CYAN}Select: ${NC}"; read -r sc
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$sc" in
            1|3)
                echo -e "  ${GREEN}[+] Installing MySQL...${NC}"
                case "$ID" in
                    debian|ubuntu|mint|kali) apt-get install -y mysql-server ;;
                    fedora|rhel|centos|rocky|alma) dnf install -y mysql-server ;;
                    arch|manjaro) pacman -S --noconfirm mysql ;;
                    opensuse|suse) zypper install -y mysql ;;
                esac
                systemctl enable --now mysql 2>/dev/null || systemctl enable --now mariadb 2>/dev/null
                if command -v mysql &>/dev/null; then
                    echo -e "  ${GREEN}[+] MySQL installed: $(mysql --version 2>/dev/null)${NC}"
                    echo -e "  ${YELLOW}[!] Run mysql_secure_installation to secure${NC}"
                fi
                ;;
        esac
        case "$sc" in
            2|3)
                echo -e "  ${GREEN}[+] Installing PostgreSQL...${NC}"
                case "$ID" in
                    debian|ubuntu|mint|kali) apt-get install -y postgresql postgresql-contrib ;;
                    fedora|rhel|centos|rocky|alma) dnf install -y postgresql-server postgresql-contrib ;;
                    arch|manjaro) pacman -S --noconfirm postgresql ;;
                    opensuse|suse) zypper install -y postgresql ;;
                esac
                systemctl enable --now postgresql 2>/dev/null
                if command -v psql &>/dev/null; then
                    echo -e "  ${GREEN}[+] PostgreSQL installed: $(psql --version 2>/dev/null)${NC}"
                fi
                ;;
            0) return ;;
            *) echo -e "  ${YELLOW}[!] Invalid option${NC}" ;;
        esac
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
