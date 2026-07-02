#!/bin/bash
# Tool: SEC-008 — Kernel Security Check
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SEC-008"
TOOL_NAME="Kernel Security Check"
TOOL_CATEGORY="SEC"
TOOL_DESC="Check sysctl security parameters"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}Kernel Security Parameters${NC}"
    local checks=(
        "net.ipv4.ip_forward:IP forwarding:0"
        "net.ipv4.conf.all.rp_filter:Reverse path filter:1"
        "net.ipv4.conf.default.rp_filter:Reverse path filter (default):1"
        "net.ipv4.tcp_syncookies:TCP SYN cookies:1"
        "net.ipv4.icmp_echo_ignore_broadcasts:ICMP broadcast ignore:1"
        "net.ipv4.icmp_ignore_bogus_error_responses:ICMP bogus errors:1"
        "net.ipv4.conf.all.accept_source_route:Source route accept:0"
        "net.ipv4.conf.default.accept_source_route:Source route accept (default):0"
        "net.ipv4.conf.all.accept_redirects:Accept redirects:0"
        "net.ipv4.conf.default.accept_redirects:Accept redirects (default):0"
        "net.ipv4.conf.all.secure_redirects:Secure redirects:1"
        "net.ipv4.conf.default.secure_redirects:Secure redirects (default):1"
        "net.ipv4.conf.all.send_redirects:Send redirects:0"
        "net.ipv4.conf.default.send_redirects:Send redirects (default):0"
        "net.ipv6.conf.all.accept_redirects:IPv6 accept redirects:0"
        "net.ipv6.conf.default.accept_redirects:IPv6 accept redirects (default):0"
        "kernel.randomize_va_space:ASLR:2"
        "kernel.kptr_restrict:Kernel pointer restrict:2"
        "kernel.dmesg_restrict:Dmesg restrict:1"
        "fs.protected_hardlinks:Protected hardlinks:1"
        "fs.protected_symlinks:Protected symlinks:1"
    )
    for check in "${checks[@]}"; do
        local param=$(echo "$check" | cut -d: -f1)
        local name=$(echo "$check" | cut -d: -f2)
        local expected=$(echo "$check" | cut -d: -f3)
        local current=$(sysctl -n "$param" 2>/dev/null)
        if [[ "$current" == "$expected" ]]; then
            echo -e "  ${GREEN}[+]${NC} $name ($param = $current)"
        else
            echo -e "  ${YELLOW}[!]${NC} $name ($param = $current, expected $expected)"
        fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
