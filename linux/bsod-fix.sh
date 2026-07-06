#!/usr/bin/env bash
# MaddixSuite - BSOD Diagnostic (Linux)
# Author: Mohammad Mehrani (Maddix)
# Repository: https://github.com/mohammadmehrani/MaddixSuite
# Website: https://mohammadmehrani.github.io/

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'
LOG="$HOME/bsod_diag_report.txt"
REBOOT_FILE="/tmp/bsod_fix_reboot"

banner() {
    echo -e "${CYAN}"
    echo "    /\_/\   MaddixSuite - BSOD Diagnostic (Linux)"
    echo "   ( o.o )  Author: Mohammad Mehrani (Maddix)"
    echo "    > ^ <   https://github.com/mohammadmehrani/MaddixSuite"
    echo -e "${NC}"
    echo ""
}

step() { echo -e "  ${GREEN}[✓]${NC} $1"; }
warn() { echo -e "  ${YELLOW}[!]${NC} $1"; }
err()  { echo -e "  ${RED}[X]${NC} $1"; }
info() { echo -e "  ${CYAN}[i]${NC} $1"; }
sep()  { echo -e "\n${YELLOW}=== $1 ===${NC}\n"; }

phase1_diagnostic() {
    sep "PHASE 1: SYSTEM DIAGNOSTIC"

    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"

    local CRASH_COUNT=0
    if command -v journalctl &>/dev/null; then
        CRASH_COUNT=$(journalctl -q -k -p crit --since "7 days ago" 2>/dev/null | grep -ci "panic\|oops\|bug" || echo 0)
    elif [ -f /var/log/kern.log ]; then
        CRASH_COUNT=$(grep -ci "panic\|oops" /var/log/kern.log 2>/dev/null || echo 0)
    fi

    if [ "$CRASH_COUNT" -gt 0 ]; then
        err "$CRASH_COUNT kernel crash(es) detected in the last 7 days"
        journalctl -q -k -p crit --since "7 days ago" --no-pager -n 5 2>/dev/null | head -30
    else
        step "No recent kernel crashes"
    fi

    local SWAP_MB=$(free -m | awk '/Swap:/{print $2}')
    info "Swap size: ${SWAP_MB}MB"
    if [ "$SWAP_MB" -lt 2048 ]; then
        warn "Small swap may cause memory pressure"
    fi

    local DISK_USE=$(df / | awk 'NR>1{print $5}' | tr -d '%')
    if [ "$DISK_USE" -gt 90 ]; then
        err "Disk usage critical: ${DISK_USE}%"
    elif [ "$DISK_USE" -gt 80 ]; then
        warn "Disk usage: ${DISK_USE}%"
    else
        step "Disk usage: ${DISK_USE}%"
    fi
}

phase2_optimize() {
    sep "PHASE 2: OPTIMIZATION"

    info "Cleaning package cache..."
    if command -v apt-get &>/dev/null; then
        apt-get clean -y 2>/dev/null && step "APT cache cleaned"
    elif command -v dnf &>/dev/null; then
        dnf clean all 2>/dev/null && step "DNF cache cleaned"
    elif command -v pacman &>/dev/null; then
        pacman -Scc --noconfirm 2>/dev/null && step "Pacman cache cleaned"
    fi

    info "Cleaning journal logs..."
    journalctl --vacuum-time=7d 2>/dev/null && step "Journal logs trimmed to 7 days"

    info "Cleaning temp files..."
    rm -rf /tmp/* 2>/dev/null || true
    step "Temp files cleaned"

    if [ -f /etc/default/grub ]; then
        local CURRENT_SWAP=$(grep -c "vm.swappiness" /etc/sysctl.d/*.conf 2>/dev/null || echo 0)
        if [ "$CURRENT_SWAP" -eq 0 ]; then
            warn "Swappiness not optimized. Consider: sysctl vm.swappiness=10"
        fi
    fi
}

phase3_report() {
    sep "PHASE 3: REPORT"
    {
        echo "=========================================="
        echo "BSOD Diagnostic Report - $(date)"
        echo "=========================================="
        echo ""
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -r)"
        echo "Uptime: $(uptime -p)"
        echo ""
        echo "--- Memory ---"
        free -h
        echo ""
        echo "--- Disk ---"
        df -h /
        echo ""
        echo "--- Kernel Crashes (7 days) ---"
        journalctl -q -k -p crit --since "7 days ago" --no-pager 2>/dev/null || echo "No journalctl access"
        echo ""
        echo "=========================================="
    } > "$LOG"
    step "Report saved to $LOG"
}

footer() {
    echo ""
    echo -e "${CYAN}    ___   ____________________________________________________________${NC}"
    echo -e "${CYAN}   /   |  Author: Mohammad Mehrani (Maddix)${NC}"
    echo -e "${CYAN}  / /| |  Repository: https://github.com/mohammadmehrani/MaddixSuite${NC}"
    echo -e "${CYAN} /_/ |_|  Website: https://mohammadmehrani.github.io/${NC}"
    echo -e "${CYAN}          \"Empower yourself with the right tools\"${NC}"
    echo ""
}

main() {
    banner
    phase1_diagnostic
    echo ""
    read -rp "Apply optimizations? (Y/n): " choice
    if [ "${choice:-Y}" = "Y" ] || [ "${choice:-Y}" = "y" ]; then
        phase2_optimize
    fi
    phase3_report
    footer
}

main "$@"