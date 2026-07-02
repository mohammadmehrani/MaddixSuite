#!/bin/bash
# Tool: SEC-007 — Failed Login Check
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SEC-007"
TOOL_NAME="Failed Login Check"
TOOL_CATEGORY="SEC"
TOOL_DESC="Show failed SSH login attempts"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}Failed Login Check${NC}"
    local auth_log=""
    if [[ -f /var/log/auth.log ]]; then
        auth_log="/var/log/auth.log"
    elif [[ -f /var/log/secure ]]; then
        auth_log="/var/log/secure"
    fi
    if [[ -n "$auth_log" ]]; then
        echo -e "  ${GRAY}Failed SSH login attempts:${NC}"
        grep "Failed password" "$auth_log" 2>/dev/null | tail -20 | sed 's/^/  /'
        local fail_count=$(grep "Failed password" "$auth_log" 2>/dev/null | wc -l)
        echo ""
        echo -e "  ${GRAY}Total failed attempts:${NC} $fail_count"
        echo ""
        echo -e "  ${GRAY}Failed attempts by IP:${NC}"
        grep "Failed password" "$auth_log" 2>/dev/null | grep -oP 'from \K\S+' | sort | uniq -c | sort -rn | head -10 | sed 's/^/  /'
        echo ""
        echo -e "  ${GRAY}Failed attempts by user:${NC}"
        grep "Failed password" "$auth_log" 2>/dev/null | grep -oP 'for \K\S+' | sort | uniq -c | sort -rn | head -10 | sed 's/^/  /'
    else
        echo -e "  ${YELLOW}[!] No auth log found${NC}"
        echo -e "  ${GRAY}Trying journalctl...${NC}"
        journalctl -u sshd -u ssh --no-pager 2>/dev/null | grep -i "failed" | tail -20 | sed 's/^/  /'
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
