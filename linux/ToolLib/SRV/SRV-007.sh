#!/bin/bash
# Tool: SRV-007 — Backup Server
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SRV-007"
TOOL_NAME="Backup Server"
TOOL_CATEGORY="SRV"
TOOL_DESC="Install borg/restic backup tools"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Install backup tools (borg/restic)?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${CYAN}Backup Server Tools${NC}"
    echo -e "  ${GRAY}1) Install BorgBackup${NC}"
    echo -e "  ${GRAY}2) Install Restic${NC}"
    echo -e "  ${GRAY}3) Install both${NC}"
    echo -e "  ${GRAY}0) Back${NC}"
    echo -en "  ${CYAN}Select: ${NC}"; read -r sc
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$sc" in
            1|3)
                echo -e "  ${GREEN}[+] Installing BorgBackup...${NC}"
                case "$ID" in
                    debian|ubuntu|mint|kali) apt-get install -y borgbackup ;;
                    fedora|rhel|centos|rocky|alma) dnf install -y borgbackup ;;
                    arch|manjaro) pacman -S --noconfirm borg ;;
                    opensuse|suse) zypper install -y borgbackup ;;
                esac
                if command -v borg &>/dev/null; then
                    echo -e "  ${GREEN}[+] BorgBackup: $(borg --version 2>/dev/null)${NC}"
                    echo -e "  ${GRAY}  Usage: borg init /path/to/repo${NC}"
                fi
                ;;
        esac
        case "$sc" in
            2|3)
                echo -e "  ${GREEN}[+] Installing Restic...${NC}"
                case "$ID" in
                    debian|ubuntu|mint|kali) apt-get install -y restic ;;
                    fedora|rhel|centos|rocky|alma) dnf install -y restic ;;
                    arch|manjaro) pacman -S --noconfirm restic ;;
                    opensuse|suse) zypper install -y restic ;;
                esac
                if command -v restic &>/dev/null; then
                    echo -e "  ${GREEN}[+] Restic: $(restic version 2>/dev/null)${NC}"
                    echo -e "  ${GRAY}  Usage: restic init --repo /path/to/repo${NC}"
                fi
                ;;
            0) return ;;
            *) echo -e "  ${YELLOW}[!] Invalid option${NC}" ;;
        esac
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
