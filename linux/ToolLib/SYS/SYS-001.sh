#!/bin/bash
# Tool: SYS-001 — System Information
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SYS-001"
TOOL_NAME="System Information"
TOOL_CATEGORY="SYS"
TOOL_DESC="Show OS, CPU, RAM, disk info"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}System Information${NC}"
    echo -e "  ${GRAY}Hostname:${NC}  $(hostname)"
    echo -e "  ${GRAY}OS:${NC}        $(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" || echo "Unknown")"
    echo -e "  ${GRAY}Kernel:${NC}    $(uname -r)"
    echo -e "  ${GRAY}Uptime:${NC}    $(uptime -p 2>/dev/null | sed 's/up //')"
    echo -e "  ${GRAY}CPU:${NC}       $(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs) ($(nproc 2>/dev/null) cores)"
    echo -e "  ${GRAY}RAM:${NC}       $(free -h | awk '/^Mem:/{print $2 " total / " $7 " free"}')"
    echo -e "  ${GRAY}Disk /:${NC}    $(df -h / | awk 'NR==2{print $2 " total / " $4 " free"}')"
    echo -e "  ${GRAY}IP:${NC}        $(ip route get 1 2>/dev/null | grep -oP 'src \K\S+' || echo "N/A")"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
