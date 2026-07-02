#!/bin/bash
# Tool: CLN-003 — Docker Cleanup
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="CLN-003"
TOOL_NAME="Docker Cleanup"
TOOL_CATEGORY="CLN"
TOOL_DESC="Run docker system prune"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Run docker system prune (remove unused containers, images, volumes)?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if ! command -v docker &>/dev/null; then
        echo -e "  ${YELLOW}[!] Docker not installed${NC}"
        exit 1
    fi
    if ! docker info &>/dev/null; then
        echo -e "  ${RED}[!!] Docker daemon not running or permission denied${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}[+] Docker disk usage before:${NC}"
    docker system df 2>/dev/null
    echo ""
    echo -e "  ${YELLOW}[!] Pruning Docker system...${NC}"
    docker system prune -af 2>/dev/null
    echo ""
    echo -e "  ${YELLOW}[!] Pruning volumes...${NC}"
    docker volume prune -f 2>/dev/null
    echo ""
    echo -e "  ${GREEN}[+] Docker disk usage after:${NC}"
    docker system df 2>/dev/null
    echo ""
    echo -e "  ${GREEN}[+] Docker cleanup complete${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
