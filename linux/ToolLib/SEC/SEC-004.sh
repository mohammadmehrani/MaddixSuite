#!/bin/bash
# Tool: SEC-004 — User Audit
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SEC-004"
TOOL_NAME="User Audit"
TOOL_CATEGORY="SEC"
TOOL_DESC="Check UID 0 users, empty passwords, sudo group"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}User Audit${NC}"
    echo -e "  ${GRAY}Users with UID 0 (root privileges):${NC}"
    local root_users=$(awk -F: '($3 == 0) {print $1}' /etc/passwd)
    echo "$root_users" | sed 's/^/  /'
    local root_count=$(echo "$root_users" | wc -l)
    if [[ "$root_count" -gt 1 ]]; then
        echo -e "  ${YELLOW}[!] Warning: Multiple users with UID 0 found${NC}"
    fi
    echo ""
    echo -e "  ${GRAY}Users with empty passwords:${NC}"
    local empty_pass=$(awk -F: '($2 == "" || $2 == "!") {print $1}' /etc/shadow 2>/dev/null)
    if [[ -n "$empty_pass" ]]; then
        echo "$empty_pass" | sed 's/^/  /'
        echo -e "  ${RED}[!!] Security risk: Users with empty passwords!${NC}"
    else
        echo -e "  ${GREEN}[+] No users with empty passwords${NC}"
    fi
    echo ""
    echo -e "  ${GRAY}Sudo group members:${NC}"
    grep -Po '^sudo:.*$' /etc/group 2>/dev/null | cut -d: -f4 | tr ',' '\n' | sed 's/^/  /'
    grep -Po '^wheel:.*$' /etc/group 2>/dev/null | cut -d: -f4 | tr ',' '\n' | sed 's/^/  /'
    echo ""
    echo -e "  ${GRAY}Recently modified users (last 24h):${NC}"
    find /etc -name "*.lock" -prune -o -type f \( -name "passwd" -o -name "shadow" -o -name "group" \) -mtime -1 -ls 2>/dev/null
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
