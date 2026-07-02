#!/bin/bash
# Tool: SEC-006 — File Permissions Check
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SEC-006"
TOOL_NAME="File Permissions Check"
TOOL_CATEGORY="SEC"
TOOL_DESC="Find world-writable files"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}File Permissions Check${NC}"
    echo -e "  ${GRAY}World-writable directories:${NC}"
    find / -type d -perm -o+w -not -path "/proc/*" -not -path "/sys/*" -not -path "/run/*" -not -path "/tmp/*" 2>/dev/null | head -20
    echo ""
    echo -e "  ${GRAY}World-writable files:${NC}"
    find / -type f -perm -o+w -not -path "/proc/*" -not -path "/sys/*" -not -path "/run/*" -not -path "/tmp/*" 2>/dev/null | head -20
    echo ""
    echo -e "  ${GRAY}No-owner files:${NC}"
    find / -nouser -not -path "/proc/*" -not -path "/sys/*" 2>/dev/null | head -10
    echo ""
    echo -e "  ${GRAY}No-group files:${NC}"
    find / -nogroup -not -path "/proc/*" -not -path "/sys/*" 2>/dev/null | head -10
    local ww_count=$(find / -type f -perm -o+w -not -path "/proc/*" -not -path "/sys/*" -not -path "/run/*" -not -path "/tmp/*" 2>/dev/null | wc -l)
    echo ""
    echo -e "  ${GRAY}Total world-writable files:${NC} $ww_count"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
