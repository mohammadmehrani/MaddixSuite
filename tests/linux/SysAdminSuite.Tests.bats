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
    command -v check_root
    [ "$?" -eq 0 ]
}

@test "detect_distro should set PKG_MGR" {
    detect_distro
    [ -n "$PKG_MGR" ]
    [[ "$PKG_MGR" =~ ^(apt|dnf|pacman|zypper)$ ]]
}
