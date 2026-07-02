#!/bin/bash
# Tool: OPT-002 — Kernel Parameters
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="OPT-002"
TOOL_NAME="Kernel Parameters"
TOOL_CATEGORY="OPT"
TOOL_DESC="Optimize network/sysctl settings"
TOOL_DANGER="Moderate"
TOOL_CONFIRM="Apply optimized kernel parameters?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}[+] Applying kernel performance parameters...${NC}"
    sysctl -w net.core.rmem_max=134217728
    sysctl -w net.core.wmem_max=134217728
    sysctl -w net.ipv4.tcp_rmem="4096 87380 134217728"
    sysctl -w net.ipv4.tcp_wmem="4096 65536 134217728"
    sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null
    sysctl -w net.core.default_qdisc=fq 2>/dev/null
    sysctl -w vm.dirty_ratio=10
    sysctl -w vm.dirty_background_ratio=5
    sysctl -w vm.vfs_cache_pressure=50
    sysctl -w vm.min_free_kbytes=65536
    sysctl -w kernel.numa_balancing=0 2>/dev/null
    cat > /etc/sysctl.d/99-performance.conf 2>/dev/null << 'EOF'
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 50
vm.min_free_kbytes = 65536
EOF
    echo -e "  ${GREEN}[+] Kernel parameters optimized${NC}"
    echo -e "  ${GRAY}  - TCP buffers increased for better network performance${NC}"
    echo -e "  ${GRAY}  - BBR congestion control enabled${NC}"
    echo -e "  ${GRAY}  - VM dirty ratios tuned for better I/O${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
