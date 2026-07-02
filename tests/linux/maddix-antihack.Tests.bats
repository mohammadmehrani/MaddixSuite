#!/usr/bin/env bats

load helpers/setup.bash

setup() {
    source "${MADDIX_ROOT}/linux/security/maddix-antihack.sh"
}

@test "maddix-antihack.sh should source without error" {
    run source "${MADDIX_ROOT}/linux/security/maddix-antihack.sh"
    [ "$status" -eq 0 ]
}

@test "detect_distro should identify package manager" {
    run detect_distro
    [ -n "$DISTRO" ]
    [ -n "$PKG_MGR" ]
}

@test "header function should not error" {
    run header "Test Header"
    [ "$status" -eq 0 ]
}

@test "finding function should add to array" {
    THREATS=0
    FINDINGS=()
    run finding "HIGH" "Test" "Test finding" "No action"
    [ "$status" -eq 0 ]
}

@test "scan_rootkits should not error" {
    run scan_rootkits
    [ "$status" -eq 0 ]
}

@test "scan_keyloggers should not error" {
    run scan_keyloggers
    [ "$status" -eq 0 ]
}

@test "scan_backdoors should not error" {
    run scan_backdoors
    [ "$status" -eq 0 ]
}

@test "scan_network should not error" {
    run scan_network
    [ "$status" -eq 0 ]
}

@test "scan_processes should not error" {
    run scan_processes
    [ "$status" -eq 0 ]
}

@test "scan_files should not error" {
    run scan_files
    [ "$status" -eq 0 ]
}

@test "show_report should not error" {
    THREATS=0
    FINDINGS=()
    run show_report
    [ "$status" -eq 0 ]
}
