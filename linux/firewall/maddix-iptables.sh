#!/bin/bash
# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
# Maddix-IPTables - Advanced Firewall Manager for Linux
# Part of MaddixSuite by Mohammad Mehrani (Maddix)
# Client & Server profiles with full iptables support
# https://github.com/mohammadmehrani/MaddixSuite
# =========================================================

# set -e (removed for testability)
CYAN='\033[0;96m'; GREEN='\033[0;92m'; YELLOW='\033[0;93m'; RED='\033[0;91m'; MAGENTA='\033[0;95m'; GRAY='\033[0;90m'; RESET='\033[0m'

check_root() { [[ $EUID -eq 0 ]] || { echo -e "${RED}Root required. Use sudo.${RESET}"; exit 1; } }

show_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║        Maddix-IPTables v1.0 - Firewall Manager        ║${RESET}"
    echo -e "${CYAN}║     Created by Mohammad Mehrani (Maddix)              ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

save_rules() {
    mkdir -p /etc/iptables
    if command -v iptables-save &>/dev/null; then
        iptables-save > /etc/iptables/rules.v4 2>/dev/null
        ip6tables-save > /etc/iptables/rules.v6 2>/dev/null
        echo -e "${GREEN}Rules saved to /etc/iptables/ (persistent across reboot)${RESET}"
    fi
}

apply_client() {
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────┐${RESET}"
    echo -e "${YELLOW}│       PROFILE: DESKTOP / CLIENT              │${RESET}"
    echo -e "${YELLOW}└─────────────────────────────────────────────┘${RESET}"

    # Default policies
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT

    # Flush existing
    iptables -F; iptables -X; iptables -t nat -F; iptables -t mangle -F

    # Loopback
    iptables -A INPUT -i lo -j ACCEPT

    # Established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    # SSH (client outbound only - no incoming)
    iptables -A OUTPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT

    # HTTP/HTTPS
    iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -m state --state NEW -j ACCEPT

    # DNS
    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

    # DHCP
    iptables -A OUTPUT -p udp --dport 67:68 -j ACCEPT

    # ICMP (ping)
    iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
    iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

    # NTP (time sync)
    iptables -A OUTPUT -p udp --dport 123 -j ACCEPT

    # Git, APIs (9418)
    iptables -A OUTPUT -p tcp --dport 9418 -j ACCEPT

    # Log dropped
    iptables -A INPUT -j LOG --log-prefix "IPT-DROP: " --log-level 4

    save_rules
    echo -e "${GREEN}✓ Client firewall applied${RESET}"
}

apply_server() {
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────┐${RESET}"
    echo -e "${YELLOW}│       PROFILE: SERVER (HARDENED)             │${RESET}"
    echo -e "${YELLOW}└─────────────────────────────────────────────┘${RESET}"

    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    iptables -F; iptables -X; iptables -t nat -F; iptables -t mangle -F

    # Loopback
    iptables -A INPUT -i lo -j ACCEPT

    # Established
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    # SSH (custom port or 22)
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 5 --name SSH -j DROP
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT

    # Web server
    iptables -A INPUT -p tcp -m multiport --dports 80,443 -m state --state NEW -j ACCEPT

    # Mail (if needed)
    # iptables -A INPUT -p tcp -m multiport --dports 25,587,993 -m state --state NEW -j ACCEPT

    # DNS (if DNS server)
    # iptables -A INPUT -p udp --dport 53 -j ACCEPT

    # ICMP
    iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
    iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

    # NTP
    iptables -A OUTPUT -p udp --dport 123 -j ACCEPT

    # Docker bridge
    iptables -A INPUT -i docker0 -j ACCEPT 2>/dev/null || true

    # Syn flood protection
    iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
    iptables -A INPUT -p tcp --syn -j DROP

    # Port scan protection
    iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
    iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

    # Log dropped
    iptables -A INPUT -j LOG --log-prefix "IPT-DROP: " --log-level 4

    save_rules
    echo -e "${GREEN}✓ Server firewall (hardened) applied${RESET}"
}

apply_minimal() {
    echo -e "\n${YELLOW}── PROFILE: MINIMAL (allow all, block incoming) ──${RESET}"
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    iptables -F; iptables -X
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
    save_rules
    echo -e "${GREEN}✓ Minimal firewall applied${RESET}"
}

flush_all() {
    echo -e "\n${YELLOW}── FLUSHING ALL RULES (allow all) ──${RESET}"
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F; iptables -X; iptables -t nat -F; iptables -t mangle -F
    echo -e "${RED}All rules flushed. Firewall disabled.${RESET}"
}

show_status() {
    echo -e "\n${YELLOW}── CURRENT IPTABLES STATUS ──${RESET}"
    echo -e "\n${GRAY}Filter table:${RESET}"
    iptables -L -v -n --line-numbers
    echo -e "\n${GRAY}NAT table:${RESET}"
    iptables -t nat -L -v -n
    echo -e "\n${GRAY}Counters:${RESET}"
    iptables -L -v -n | grep -E "pkts|Chain" | head -20
}

custom_port() {
    read -p "Port number: " port
    read -p "Protocol (tcp/udp): " proto
    read -p "Action (ACCEPT/DROP): " action
    read -p "Direction (in/out): " dir
    if [[ "$dir" == "in" ]]; then
        iptables -A INPUT -p $proto --dport $port -j $action
    else
        iptables -A OUTPUT -p $proto --dport $port -j $action
    fi
    save_rules
    echo -e "${GREEN}Rule added${RESET}"
}

block_ip() {
    read -p "IP to block: " ip
    iptables -A INPUT -s $ip -j DROP
    iptables -A OUTPUT -d $ip -j DROP
    save_rules
    echo -e "${RED}$ip blocked${RESET}"
}

limit_rate() {
    read -p "Port: " port
    read -p "Max connections/sec: " rate
    iptables -A INPUT -p tcp --dport $port -m limit --limit ${rate}/s -j ACCEPT
    iptables -A INPUT -p tcp --dport $port -j DROP
    save_rules
    echo -e "${GREEN}Rate limit set on port $port: $rate/s${RESET}"
}

nat_setup() {
    echo -e "\n${YELLOW}── NAT / PORT FORWARDING ──${RESET}"
    read -p "External port: " ext_port
    read -p "Internal IP: " int_ip
    read -p "Internal port: " int_port
    read -p "Protocol (tcp/udp): " proto
    iptables -t nat -A PREROUTING -p $proto --dport $ext_port -j DNAT --to-destination ${int_ip}:${int_port}
    iptables -A FORWARD -p $proto -d $int_ip --dport $int_port -j ACCEPT
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/99-iptables.conf 2>/dev/null || true
    save_rules
    echo -e "${GREEN}NAT rule: port $ext_port → $int_ip:$int_port${RESET}"
}

show_menu() {
    show_banner
    echo -e " ${MAGENTA}── PROFILES ──${RESET}"
    echo "   1.  Apply Client/Desktop (safe defaults)"
    echo "   2.  Apply Server (hardened + SSH brute-force)"
    echo "   3.  Apply Minimal (block all incoming)"
    echo "   4.  Flush All (disable firewall)"
    echo ""
    echo -e " ${MAGENTA}── MANUAL RULES ──${RESET}"
    echo "   5.  Add Custom Port Rule"
    echo "   6.  Block IP Address"
    echo "   7.  Set Rate Limit on Port"
    echo "   8.  NAT / Port Forwarding"
    echo ""
    echo -e " ${MAGENTA}── STATUS ──${RESET}"
    echo "   9.  Show Current Rules & Counters"
    echo "   0.  Exit"
    echo ""
}

main() {
    check_root
    while true; do
        show_menu
        read -p "Select (0-9): " c
        case "$c" in
            1) apply_client ;;
            2) apply_server ;;
            3) apply_minimal ;;
            4) flush_all ;;
            5) custom_port ;;
            6) block_ip ;;
            7) limit_rate ;;
            8) nat_setup ;;
            9) show_status ;;
            0) echo -e "${CYAN}Goodbye!${RESET}"; exit 0 ;;
            *) echo -e "${RED}Invalid${RESET}" ;;
        esac
        read -p "Press Enter..."
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

