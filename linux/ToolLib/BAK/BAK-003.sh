#!/bin/bash
# Tool: BAK-003 — Database Backup
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="BAK-003"
TOOL_NAME="Database Backup"
TOOL_CATEGORY="BAK"
TOOL_DESC="MySQL/PostgreSQL dump"
TOOL_DANGER="Safe"
TOOL_CONFIRM=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    local backup_dir="$HOME/MaddixSuite/Backups"
    mkdir -p "$backup_dir"
    local ts=$(date +%Y%m%d_%H%M%S)
    echo -e "  ${CYAN}Database Backup${NC}"
    if command -v mysqldump &>/dev/null; then
        echo -e "  ${GRAY}MySQL dump${NC}"
        echo -en "  ${GRAY}MySQL user (root): ${NC}"; read -r mu
        mu=${mu:-root}
        echo -en "  ${GRAY}MySQL password: ${NC}"; read -rs mp; echo
        mysqldump -u"$mu" -p"$mp" --all-databases --routines --events 2>/dev/null | gzip > "$backup_dir/mysql_$ts.sql.gz"
        if [[ -f "$backup_dir/mysql_$ts.sql.gz" && -s "$backup_dir/mysql_$ts.sql.gz" ]]; then
            echo -e "  ${GREEN}[+] MySQL backup: $backup_dir/mysql_$ts.sql.gz ($(du -h "$backup_dir/mysql_$ts.sql.gz" | cut -f1))${NC}"
        else
            echo -e "  ${RED}[!!] MySQL backup failed${NC}"
        fi
    else
        echo -e "  ${YELLOW}[!] mysqldump not found${NC}"
    fi
    if command -v pg_dumpall &>/dev/null; then
        echo -e "  ${GRAY}PostgreSQL dump${NC}"
        echo -en "  ${GRAY}PostgreSQL user (postgres): ${NC}"; read -r pu
        pu=${pu:-postgres}
        pg_dumpall -U "$pu" 2>/dev/null | gzip > "$backup_dir/postgres_$ts.psql.gz"
        if [[ -f "$backup_dir/postgres_$ts.psql.gz" && -s "$backup_dir/postgres_$ts.psql.gz" ]]; then
            echo -e "  ${GREEN}[+] PostgreSQL backup: $backup_dir/postgres_$ts.psql.gz ($(du -h "$backup_dir/postgres_$ts.psql.gz" | cut -f1))${NC}"
        else
            echo -e "  ${RED}[!!] PostgreSQL backup failed${NC}"
        fi
    else
        echo -e "  ${YELLOW}[!] pg_dumpall not found${NC}"
    fi
    echo -e "  ${GREEN}[+] Database backup complete${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
