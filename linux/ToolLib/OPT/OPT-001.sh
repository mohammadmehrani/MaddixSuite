#!/bin/bash
# Tool: OPT-001 — Swappiness Tuning
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="OPT-001"
TOOL_NAME="Swappiness Tuning"
TOOL_CATEGORY="OPT"
TOOL_DESC="Set vm.swappiness to 10"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Set vm.swappiness to 10 (better for SSD)?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    local current=$(cat /proc/sys/vm/swappiness 2>/dev/null)
    echo -e "  ${GRAY}Current swappiness:${NC} $current"
    echo -e "  ${GREEN}[+] Setting swappiness to 10...${NC}"
    sysctl vm.swappiness=10
    echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf 2>/dev/null
    if [[ -f /etc/sysctl.d/99-swappiness.conf ]]; then
        echo -e "  ${GREEN}[+] Persistent setting saved to /etc/sysctl.d/99-swappiness.conf${NC}"
    fi
    echo -e "  ${GREEN}[+] Swappiness set to 10 (reduces swap usage, improves responsiveness)${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
