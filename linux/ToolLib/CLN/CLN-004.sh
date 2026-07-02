#!/bin/bash
# Tool: CLN-004 — Cache Cleaner
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="CLN-004"
TOOL_NAME="Cache Cleaner"
TOOL_CATEGORY="CLN"
TOOL_DESC="Clear .cache, /tmp, /var/tmp"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Clear .cache, /tmp, and /var/tmp?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}Cache Cleaner${NC}"
    echo -e "  ${GREEN}[+] Cleaning user cache...${NC}"
    rm -rf ~/.cache/* 2>/dev/null && echo -e "  ${GREEN}  [+] ~/.cache cleared${NC}" || echo -e "  ${YELLOW}  [!] No ~/.cache found${NC}"
    echo -e "  ${GREEN}[+] Cleaning system cache...${NC}"
    if [[ "$EUID" -eq 0 ]]; then
        rm -rf /var/cache/* 2>/dev/null && echo -e "  ${GREEN}  [+] /var/cache cleared${NC}"
    else
        echo -e "  ${YELLOW}  [!] Skip /var/cache (need root)${NC}"
    fi
    echo -e "  ${GREEN}[+] Cleaning temp directories...${NC}"
    if [[ "$EUID" -eq 0 ]]; then
        rm -rf /tmp/* 2>/dev/null && echo -e "  ${GREEN}  [+] /tmp cleared${NC}"
        rm -rf /var/tmp/* 2>/dev/null && echo -e "  ${GREEN}  [+] /var/tmp cleared${NC}"
    else
        echo -e "  ${YELLOW}  [!] Skip /tmp and /var/tmp (need root)${NC}"
    fi
    echo -e "  ${GREEN}[+] Cleaning thumbnail cache...${NC}"
    rm -rf ~/.thumbnails/* 2>/dev/null || true
    rm -rf ~/.cache/thumbnails/* 2>/dev/null || true
    echo -e "  ${GREEN}[+] Cache cleanup complete${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
