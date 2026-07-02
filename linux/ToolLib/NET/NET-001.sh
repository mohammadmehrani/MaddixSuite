#!/bin/bash
# Tool: NET-001 — Network Diagnostic
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="NET-001"
TOOL_NAME="Network Diagnostic"
TOOL_CATEGORY="NET"
TOOL_DESC="Show interfaces, IP, DNS, connectivity"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}Network Diagnostic${NC}"
    echo -e "  ${GRAY}Interfaces:${NC}"
    ip -br addr show 2>/dev/null || ifconfig 2>/dev/null
    echo ""
    echo -e "  ${GRAY}Routing:${NC}"
    ip route show 2>/dev/null || route -n 2>/dev/null
    echo ""
    echo -e "  ${GRAY}DNS:${NC}"
    cat /etc/resolv.conf 2>/dev/null
    echo ""
    echo -e "  ${GRAY}Connectivity:${NC}"
    ping -c 2 -W 2 8.8.8.8 &>/dev/null && echo -e "  ${GREEN}[+] Internet: OK${NC}" || echo -e "  ${RED}[!!] Internet: FAIL${NC}"
    ping -c 2 -W 2 google.com &>/dev/null && echo -e "  ${GREEN}[+] DNS resolution: OK${NC}" || echo -e "  ${YELLOW}[!] DNS resolution: FAIL${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
