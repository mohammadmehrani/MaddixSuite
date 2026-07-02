#!/bin/bash
# Tool: SYS-007 — Service Manager
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SYS-007"
TOOL_NAME="Service Manager"
TOOL_CATEGORY="SYS"
TOOL_DESC="List/restart/failed services via systemctl"
TOOL_DANGER="Moderate"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${CYAN}Service Manager${NC}"
    echo -e "  ${YELLOW}Failed services:${NC}"
    systemctl --failed --no-pager 2>/dev/null
    echo ""
    echo -e "  ${GRAY}1) List all running services${NC}"
    echo -e "  ${GRAY}2) Restart a service${NC}"
    echo -e "  ${GRAY}3) View service logs${NC}"
    echo -e "  ${GRAY}4) Reset failed services${NC}"
    echo -e "  ${GRAY}0) Back${NC}"
    echo -en "  ${CYAN}Select: ${NC}"; read -r sc
    case "$sc" in
        1) systemctl list-units --type=service --state=running --no-pager ;;
        2)
            echo -en "  ${GRAY}Service name: ${NC}"; read -r svc
            if [[ -n "$svc" ]]; then
                systemctl restart "$svc" 2>/dev/null && echo -e "  ${GREEN}[+] $svc restarted${NC}" || echo -e "  ${RED}[!!] Failed to restart $svc${NC}"
            fi
            ;;
        3)
            echo -en "  ${GRAY}Service name: ${NC}"; read -r svc
            if [[ -n "$svc" ]]; then
                journalctl -u "$svc" --no-pager -n 50
            fi
            ;;
        4) systemctl reset-failed && echo -e "  ${GREEN}[+] Failed services reset${NC}" ;;
        0) return ;;
        *) echo -e "  ${YELLOW}[!] Invalid option${NC}" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
