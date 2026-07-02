#!/bin/bash
# Tool: SYS-003 — Package Manager Fix
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SYS-003"
TOOL_NAME="Package Manager Fix"
TOOL_CATEGORY="SYS"
TOOL_DESC="Fix broken packages, configure dpkg"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Fix package manager and broken packages?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu|mint|kali)
                echo -e "  ${GREEN}[+] Configuring dpkg...${NC}"
                dpkg --configure -a
                echo -e "  ${GREEN}[+] Fixing broken packages...${NC}"
                apt-get --fix-broken install -y
                echo -e "  ${GREEN}[+] Updating package lists...${NC}"
                apt-get update
                echo -e "  ${GREEN}[+] Package manager fixed${NC}"
                ;;
            fedora|rhel|centos|rocky|alma)
                echo -e "  ${GREEN}[+] Checking package consistency...${NC}"
                dnf check
                echo -e "  ${GREEN}[+] Package manager checked${NC}"
                ;;
            arch|manjaro)
                echo -e "  ${GREEN}[+] Syncing package databases...${NC}"
                pacman -Sy
                echo -e "  ${GREEN}[+] Package manager synced${NC}"
                ;;
            opensuse|suse)
                echo -e "  ${GREEN}[+] Refreshing repositories...${NC}"
                zypper refresh
                echo -e "  ${GREEN}[+] Package manager refreshed${NC}"
                ;;
            *)
                echo -e "  ${YELLOW}[!] Unsupported distro: $ID${NC}"
                ;;
        esac
    else
        echo -e "  ${RED}[!!] Cannot detect OS${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
