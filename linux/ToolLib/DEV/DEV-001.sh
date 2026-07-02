#!/bin/bash
# Tool: DEV-001 — Docker Install
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="DEV-001"
TOOL_NAME="Docker Install"
TOOL_CATEGORY="DEV"
TOOL_DESC="Install Docker CE"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Install Docker CE?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    if command -v docker &>/dev/null; then
        echo -e "  ${GREEN}[+] Docker already installed: $(docker --version 2>/dev/null)${NC}"
        docker info --format '{{.ServerVersion}}' 2>/dev/null && echo -e "  ${GREEN}[+] Docker daemon running${NC}" || echo -e "  ${YELLOW}[!] Docker daemon not running${NC}"
        return
    fi
    echo -e "  ${GREEN}[+] Installing Docker CE...${NC}"
    curl -fsSL https://get.docker.com | sh
    if command -v docker &>/dev/null; then
        systemctl enable --now docker 2>/dev/null
        echo -e "  ${GREEN}[+] Docker installed: $(docker --version)${NC}"
        echo -e "  ${YELLOW}[!] Add users to docker group to run without sudo: usermod -aG docker \$USER${NC}"
    else
        echo -e "  ${RED}[!!] Docker installation failed${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
