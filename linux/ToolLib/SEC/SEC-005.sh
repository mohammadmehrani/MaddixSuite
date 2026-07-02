#!/bin/bash
# Tool: SEC-005 — SUID Scanner
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SEC-005"
TOOL_NAME="SUID Scanner"
TOOL_CATEGORY="SEC"
TOOL_DESC="Find SUID/SGID binaries"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}SUID/SGID Scanner${NC}"
    echo -e "  ${GRAY}SUID binaries (setuid):${NC}"
    find / -type f -perm -4000 -not -path "/proc/*" -not -path "/sys/*" -not -path "/run/*" 2>/dev/null | while read -r f; do
        echo -e "  ${YELLOW}[SUID]${NC} $f"
    done
    echo ""
    echo -e "  ${GRAY}SGID binaries (setgid):${NC}"
    find / -type f -perm -2000 -not -path "/proc/*" -not -path "/sys/*" -not -path "/run/*" 2>/dev/null | while read -r f; do
        echo -e "  ${YELLOW}[SGID]${NC} $f"
    done
    echo ""
    local suid_count=$(find / -type f -perm -4000 -not -path "/proc/*" -not -path "/sys/*" -not -path "/run/*" 2>/dev/null | wc -l)
    local sgid_count=$(find / -type f -perm -2000 -not -path "/proc/*" -not -path "/sys/*" -not -path "/run/*" 2>/dev/null | wc -l)
    echo -e "  ${GRAY}Total:${NC} $suid_count SUID, $sgid_count SGID"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
