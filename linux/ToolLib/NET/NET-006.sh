#!/bin/bash
# Tool: NET-006 — Speed Test
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="NET-006"
TOOL_NAME="Speed Test"
TOOL_CATEGORY="NET"
TOOL_DESC="Test internet speed via speedtest-cli"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}Internet Speed Test${NC}"
    if command -v speedtest-cli &>/dev/null; then
        echo -e "  ${GRAY}Running speed test...${NC}"
        speedtest-cli 2>/dev/null
    elif command -v speedtest &>/dev/null; then
        echo -e "  ${GRAY}Running speed test (ookla)...${NC}"
        speedtest 2>/dev/null
    elif command -v python3 &>/dev/null; then
        echo -e "  ${GRAY}Downloading speedtest-cli...${NC}"
        python3 -c "
import urllib.request, json
try:
    url = 'https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py'
    exec(urllib.request.urlopen(url).read())
except:
    print('Speed test failed')
" 2>/dev/null || echo -e "  ${RED}[!!] Speed test failed${NC}"
    else
        echo -e "  ${YELLOW}[!] Install speedtest-cli for bandwidth testing${NC}"
        echo -e "  ${GRAY}  pip install speedtest-cli${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
