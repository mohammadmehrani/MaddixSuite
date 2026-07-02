#!/bin/bash
# Tool: OPT-003 — I/O Scheduler
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="OPT-003"
TOOL_NAME="I/O Scheduler"
TOOL_CATEGORY="OPT"
TOOL_DESC="Set I/O scheduler for SSD/HDD"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Set optimal I/O scheduler for SSD/HDD?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${CYAN}I/O Scheduler Tuning${NC}"
    for disk in /sys/block/{sd*,nvme*,vd*,xvd*}; do
        if [[ -d "$disk" ]]; then
            local name=$(basename "$disk")
            local rotational=$(cat "$disk/queue/rotational" 2>/dev/null)
            local schedulers=$(cat "$disk/queue/scheduler" 2>/dev/null)
            echo -e "  ${GRAY}Device $name:${NC} $schedulers"
            if [[ -f "$disk/queue/scheduler" ]]; then
                if [[ "$rotational" == "1" ]]; then
                    echo -e "  ${YELLOW}[!] HDD detected - setting mq-deadline${NC}"
                    echo "mq-deadline" > "$disk/queue/scheduler" 2>/dev/null
                else
                    echo -e "  ${GREEN}[+] SSD/NVMe detected - setting none (NOOP)${NC}"
                    echo "none" > "$disk/queue/scheduler" 2>/dev/null
                fi
                echo -e "  ${GREEN}  [+] Set to:$(cat "$disk/queue/scheduler" 2>/dev/null)${NC}"
            fi
        fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
