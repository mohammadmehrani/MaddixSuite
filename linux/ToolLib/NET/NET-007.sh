#!/bin/bash
# Tool: NET-007 — Traceroute
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="NET-007"
TOOL_NAME="Traceroute"
TOOL_CATEGORY="NET"
TOOL_DESC="Trace route to target host"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}Traceroute${NC}"
    echo -en "  ${GRAY}Target host: ${NC}"; read -r target
    if [[ -z "$target" ]]; then
        target="google.com"
        echo -e "  ${YELLOW}[!] Using default: $target${NC}"
    fi
    if command -v traceroute &>/dev/null; then
        traceroute -n "$target"
    elif command -v tracepath &>/dev/null; then
        tracepath -n "$target"
    elif command -v mtr &>/dev/null; then
        mtr -r -c 5 "$target"
    else
        echo -e "  ${YELLOW}[!] No traceroute tool available${NC}"
        echo -e "  ${GRAY}Using ping with TTL...${NC}"
        ping -c 1 -t 1 "$target" &>/dev/null
        for ttl in {1..30}; do
            ping -c 1 -t "$ttl" -W 1 "$target" 2>/dev/null | grep "from" | head -1
        done
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
