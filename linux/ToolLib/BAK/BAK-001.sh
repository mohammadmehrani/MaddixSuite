#!/bin/bash
# Tool: BAK-001 — Package Backup
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="BAK-001"
TOOL_NAME="Package Backup"
TOOL_CATEGORY="BAK"
TOOL_DESC="Save list of installed packages"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    local backup_dir="$HOME/MaddixSuite/Backups"
    mkdir -p "$backup_dir"
    local ts=$(date +%Y%m%d_%H%M%S)
    local f="$backup_dir/packages_$ts.list"
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu|mint|kali)
                dpkg --get-selections | grep -v deinstall > "$f"
                ;;
            fedora|rhel|centos|rocky|alma)
                dnf list installed > "$f" 2>/dev/null
                ;;
            arch|manjaro)
                pacman -Qqe > "$f"
                ;;
            opensuse|suse)
                zypper se --installed-only > "$f" 2>/dev/null
                ;;
            *)
                echo -e "  ${YELLOW}[!] Unsupported distro for package backup${NC}"
                return
                ;;
        esac
    fi
    if [[ -f "$f" ]]; then
        local lines=$(wc -l < "$f")
        echo -e "  ${GREEN}[+] Package list saved: $f${NC}"
        echo -e "  ${GRAY}[+] $lines packages backed up${NC}"
    else
        echo -e "  ${RED}[!!] Failed to create package backup${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
