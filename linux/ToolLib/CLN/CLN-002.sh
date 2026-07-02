#!/bin/bash
# Tool: CLN-002 — Journal Cleanup
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="CLN-002"
TOOL_NAME="Journal Cleanup"
TOOL_CATEGORY="CLN"
TOOL_DESC="Vacuum journal logs to 100MB"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Vacuum journal logs to 100MB?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    local current=$(journalctl --disk-usage 2>/dev/null)
    echo -e "  ${GRAY}Current journal usage:${NC}"
    echo "  $current"
    echo ""
    echo -e "  ${GREEN}[+] Vacuuming journal to 100MB...${NC}"
    journalctl --vacuum-size=100M 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo -e "  ${GREEN}[+] Journal cleaned to 100MB${NC}"
    else
        echo -e "  ${RED}[!!] Failed to vacuum journal${NC}"
    fi
    local after=$(journalctl --disk-usage 2>/dev/null)
    echo -e "  ${GRAY}After cleanup:${NC}"
    echo "  $after"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
