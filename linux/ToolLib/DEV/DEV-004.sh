#!/bin/bash
# Tool: DEV-004 — Python Setup
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="DEV-004"
TOOL_NAME="Python Setup"
TOOL_CATEGORY="DEV"
TOOL_DESC="Install python3, pip, venv"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Install Python3, pip, and venv?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${CYAN}Python Setup${NC}"
    if command -v python3 &>/dev/null; then
        echo -e "  ${GREEN}[+] Python3: $(python3 --version 2>/dev/null)${NC}"
    else
        echo -e "  ${GREEN}[+] Installing python3...${NC}"
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            case "$ID" in
                debian|ubuntu|mint|kali) apt-get install -y python3 ;;
                fedora|rhel|centos|rocky|alma) dnf install -y python3 ;;
                arch|manjaro) pacman -S --noconfirm python ;;
                opensuse|suse) zypper install -y python3 ;;
            esac
        fi
    fi
    if command -v pip3 &>/dev/null; then
        echo -e "  ${GREEN}[+] pip3: $(pip3 --version 2>/dev/null)${NC}"
    else
        echo -e "  ${GREEN}[+] Installing pip...${NC}"
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            case "$ID" in
                debian|ubuntu|mint|kali) apt-get install -y python3-pip ;;
                fedora|rhel|centos|rocky|alma) dnf install -y python3-pip ;;
                arch|manjaro) pacman -S --noconfirm python-pip ;;
                opensuse|suse) zypper install -y python3-pip ;;
            esac
        fi
    fi
    if python3 -m venv --help &>/dev/null; then
        echo -e "  ${GREEN}[+] python3-venv available${NC}"
    else
        echo -e "  ${GREEN}[+] Installing venv...${NC}"
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            case "$ID" in
                debian|ubuntu|mint|kali) apt-get install -y python3-venv ;;
                fedora|rhel|centos|rocky|alma) dnf install -y python3-virtualenv ;;
                arch|manjaro) pacman -S --noconfirm python-virtualenv ;;
            esac
        fi
    fi
    echo -e "  ${GREEN}[+] Python setup complete${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
