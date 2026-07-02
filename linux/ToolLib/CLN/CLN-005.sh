#!/bin/bash
# Tool: CLN-005 — Old Kernel Remover
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="CLN-005"
TOOL_NAME="Old Kernel Remover"
TOOL_CATEGORY="CLN"
TOOL_DESC="Remove old kernel packages"
TOOL_DANGER="High"
TOOL_CONFIRM="Remove old kernel packages (keep current)?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    local current_kernel=$(uname -r)
    echo -e "  ${GRAY}Current kernel:${NC} $current_kernel"
    echo ""
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu|mint|kali)
                echo -e "  ${GRAY}Installed kernels:${NC}"
                dpkg --list | grep -E 'linux-image|linux-headers' | awk '{print $2}' | sed 's/^/  /'
                echo ""
                echo -e "  ${YELLOW}[!] Removing old kernels...${NC}"
                apt-get autoremove --purge -y
                echo -e "  ${GREEN}[+] Old kernels removed${NC}"
                ;;
            fedora|rhel|centos|rocky|alma)
                echo -e "  ${GRAY}Installed kernels:${NC}"
                rpm -qa kernel | sed 's/^/  /'
                echo ""
                local old_kernels=$(rpm -qa kernel | grep -v "$(uname -r)" | grep -v "$(rpm -q kernel | tail -1)" 2>/dev/null)
                if [[ -n "$old_kernels" ]]; then
                    echo -e "  ${YELLOW}[!] Removing old kernels...${NC}"
                    dnf remove -y $old_kernels 2>/dev/null
                    echo -e "  ${GREEN}[+] Old kernels removed${NC}"
                else
                    echo -e "  ${GREEN}[+] No old kernels to remove${NC}"
                fi
                ;;
            arch|manjaro)
                echo -e "  ${GRAY}Installed kernels:${NC}"
                pacman -Q linux linux-lts 2>/dev/null | sed 's/^/  /'
                echo ""
                echo -e "  ${YELLOW}[!] Use 'pacman -Rns' to remove old kernels manually${NC}"
                ;;
            *)
                echo -e "  ${YELLOW}[!] Automatic kernel removal not supported for $ID${NC}"
                ;;
        esac
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
