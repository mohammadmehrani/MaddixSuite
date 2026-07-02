#!/bin/bash
# Tool: SRV-006 — Monitoring Setup
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SRV-006"
TOOL_NAME="Monitoring Setup"
TOOL_CATEGORY="SRV"
TOOL_DESC="Install netdata or prometheus"
TOOL_DANGER="Moderate"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${CYAN}Monitoring Setup${NC}"
    echo -e "  ${GRAY}1) Install Netdata (lightweight, web dashboard)${NC}"
    echo -e "  ${GRAY}2) Install Prometheus + Node Exporter${NC}"
    echo -e "  ${GRAY}0) Back${NC}"
    echo -en "  ${CYAN}Select: ${NC}"; read -r sc
    case "$sc" in
        1)
            echo -e "  ${GREEN}[+] Installing Netdata...${NC}"
            bash <(curl -Ss https://my-netdata.io/kickstart.sh) 2>/dev/null || {
                if [[ -f /etc/os-release ]]; then
                    . /etc/os-release
                    case "$ID" in
                        debian|ubuntu|mint|kali)
                            apt-get install -y netdata
                            ;;
                        fedora|rhel|centos|rocky|alma)
                            dnf install -y netdata
                            ;;
                    esac
                fi
            }
            if command -v netdata &>/dev/null; then
                systemctl enable --now netdata 2>/dev/null
                echo -e "  ${GREEN}[+] Netdata installed${NC}"
                echo -e "  ${GRAY}  Dashboard: http://localhost:19999${NC}"
            fi
            ;;
        2)
            echo -e "  ${GREEN}[+] Installing Prometheus Node Exporter...${NC}"
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                case "$ID" in
                    debian|ubuntu|mint|kali) apt-get install -y prometheus-node-exporter ;;
                    fedora|rhel|centos|rocky|alma) dnf install -y prometheus-node-exporter ;;
                esac
            fi
            systemctl enable --now prometheus-node-exporter 2>/dev/null
            echo -e "  ${GREEN}[+] Prometheus Node Exporter installed${NC}"
            echo -e "  ${GRAY}  Metrics: http://localhost:9100/metrics${NC}"
            echo -e "  ${YELLOW}[!] For full Prometheus: visit prometheus.io/download${NC}"
            ;;
        0) return ;;
        *) echo -e "  ${YELLOW}[!] Invalid option${NC}" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
