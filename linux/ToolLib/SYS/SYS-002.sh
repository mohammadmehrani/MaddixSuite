#!/bin/bash
# Tool: SYS-002 — System Update
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SYS-002"
TOOL_NAME="System Update"
TOOL_CATEGORY="SYS"
TOOL_DESC="Update package lists and upgrade system"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Update package lists and upgrade all packages?"

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
                echo -e "  ${GREEN}[+] Updating package lists...${NC}"
                apt-get update && echo -e "  ${GREEN}[+] Package lists updated${NC}"
                echo -e "  ${GREEN}[+] Upgrading packages...${NC}"
                apt-get upgrade -y && apt-get dist-upgrade -y
                echo -e "  ${GREEN}[+] System upgraded${NC}"
                ;;
            fedora|rhel|centos|rocky|alma)
                echo -e "  ${GREEN}[+] Updating packages...${NC}"
                dnf upgrade -y && echo -e "  ${GREEN}[+] System upgraded${NC}"
                ;;
            arch|manjaro)
                echo -e "  ${GREEN}[+] Updating packages...${NC}"
                pacman -Syu --noconfirm && echo -e "  ${GREEN}[+] System upgraded${NC}"
                ;;
            opensuse|suse)
                echo -e "  ${GREEN}[+] Updating packages...${NC}"
                zypper update -y && echo -e "  ${GREEN}[+] System upgraded${NC}"
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
