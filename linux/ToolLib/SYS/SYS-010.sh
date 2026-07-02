#!/bin/bash
# Tool: SYS-010 — User Manager
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SYS-010"
TOOL_NAME="User Manager"
TOOL_CATEGORY="SYS"
TOOL_DESC="List users, add/delete users, change passwords"
TOOL_DANGER="High"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${CYAN}User Manager${NC}"
    echo -e "  ${GRAY}1) List all users${NC}"
    echo -e "  ${GRAY}2) Add a new user${NC}"
    echo -e "  ${GRAY}3) Delete a user${NC}"
    echo -e "  ${GRAY}4) Change user password${NC}"
    echo -e "  ${GRAY}5) List sudo users${NC}"
    echo -e "  ${GRAY}0) Back${NC}"
    echo -en "  ${CYAN}Select: ${NC}"; read -r sc
    case "$sc" in
        1)
            echo -e "  ${GRAY}System users:${NC}"
            awk -F: '{print "  " $1 " (UID: " $3 ", GID: " $4 ", Shell: " $7 ")"}' /etc/passwd
            ;;
        2)
            echo -en "  ${GRAY}Username: ${NC}"; read -r uname
            if [[ -n "$uname" ]]; then
                useradd -m -s /bin/bash "$uname" && echo -e "  ${GREEN}[+] User $uname created${NC}" || echo -e "  ${RED}[!!] Failed to create user${NC}"
                passwd "$uname"
            fi
            ;;
        3)
            echo -en "  ${GRAY}Username: ${NC}"; read -r uname
            if [[ -n "$uname" ]]; then
                userdel -r "$uname" && echo -e "  ${GREEN}[+] User $uname deleted${NC}" || echo -e "  ${RED}[!!] Failed to delete user${NC}"
            fi
            ;;
        4)
            echo -en "  ${GRAY}Username: ${NC}"; read -r uname
            if [[ -n "$uname" ]]; then
                passwd "$uname"
            fi
            ;;
        5)
            echo -e "  ${GRAY}Sudo group members:${NC}"
            grep -Po '^sudo:.*$' /etc/group | cut -d: -f4 | tr ',' '\n' | sed 's/^/  /'
            echo -e "  ${GRAY}Wheel group members:${NC}"
            grep -Po '^wheel:.*$' /etc/group | cut -d: -f4 | tr ',' '\n' | sed 's/^/  /'
            ;;
        0) return ;;
        *) echo -e "  ${YELLOW}[!] Invalid option${NC}" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
