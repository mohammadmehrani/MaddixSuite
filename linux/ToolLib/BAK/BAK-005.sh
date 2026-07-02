#!/bin/bash
# Tool: BAK-005 — Restore Packages
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="BAK-005"
TOOL_NAME="Restore Packages"
TOOL_CATEGORY="BAK"
TOOL_DESC="Restore packages from backup list"
TOOL_DANGER="High"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    local backup_dir="$HOME/MaddixSuite/Backups"
    local files=("$backup_dir"/packages_*.list)
    if [[ ${#files[@]} -eq 0 ]] || [[ ! -f "${files[0]}" ]]; then
        echo -e "  ${YELLOW}[!] No package backup lists found in $backup_dir${NC}"
        exit 1
    fi
    echo -e "  ${CYAN}Available backups:${NC}"
    local i=1
    for f in "${files[@]}"; do
        if [[ -f "$f" ]]; then
            echo -e "  ${GRAY}$i)${NC} $(basename "$f") ($(wc -l < "$f") packages)"
            ((i++))
        fi
    done
    echo -en "  ${CYAN}Select backup number: ${NC}"; read -r sel
    local idx=$((sel - 1))
    if [[ $idx -ge 0 ]] && [[ $idx -lt ${#files[@]} ]]; then
        local selected="${files[$idx]}"
        echo -e "  ${GREEN}[+] Restoring from $(basename "$selected")...${NC}"
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            case "$ID" in
                debian|ubuntu|mint|kali)
                    dpkg --clear-selections
                    dpkg --set-selections < "$selected"
                    apt-get dselect-upgrade -y
                    echo -e "  ${GREEN}[+] Packages restored via apt${NC}"
                    ;;
                arch|manjaro)
                    pacman -S --needed - < "$selected"
                    echo -e "  ${GREEN}[+] Packages restored via pacman${NC}"
                    ;;
                *)
                    echo -e "  ${YELLOW}[!] Restore not implemented for $ID${NC}"
                    ;;
            esac
        fi
    else
        echo -e "  ${RED}[!!] Invalid selection${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
