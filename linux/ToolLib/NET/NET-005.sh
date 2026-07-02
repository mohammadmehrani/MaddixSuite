#!/bin/bash
# Tool: NET-005 — WiFi Manager
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="NET-005"
TOOL_NAME="WiFi Manager"
TOOL_CATEGORY="NET"
TOOL_DESC="Scan/list/connect WiFi via nmcli"
TOOL_DANGER="Moderate"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if ! command -v nmcli &>/dev/null; then
        echo -e "  ${YELLOW}[!] nmcli not available. Install NetworkManager.${NC}"
        exit 1
    fi
    echo -e "  ${CYAN}WiFi Manager${NC}"
    echo -e "  ${GRAY}1) Scan WiFi networks${NC}"
    echo -e "  ${GRAY}2) List saved connections${NC}"
    echo -e "  ${GRAY}3) Connect to WiFi${NC}"
    echo -e "  ${GRAY}4) Show current connection${NC}"
    echo -e "  ${GRAY}5) Turn WiFi on/off${NC}"
    echo -e "  ${GRAY}0) Back${NC}"
    echo -en "  ${CYAN}Select: ${NC}"; read -r sc
    case "$sc" in
        1)
            echo -e "  ${GRAY}Scanning...${NC}"
            nmcli device wifi list 2>/dev/null | head -30
            ;;
        2)
            nmcli connection show 2>/dev/null
            ;;
        3)
            echo -en "  ${GRAY}SSID: ${NC}"; read -r ssid
            if [[ -n "$ssid" ]]; then
                echo -en "  ${GRAY}Password: ${NC}"; read -rs pass; echo
                nmcli device wifi connect "$ssid" password "$pass" 2>/dev/null && echo -e "  ${GREEN}[+] Connected to $ssid${NC}" || echo -e "  ${RED}[!!] Connection failed${NC}"
            fi
            ;;
        4)
            nmcli connection show --active 2>/dev/null
            ;;
        5)
            echo -e "  ${GRAY}1) Enable WiFi${NC}"
            echo -e "  ${GRAY}2) Disable WiFi${NC}"
            echo -en "  ${CYAN}Select: ${NC}"; read -r wc
            case "$wc" in
                1) nmcli radio wifi on && echo -e "  ${GREEN}[+] WiFi enabled${NC}" ;;
                2) nmcli radio wifi off && echo -e "  ${YELLOW}[!] WiFi disabled${NC}" ;;
            esac
            ;;
        0) return ;;
        *) echo -e "  ${YELLOW}[!] Invalid option${NC}" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
