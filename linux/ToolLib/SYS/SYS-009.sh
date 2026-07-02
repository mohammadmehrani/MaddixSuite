#!/bin/bash
# Tool: SYS-009 — Kernel Module Manager
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SYS-009"
TOOL_NAME="Kernel Module Manager"
TOOL_CATEGORY="SYS"
TOOL_DESC="List/load/unload kernel modules"
TOOL_DANGER="Moderate"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${CYAN}Kernel Module Manager${NC}"
    echo -e "  ${GRAY}1) List loaded modules${NC}"
    echo -e "  ${GRAY}2) Load a module${NC}"
    echo -e "  ${GRAY}3) Unload a module${NC}"
    echo -e "  ${GRAY}4) Show module info${NC}"
    echo -e "  ${GRAY}5) List available modules${NC}"
    echo -e "  ${GRAY}0) Back${NC}"
    echo -en "  ${CYAN}Select: ${NC}"; read -r sc
    case "$sc" in
        1) lsmod | head -40 ;;
        2)
            echo -en "  ${GRAY}Module name: ${NC}"; read -r mod
            if [[ -n "$mod" ]]; then
                modprobe "$mod" && echo -e "  ${GREEN}[+] Module $mod loaded${NC}" || echo -e "  ${RED}[!!] Failed to load $mod${NC}"
            fi
            ;;
        3)
            echo -en "  ${GRAY}Module name: ${NC}"; read -r mod
            if [[ -n "$mod" ]]; then
                modprobe -r "$mod" && echo -e "  ${GREEN}[+] Module $mod unloaded${NC}" || echo -e "  ${RED}[!!] Failed to unload $mod${NC}"
            fi
            ;;
        4)
            echo -en "  ${GRAY}Module name: ${NC}"; read -r mod
            if [[ -n "$mod" ]]; then
                modinfo "$mod"
            fi
            ;;
        5)
            echo -e "  ${GRAY}Available modules (first 50):${NC}"
            find /lib/modules/$(uname -r) -name "*.ko*" 2>/dev/null | head -50 | while read -r m; do basename "$m" .ko*; done
            ;;
        0) return ;;
        *) echo -e "  ${YELLOW}[!] Invalid option${NC}" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
