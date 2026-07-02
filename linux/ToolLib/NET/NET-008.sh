#!/bin/bash
# Tool: NET-008 — Network Stats
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="NET-008"
TOOL_NAME="Network Stats"
TOOL_CATEGORY="NET"
TOOL_DESC="Show interface statistics, bandwidth"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}Network Statistics${NC}"
    echo -e "  ${GRAY}Interface statistics:${NC}"
    if command -v ip &>/dev/null; then
        ip -s link 2>/dev/null | head -60
    elif command -v ifconfig &>/dev/null; then
        ifconfig -s 2>/dev/null
    fi
    echo ""
    echo -e "  ${GRAY}Bandwidth usage (by device):${NC}"
    if [[ -d /sys/class/net ]]; then
        for iface in /sys/class/net/*; do
            name=$(basename "$iface")
            rx=$(cat "$iface/statistics/rx_bytes" 2>/dev/null)
            tx=$(cat "$iface/statistics/tx_bytes" 2>/dev/null)
            echo -e "  ${GRAY}$name:${NC} RX=$(numfmt --to=iec $rx 2>/dev/null || echo $rx) TX=$(numfmt --to=iec $tx 2>/dev/null || echo $tx)"
        done
    fi
    echo ""
    echo -e "  ${GRAY}Active connections:${NC}"
    ss -s 2>/dev/null || netstat -s 2>/dev/null | head -20
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
