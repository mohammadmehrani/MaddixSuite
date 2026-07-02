#!/bin/bash
# Tool: SYS-006 — Disk Usage Analyzer
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SYS-006"
TOOL_NAME="Disk Usage Analyzer"
TOOL_CATEGORY="SYS"
TOOL_DESC="Show top directories by size"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}Disk Usage Overview${NC}"
    echo -e "  ${GRAY}Filesystem usage:${NC}"
    df -h | head -20
    echo ""
    echo -e "  ${GRAY}Top 20 directories by size (/*):${NC}"
    du -sh /* 2>/dev/null | sort -rh | head -20
    echo ""
    echo -e "  ${GRAY}Top 10 directories in /home:${NC}"
    if [[ -d /home ]]; then
        du -sh /home/* 2>/dev/null | sort -rh | head -10
    else
        echo -e "  ${YELLOW}[!] /home directory not found${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
