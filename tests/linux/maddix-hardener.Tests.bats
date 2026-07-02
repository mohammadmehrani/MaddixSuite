#!/usr/bin/env bats

load helpers/setup.bash

setup() {
    source "${MADDIX_ROOT}/linux/security/maddix-hardener.sh"
}

@test "maddix-hardener.sh should source without error" {
    run source "${MADDIX_ROOT}/linux/security/maddix-hardener.sh"
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

@test "ssh_harden function should exist" {
    command -v ssh_harden
    [ "$?" -eq 0 ]
}

@test "kernel_harden function should exist" {
    command -v kernel_harden
    [ "$?" -eq 0 ]
}
