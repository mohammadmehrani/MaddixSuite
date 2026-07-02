#!/bin/bash
# Tool: SEC-001 — Security Audit
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SEC-001"
TOOL_NAME="Security Audit"
TOOL_CATEGORY="SEC"
TOOL_DESC="Check ports, SSH, users, sudoers"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}Security Audit${NC}"
    echo -e "  ${GRAY}Open ports:${NC}"
    ss -tlnp 2>/dev/null | head -20 || netstat -tlnp 2>/dev/null | head -20
    echo ""
    echo -e "  ${GRAY}SSH status:${NC}"
    systemctl is-active sshd 2>/dev/null && echo -e "  ${GREEN}[+] SSH running${NC}" || echo -e "  ${YELLOW}[!] SSH not active${NC}"
    if [[ -f /etc/ssh/sshd_config ]]; then
        grep -E "PermitRootLogin|PasswordAuthentication" /etc/ssh/sshd_config 2>/dev/null | grep -v "^#" | sed 's/^/  /'
    fi
    echo ""
    echo -e "  ${GRAY}Users with UID 0:${NC}"
    awk -F: '($3 == 0) {print "  " $1}' /etc/passwd
    echo ""
    echo -e "  ${GRAY}Sudo group:${NC}"
    grep -Po '^sudo:.*$' /etc/group 2>/dev/null | cut -d: -f4 | tr ',' '\n' | sed 's/^/  /'
    echo ""
    echo -e "  ${GRAY}Last logins:${NC}"
    last -10 2>/dev/null || echo "  No login history"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
