#!/bin/bash
# Tool: NET-003 — DNS Config
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="NET-003"
TOOL_NAME="DNS Config"
TOOL_CATEGORY="NET"
TOOL_DESC="View/test DNS resolution, change DNS servers"
TOOL_DANGER="Moderate"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${CYAN}DNS Configuration${NC}"
    echo -e "  ${GRAY}Current DNS:${NC}"
    cat /etc/resolv.conf 2>/dev/null
    echo ""
    echo -e "  ${GRAY}1) Test DNS resolution (google.com)${NC}"
    echo -e "  ${GRAY}2) Set DNS to Cloudflare (1.1.1.1)${NC}"
    echo -e "  ${GRAY}3) Set DNS to Google (8.8.8.8)${NC}"
    echo -e "  ${GRAY}4) Flush DNS cache${NC}"
    echo -e "  ${GRAY}0) Back${NC}"
    echo -en "  ${CYAN}Select: ${NC}"; read -r sc
    case "$sc" in
        1)
            echo -e "  ${GRAY}Testing DNS resolution...${NC}"
            nslookup google.com 2>/dev/null && echo -e "  ${GREEN}[+] DNS resolution OK${NC}" || echo -e "  ${RED}[!!] DNS resolution failed${NC}"
            ;;
        2)
            echo "nameserver 1.1.1.1" > /etc/resolv.conf
            echo "nameserver 1.0.0.1" >> /etc/resolv.conf
            echo -e "  ${GREEN}[+] DNS set to Cloudflare (1.1.1.1)${NC}"
            ;;
        3)
            echo "nameserver 8.8.8.8" > /etc/resolv.conf
            echo "nameserver 8.8.4.4" >> /etc/resolv.conf
            echo -e "  ${GREEN}[+] DNS set to Google (8.8.8.8)${NC}"
            ;;
        4)
            if command -v systemd-resolve &>/dev/null; then
                systemd-resolve --flush-caches && echo -e "  ${GREEN}[+] DNS cache flushed${NC}"
            elif command -v resolvectl &>/dev/null; then
                resolvectl flush-caches && echo -e "  ${GREEN}[+] DNS cache flushed${NC}"
            else
                echo -e "  ${YELLOW}[!] No DNS cache tool found${NC}"
            fi
            ;;
        0) return ;;
        *) echo -e "  ${YELLOW}[!] Invalid option${NC}" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
