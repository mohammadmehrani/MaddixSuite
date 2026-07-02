#!/bin/bash
# Tool: NET-002 — Firewall Manager
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="NET-002"
TOOL_NAME="Firewall Manager"
TOOL_CATEGORY="NET"
TOOL_DESC="Configure ufw/iptables rules"
TOOL_DANGER="High"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${CYAN}Firewall Manager${NC}"
    if command -v ufw &>/dev/null; then
        echo -e "  ${GRAY}UFW Status:${NC}"
        ufw status verbose
        echo ""
        echo -e "  ${GRAY}1) Enable UFW${NC}"
        echo -e "  ${GRAY}2) Disable UFW${NC}"
        echo -e "  ${GRAY}3) Allow port${NC}"
        echo -e "  ${GRAY}4) Deny port${NC}"
        echo -e "  ${GRAY}5) Reset UFW${NC}"
        echo -e "  ${GRAY}0) Back${NC}"
        echo -en "  ${CYAN}Select: ${NC}"; read -r sc
        case "$sc" in
            1) ufw --force enable && echo -e "  ${GREEN}[+] UFW enabled${NC}" ;;
            2) ufw disable && echo -e "  ${YELLOW}[!] UFW disabled${NC}" ;;
            3) echo -en "  ${GRAY}Port: ${NC}"; read -r p; [[ -n "$p" ]] && ufw allow "$p" && echo -e "  ${GREEN}[+] Port $p allowed${NC}" ;;
            4) echo -en "  ${GRAY}Port: ${NC}"; read -r p; [[ -n "$p" ]] && ufw deny "$p" && echo -e "  ${GREEN}[+] Port $p denied${NC}" ;;
            5) ufw --force reset && echo -e "  ${YELLOW}[!] UFW reset${NC}" ;;
        esac
    elif command -v iptables &>/dev/null; then
        echo -e "  ${GRAY}Current iptables rules:${NC}"
        iptables -L -n --line-numbers 2>/dev/null | head -30
        echo ""
        echo -e "  ${GRAY}1) Apply default deny incoming${NC}"
        echo -e "  ${GRAY}2) Flush all rules${NC}"
        echo -e "  ${GRAY}3) Allow SSH (port 22)${NC}"
        echo -e "  ${GRAY}0) Back${NC}"
        echo -en "  ${CYAN}Select: ${NC}"; read -r sc
        case "$sc" in
            1)
                iptables -P INPUT DROP
                iptables -P FORWARD DROP
                iptables -P OUTPUT ACCEPT
                iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
                iptables -A INPUT -i lo -j ACCEPT
                echo -e "  ${GREEN}[+] Default deny rules applied${NC}"
                ;;
            2) iptables -F && echo -e "  ${YELLOW}[!] All rules flushed${NC}" ;;
            3) iptables -A INPUT -p tcp --dport 22 -j ACCEPT && echo -e "  ${GREEN}[+] SSH allowed${NC}" ;;
        esac
    else
        echo -e "  ${YELLOW}[!] No firewall found. Install ufw or iptables.${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
