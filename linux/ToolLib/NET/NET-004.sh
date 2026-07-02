#!/bin/bash
# Tool: NET-004 — Port Scanner
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="NET-004"
TOOL_NAME="Port Scanner"
TOOL_CATEGORY="NET"
TOOL_DESC="Scan local listening ports with ss/netstat"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}Local Listening Ports${NC}"
    if command -v ss &>/dev/null; then
        echo -e "  ${GRAY}TCP listening ports:${NC}"
        ss -tlnp 2>/dev/null | head -30
        echo ""
        echo -e "  ${GRAY}UDP listening ports:${NC}"
        ss -ulnp 2>/dev/null | head -30
    elif command -v netstat &>/dev/null; then
        echo -e "  ${GRAY}TCP listening ports:${NC}"
        netstat -tlnp 2>/dev/null | head -30
        echo ""
        echo -e "  ${GRAY}UDP listening ports:${NC}"
        netstat -ulnp 2>/dev/null | head -30
    else
        echo -e "  ${YELLOW}[!] Neither ss nor netstat available${NC}"
    fi
    echo ""
    echo -e "  ${GRAY}Summary:${NC}"
    if command -v ss &>/dev/null; then
        ss -tlnp 2>/dev/null | awk 'NR>1{print $4}' | cut -d: -f2 | sort -n | uniq | while read -r p; do echo "  Port $p is listening"; done
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
