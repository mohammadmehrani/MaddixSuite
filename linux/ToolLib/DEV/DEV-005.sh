#!/bin/bash
# Tool: DEV-005 — Git Setup
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="DEV-005"
TOOL_NAME="Git Setup"
TOOL_CATEGORY="DEV"
TOOL_DESC="Install and configure git"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if ! command -v git &>/dev/null; then
        if [[ "$EUID" -ne 0 ]]; then
            echo -e "  ${RED}[!!] Root required to install git${NC}"
            exit 1
        fi
        echo -e "  ${GREEN}[+] Installing git...${NC}"
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            case "$ID" in
                debian|ubuntu|mint|kali) apt-get install -y git ;;
                fedora|rhel|centos|rocky|alma) dnf install -y git ;;
                arch|manjaro) pacman -S --noconfirm git ;;
                opensuse|suse) zypper install -y git ;;
            esac
        fi
    fi
    if command -v git &>/dev/null; then
        echo -e "  ${GREEN}[+] Git: $(git --version)${NC}"
        local name=$(git config --global user.name 2>/dev/null)
        local email=$(git config --global user.email 2>/dev/null)
        if [[ -z "$name" ]]; then
            echo -en "  ${GRAY}Git user name: ${NC}"; read -r gname
            if [[ -n "$gname" ]]; then
                git config --global user.name "$gname"
                echo -e "  ${GREEN}[+] Git user name set to: $gname${NC}"
            fi
        else
            echo -e "  ${GRAY}Git user name:${NC} $name"
        fi
        if [[ -z "$email" ]]; then
            echo -en "  ${GRAY}Git email: ${NC}"; read -r gemail
            if [[ -n "$gemail" ]]; then
                git config --global user.email "$gemail"
                echo -e "  ${GREEN}[+] Git email set to: $gemail${NC}"
            fi
        else
            echo -e "  ${GRAY}Git email:${NC} $email"
        fi
        git config --global init.defaultBranch main 2>/dev/null
        git config --global color.ui auto
        echo -e "  ${GREEN}[+] Git configured${NC}"
        echo -e "  ${GRAY}  Config: ~/.gitconfig${NC}"
    else
        echo -e "  ${RED}[!!] Git installation failed${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
