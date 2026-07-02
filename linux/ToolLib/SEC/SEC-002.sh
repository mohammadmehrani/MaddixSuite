#!/bin/bash
# Tool: SEC-002 — SSH Hardening
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SEC-002"
TOOL_NAME="SSH Hardening"
TOOL_CATEGORY="SEC"
TOOL_DESC="Disable root login, key-only auth"
TOOL_DANGER="High"
TOOL_CONFIRM="Disable root login and password authentication for SSH?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    if [[ ! -f /etc/ssh/sshd_config ]]; then
        echo -e "  ${RED}[!!] SSH config not found at /etc/ssh/sshd_config${NC}"
        exit 1
    fi
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)
    echo -e "  ${GREEN}[+] Backup created${NC}"
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
    sed -i 's/^#\?ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
    sed -i 's/^#\?ClientAliveCountMax.*/ClientAliveCountMax 2/' /etc/ssh/sshd_config
    echo -e "  ${GREEN}[+] SSH hardened${NC}"
    echo -e "  ${YELLOW}[!] Verifying config...${NC}"
    sshd -t && echo -e "  ${GREEN}[+] Config syntax OK${NC}" || echo -e "  ${RED}[!!] Config syntax error${NC}"
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    echo -e "  ${GREEN}[+] SSH service restarted${NC}"
    echo -e "  ${YELLOW}[!] Make sure you have key-based access before closing this session!${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
