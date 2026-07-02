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

@test "detect_distro should set OS_ID" {
    detect_distro
    [ -n "$OS_ID" ]
}

@test "audit_ssh function should exist" {
    command -v audit_ssh
    [ "$?" -eq 0 ]
}

@test "harden_sysctl function should exist" {
    command -v harden_sysctl
    [ "$?" -eq 0 ]
}
