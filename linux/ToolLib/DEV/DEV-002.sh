#!/bin/bash
# Tool: DEV-002 — Fish Shell Install
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="DEV-002"
TOOL_NAME="Fish Shell Install"
TOOL_CATEGORY="DEV"
TOOL_DESC="Install modern fish shell"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Install Fish Shell?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if command -v fish &>/dev/null; then
        echo -e "  ${GREEN}[+] Fish Shell already installed: $(fish --version 2>/dev/null)${NC}"
        return
    fi
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}[+] Installing Fish Shell...${NC}"
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu|mint|kali)
                echo 'deb https://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_12/ /' | tee /etc/apt/sources.list.d/fish.list
                curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_12/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/fish.gpg >/dev/null
                apt-get update && apt-get install -y fish
                ;;
            fedora|rhel|centos|rocky|alma)
                dnf install -y fish
                ;;
            arch|manjaro)
                pacman -S --noconfirm fish
                ;;
            opensuse|suse)
                zypper install -y fish
                ;;
            *)
                echo -e "  ${YELLOW}[!] Unsupported distro. Install fish manually.${NC}"
                return
                ;;
        esac
    fi
    if command -v fish &>/dev/null; then
        echo -e "  ${GREEN}[+] Fish Shell installed: $(fish --version)${NC}"
        echo -e "  ${GRAY}  Run 'fish' to start, 'fish_config' for web config${NC}"
    else
        echo -e "  ${RED}[!!] Fish Shell installation failed${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
