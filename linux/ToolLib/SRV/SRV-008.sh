#!/bin/bash
# Tool: SRV-008 — Mail Server
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SRV-008"
TOOL_NAME="Mail Server"
TOOL_CATEGORY="SRV"
TOOL_DESC="Install postfix basic setup"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Install Postfix mail server?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}[+] Installing Postfix...${NC}"
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu|mint|kali)
                echo "postfix postfix/mailname string $(hostname -f 2>/dev/null || hostname)" | debconf-set-selections
                echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
                apt-get install -y postfix mailutils
                ;;
            fedora|rhel|centos|rocky|alma)
                dnf install -y postfix mailx
                ;;
            arch|manjaro)
                pacman -S --noconfirm postfix
                ;;
            opensuse|suse)
                zypper install -y postfix
                ;;
        esac
    fi
    if command -v postfix &>/dev/null; then
        systemctl enable --now postfix 2>/dev/null
        echo -e "  ${GREEN}[+] Postfix installed and running${NC}"
        echo -e "  ${GRAY}  Config: /etc/postfix/main.cf${NC}"
        echo -e "  ${GRAY}  Test: echo test | mail -s test root${NC}"
        postfix status 2>/dev/null
    else
        echo -e "  ${RED}[!!] Postfix installation failed${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
