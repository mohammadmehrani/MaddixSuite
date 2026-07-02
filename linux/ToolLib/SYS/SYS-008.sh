#!/bin/bash
# Tool: SYS-008 — Journal Log Viewer
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SYS-008"
TOOL_NAME="Journal Log Viewer"
TOOL_CATEGORY="SYS"
TOOL_DESC="View systemd journal with filters"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}Journal Log Viewer${NC}"
    echo -e "  ${GRAY}1) Show last 50 log entries${NC}"
    echo -e "  ${GRAY}2) Show kernel messages (dmesg)${NC}"
    echo -e "  ${GRAY}3) Show errors from last boot${NC}"
    echo -e "  ${GRAY}4) Show logs for a specific service${NC}"
    echo -e "  ${GRAY}5) Show logs since last boot${NC}"
    echo -e "  ${GRAY}0) Back${NC}"
    echo -en "  ${CYAN}Select: ${NC}"; read -r sc
    case "$sc" in
        1) journalctl --no-pager -n 50 ;;
        2) dmesg | tail -50 ;;
        3) journalctl -p 3 -xb --no-pager -n 50 ;;
        4)
            echo -en "  ${GRAY}Service name: ${NC}"; read -r svc
            if [[ -n "$svc" ]]; then
                journalctl -u "$svc" --no-pager -n 50
            fi
            ;;
        5) journalctl -b --no-pager -n 50 ;;
        0) return ;;
        *) echo -e "  ${YELLOW}[!] Invalid option${NC}" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
