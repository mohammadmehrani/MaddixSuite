#!/usr/bin/env bats

load helpers/setup.bash

setup() {
    source "${MADDIX_ROOT}/linux/MaddixSuite.sh"
    MADDIX_TEST_MODE=1
}

@test "MaddixSuite.sh should source without error" {
    run source "${MADDIX_ROOT}/linux/MaddixSuite.sh"
    [ "$status" -eq 0 ]
}

@test "detect_system should set environment variables" {
    run detect_system
    [ -n "$OS_NAME" ]
    [ -n "$OS_ID" ]
    [ -n "$KERNEL" ]
    [ -n "$HOSTNAME" ]
}

@test "show_banner should not error" {
    run show_banner
    [ "$status" -eq 0 ]
}

@test "show_system_info should not error" {
    detect_system
    run show_system_info
    [ "$status" -eq 0 ]
}

@test "header function should output colored text" {
    run header "Test Header"
    [ "$status" -eq 0 ]
}

@test "info function should output gray text" {
    run info "Test info"
    [ "$status" -eq 0 ]
}

@test "ok function should output green success" {
    run ok "Test success"
    [ "$status" -eq 0 ]
}

@test "warn function should output yellow warning" {
    run warn "Test warning"
    [ "$status" -eq 0 ]
}

@test "SYS-001 sys_info should not error" {
    detect_system
    run sys_info
    [ "$status" -eq 0 ]
}

@test "NET-001 net_diag should not error" {
    run net_diag
    [ "$status" -eq 0 ]
}

@test "SEC-001 sec_audit should not error" {
    run sec_audit
    [ "$status" -eq 0 ]
}

@test "CLN-001 cln_system should not error" {
    run cln_system
    [ "$status" -eq 0 ]
}

@test "OPT-001 opt_swappiness should show current value" {
    run opt_swappiness
    [ "$status" -eq 0 ]
}

@test "BAK-001 bak_packages should not error" {
    run bak_packages
    [ "$status" -eq 0 ]
}

@test "DEV-001 dev_fish should check if fish exists" {
    run dev_fish
    [ "$status" -eq 0 ]
}

@test "show_help should not error" {
    run show_help
    [ "$status" -eq 0 ]
}

@test "run_tool with valid ID should execute" {
    run run_tool "SYS-001"
    [ "$status" -eq 0 ]
}

@test "run_tool with unknown ID should warn" {
    run run_tool "SYS-999"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Unknown" ]]
}
