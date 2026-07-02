#!/bin/bash
# Tool: SYS-005 — Filesystem Check
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SYS-005"
TOOL_NAME="Filesystem Check"
TOOL_CATEGORY="SYS"
TOOL_DESC="Schedule fsck on next boot"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Schedule filesystem check on next boot?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${YELLOW}[!] Scheduling fsck on next boot...${NC}"
    touch /forcefsck && echo -e "  ${GREEN}[+] fsck will run on next boot${NC}" || echo -e "  ${RED}[!!] Failed to schedule fsck${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
