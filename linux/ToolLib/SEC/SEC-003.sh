#!/bin/bash
# Tool: SEC-003 — Firewall Setup
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SEC-003"
TOOL_NAME="Firewall Setup"
TOOL_CATEGORY="SEC"
TOOL_DESC="Configure default-deny firewall rules"
TOOL_DANGER="High"
TOOL_CONFIRM="Apply default-deny firewall rules?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    if command -v ufw &>/dev/null; then
        echo -e "  ${GREEN}[+] Configuring UFW...${NC}"
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ssh
        ufw allow http
        ufw allow https
        echo -en "  ${GRAY}Additional port to allow (e.g., 443, 8080): ${NC}"; read -r p
        if [[ -n "$p" ]]; then
            for port in $p; do
                ufw allow "$port" && echo -e "  ${GREEN}[+] Port $port allowed${NC}"
            done
        fi
        ufw --force enable
        ufw status verbose
        echo -e "  ${GREEN}[+] UFW configured with default-deny policy${NC}"
    elif command -v iptables &>/dev/null; then
        echo -e "  ${GREEN}[+] Configuring iptables...${NC}"
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT
        iptables -A INPUT -i lo -j ACCEPT
        iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        iptables -A INPUT -p tcp --dport 22 -j ACCEPT
        iptables -A INPUT -p tcp --dport 80 -j ACCEPT
        iptables -A INPUT -p tcp --dport 443 -j ACCEPT
        iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
        echo -e "  ${GREEN}[+] iptables default-deny rules applied${NC}"
        if command -v iptables-save &>/dev/null; then
            mkdir -p /etc/iptables
            iptables-save > /etc/iptables/rules.v4 2>/dev/null && echo -e "  ${GREEN}[+] Rules saved to /etc/iptables/rules.v4${NC}"
        fi
    else
        echo -e "  ${YELLOW}[!] Install ufw or iptables first${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
