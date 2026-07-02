#!/bin/bash
# Tool: OPT-004 — CPU Governor
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="OPT-004"
TOOL_NAME="CPU Governor"
TOOL_CATEGORY="OPT"
TOOL_DESC="Set performance governor"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Set CPU governor to 'performance'?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${CYAN}CPU Governor${NC}"
    local governors_found=false
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -f "$cpu" ]]; then
            governors_found=true
            local current=$(cat "$cpu" 2>/dev/null)
            local num=$(echo "$cpu" | grep -oP 'cpu\K\d+')
            echo -e "  ${GRAY}CPU $num:${NC} $current -> performance"
            echo "performance" > "$cpu" 2>/dev/null
        fi
    done
    if ! $governors_found; then
        echo -e "  ${YELLOW}[!] CPU frequency scaling not available${NC}"
        echo -e "  ${GRAY}This may be a VM or the acpi-cpufreq driver is not loaded${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}[+] All CPU cores set to performance governor${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
