#!/bin/bash
# Tool: BAK-004 — Remote Upload
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="BAK-004"
TOOL_NAME="Remote Upload"
TOOL_CATEGORY="BAK"
TOOL_DESC="Upload backup via curl/ftp"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    echo -e "  ${CYAN}Remote Upload${NC}"
    echo -en "  ${GRAY}Source file path: ${NC}"; read -r src
    if [[ ! -f "$src" ]]; then
        echo -e "  ${RED}[!!] File not found: $src${NC}"
        exit 1
    fi
    local fsize=$(du -h "$src" | cut -f1)
    echo -e "  ${GRAY}File:${NC} $src ($fsize)"
    echo ""
    echo -e "  ${GRAY}1) FTP upload${NC}"
    echo -e "  ${GRAY}2) SCP upload${NC}"
    echo -e "  ${GRAY}3) Local copy${NC}"
    echo -e "  ${GRAY}0) Back${NC}"
    echo -en "  ${CYAN}Select: ${NC}"; read -r sc
    case "$sc" in
        1)
            echo -en "  ${GRAY}FTP server: ${NC}"; read -r srv
            echo -en "  ${GRAY}FTP user: ${NC}"; read -r user
            echo -en "  ${GRAY}FTP password: ${NC}"; read -rs pass; echo
            echo -en "  ${GRAY}Remote path: ${NC}"; read -r rpath
            if command -v curl &>/dev/null; then
                curl -T "$src" "ftp://$srv$rpath/" --user "$user:$pass" 2>/dev/null && echo -e "  ${GREEN}[+] Uploaded via FTP${NC}" || echo -e "  ${RED}[!!] FTP upload failed${NC}"
            else
                echo -e "  ${YELLOW}[!] curl not available${NC}"
            fi
            ;;
        2)
            echo -en "  ${GRAY}SCP user@host: ${NC}"; read -r dest
            echo -en "  ${GRAY}Remote path: ${NC}"; read -r rpath
            if command -v scp &>/dev/null; then
                scp "$src" "$dest:$rpath" 2>/dev/null && echo -e "  ${GREEN}[+] Uploaded via SCP${NC}" || echo -e "  ${RED}[!!] SCP failed${NC}"
            else
                echo -e "  ${YELLOW}[!] scp not available${NC}"
            fi
            ;;
        3)
            echo -en "  ${GRAY}Destination directory: ${NC}"; read -r dest
            if [[ -d "$dest" ]]; then
                cp "$src" "$dest/" && echo -e "  ${GREEN}[+] Copied to $dest${NC}" || echo -e "  ${RED}[!!] Copy failed${NC}"
            else
                echo -e "  ${RED}[!!] Destination not found${NC}"
            fi
            ;;
        0) return ;;
        *) echo -e "  ${YELLOW}[!] Invalid option${NC}" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
