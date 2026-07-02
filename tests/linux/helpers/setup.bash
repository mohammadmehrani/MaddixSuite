#!/bin/bash
# MaddixSuite BATS Test Setup
# Source this file in every .bats test file

export MADDIX_ROOT="${BATS_TEST_DIRNAME}/../../.."
export MADDIX_TEST_MODE=1
export PATH="${MADDIX_ROOT}/linux:${PATH}"

# Mock functions that override system commands
mock_command() {
    local cmd="$1"
    local output="$2"
    eval "${cmd}() { echo '${output}'; }"
    export -f "${cmd}"
}

# Reset all mocks
reset_mocks() {
    unset -f ping traceroute nslookup dig curl wget systemctl 2>/dev/null || true
}

# Sample output generators
sample_ip_addr() {
    cat <<'EOF'
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536
    inet 127.0.0.1/8 scope host lo
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    inet 192.168.1.100/24 brd 192.168.1.255 scope global eth0
EOF
}

sample_df() {
    cat <<'EOF'
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       475G  155G  320G  33% /
EOF
}
