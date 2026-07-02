#!/bin/bash
# Tool: OPT-005 — Transparent Hugepages
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="OPT-005"
TOOL_NAME="Transparent Hugepages"
TOOL_CATEGORY="OPT"
TOOL_DESC="Disable THP for performance"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Disable Transparent Hugepages (recommended for databases, Redis)?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${CYAN}Transparent Hugepages${NC}"
    local current=$(cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null)
    echo -e "  ${GRAY}Current:${NC} $current"
    if echo "$current" | grep -q "\[never\]"; then
        echo -e "  ${GREEN}[+] THP already disabled${NC}"
    else
        echo -e "  ${GREEN}[+] Disabling THP...${NC}"
        echo "never" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null
        echo "never" > /sys/kernel/mm/transparent_hugepage/defrag 2>/dev/null
        cat > /etc/rc.local.d/thp-disable.sh 2>/dev/null << 'EOF'
if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]]; then
    echo "never" > /sys/kernel/mm/transparent_hugepage/enabled
    echo "never" > /sys/kernel/mm/transparent_hugepage/defrag
fi
EOF
        chmod +x /etc/rc.local.d/thp-disable.sh 2>/dev/null || true
        echo -e "  ${GREEN}[+] THP disabled (recommended for databases/Redis)${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
