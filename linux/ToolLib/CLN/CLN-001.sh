#!/bin/bash
# Tool: CLN-001 — System Cleanup
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="CLN-001"
TOOL_NAME="System Cleanup"
TOOL_CATEGORY="CLN"
TOOL_DESC="Clean package cache, orphans, temp"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Clean package cache, orphans, and temp files?"

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
                echo -e "  ${GREEN}[+] Removing orphan packages...${NC}"
                apt-get autoremove -y
                echo -e "  ${GREEN}[+] Cleaning package cache...${NC}"
                apt-get autoclean -y
                apt-get clean -y
                ;;
            fedora|rhel|centos|rocky|alma)
                echo -e "  ${GREEN}[+] Removing orphan packages...${NC}"
                dnf autoremove -y
                echo -e "  ${GREEN}[+] Cleaning cache...${NC}"
                dnf clean all
                ;;
            arch|manjaro)
                echo -e "  ${GREEN}[+] Removing orphans...${NC}"
                pacman -Rns $(pacman -Qdtq 2>/dev/null) --noconfirm 2>/dev/null || true
                echo -e "  ${GREEN}[+] Cleaning cache...${NC}"
                pacman -Sc --noconfirm
                ;;
            opensuse|suse)
                echo -e "  ${GREEN}[+] Cleaning zypper cache...${NC}"
                zypper clean -a
                ;;
        esac
    fi
    echo -e "  ${GREEN}[+] Cleaning journal (vacuum to 200M)...${NC}"
    journalctl --vacuum-size=200M 2>/dev/null || true
    echo -e "  ${GREEN}[+] Cleaning temp files...${NC}"
    rm -rf /tmp/* 2>/dev/null
    rm -rf /var/tmp/* 2>/dev/null
    echo -e "  ${GREEN}[+] System cleanup complete${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
