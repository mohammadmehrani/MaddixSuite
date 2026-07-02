#!/usr/bin/env bats

load helpers/setup.bash

setup() {
    source "${MADDIX_ROOT}/linux/devtools/maddix-devsetup.sh"
}

@test "maddix-devsetup.sh should source without error" {
    run source "${MADDIX_ROOT}/linux/devtools/maddix-devsetup.sh"
    [ "$status" -eq 0 ]
}

@test "show_banner should not error" {
    run show_banner
    [ "$status" -eq 0 ]
}

@test "show_menu should not error" {
    run show_menu
    [ "$status" -eq 0 ]
}
