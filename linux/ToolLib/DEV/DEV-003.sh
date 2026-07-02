#!/bin/bash
# Tool: DEV-003 — Node.js Setup
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="DEV-003"
TOOL_NAME="Node.js Setup"
TOOL_CATEGORY="DEV"
TOOL_DESC="Install Node.js via nvm"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Install Node.js via nvm?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if command -v node &>/dev/null; then
        echo -e "  ${GREEN}[+] Node.js already installed: $(node --version)${NC}"
        echo -e "  ${GREEN}[+] npm: $(npm --version)${NC}"
        return
    fi
    echo -e "  ${GREEN}[+] Installing nvm (Node Version Manager)...${NC}"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        . "$NVM_DIR/nvm.sh"
        echo -e "  ${GREEN}[+] Installing latest LTS Node.js...${NC}"
        nvm install --lts
        nvm use --lts
        if command -v node &>/dev/null; then
            echo -e "  ${GREEN}[+] Node.js installed: $(node --version)${NC}"
            echo -e "  ${GREEN}[+] npm: $(npm --version)${NC}"
            echo -e "  ${YELLOW}[!] Restart shell or run: source ~/.bashrc${NC}"
        else
            echo -e "  ${RED}[!!] Node.js installation failed${NC}"
        fi
    else
        echo -e "  ${RED}[!!] nvm installation failed${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
