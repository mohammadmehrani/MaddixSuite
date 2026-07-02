#!/usr/bin/env bats

load helpers/setup.bash

setup() {
    source "${MADDIX_ROOT}/linux/firewall/maddix-iptables.sh"
}

@test "maddix-iptables.sh should source without error" {
    run source "${MADDIX_ROOT}/linux/firewall/maddix-iptables.sh"
    [ "$status" -eq 0 ]
}

@test "show_banner should not error" {
    run show_banner
    [ "$status" -eq 0 ]
}

@test "detect_system should set variables" {
    run detect_system
    [ -n "$OS_ID" ]
}

@test "show_status function should exist" {
    command -v show_status
    [ "$?" -eq 0 ]
}
