#!/bin/bash
# Tool: BAK-002 — Config Backup
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="BAK-002"
TOOL_NAME="Config Backup"
TOOL_CATEGORY="BAK"
TOOL_DESC="Backup /etc and /home to archive"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    local backup_dir="$HOME/MaddixSuite/Backups"
    mkdir -p "$backup_dir"
    local ts=$(date +%Y%m%d_%H%M%S)
    local f="$backup_dir/configs_$ts.tar.gz"
    echo -e "  ${GREEN}[+] Backing up /etc and /home...${NC}"
    tar -czf "$f" /etc 2>/dev/null
    if [[ -d /home ]]; then
        tar -czf "$backup_dir/home_$ts.tar.gz" /home 2>/dev/null
        echo -e "  ${GREEN}[+] /home backed up separately${NC}"
    fi
    if [[ -f "$f" ]]; then
        local size=$(du -h "$f" | cut -f1)
        echo -e "  ${GREEN}[+] Config backup saved: $f${NC}"
        echo -e "  ${GRAY}[+] Size: $size${NC}"
        echo -e "  ${GREEN}[+] Backup directory: $backup_dir${NC}"
    else
        echo -e "  ${RED}[!!] Backup failed${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
