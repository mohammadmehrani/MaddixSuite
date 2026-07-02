#!/usr/bin/env bats

load helpers/setup.bash

setup() {
    source "${MADDIX_ROOT}/linux/SysAdminSuite.sh"
}

@test "SysAdminSuite.sh should source without error" {
    run source "${MADDIX_ROOT}/linux/SysAdminSuite.sh"
    [ "$status" -eq 0 ]
}

@test "check_root function should exist" {
    run check_root
    [ "$status" -eq 0 ]
}

@test "detect_distro should set PKG_MGR" {
    run detect_distro
    [ -n "$PKG_MGR" ]
    [[ "$PKG_MGR" =~ ^(apt|dnf|pacman|zypper)$ ]]
}

@test "show_banner should not error" {
    run show_banner
    [ "$status" -eq 0 ]
}

@test "show_system_info should not error" {
    detect_distro
    run show_system_info
    [ "$status" -eq 0 ]
}
