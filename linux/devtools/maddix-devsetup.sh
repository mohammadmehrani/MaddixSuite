#!/bin/bash
# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
# Maddix-DevSetup - Developer Environment Installer
# Part of MaddixSuite by Mohammad Mehrani (Maddix)
# Installs essential dev tools: editors, languages, DBs, git, docker, cloud CLIs
# https://github.com/mohammadmehrani/MaddixSuite
# =========================================================

# set -e (removed for testability)
CYAN='\033[0;96m'; GREEN='\033[0;92m'; YELLOW='\033[0;93m'; RED='\033[0;91m'; MAGENTA='\033[0;95m'; GRAY='\033[0;90m'; RESET='\033[0m'

check_root() { [[ $EUID -eq 0 ]] || { echo -e "${RED}Run with sudo.${RESET}"; exit 1; } }

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release; OS_ID="$ID"
    elif [ -f /etc/debian_version ]; then
        OS_ID="debian"
    else
        OS_ID="unknown"
    fi
}

show_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║     Maddix-DevSetup v1.0 - Dev Environment             ║${RESET}"
    echo -e "${CYAN}║     Created by Mohammad Mehrani (Maddix)              ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

install_category() {
    local title="$1"; shift
    echo -e "\n${YELLOW}┌─ $title ─────────────────────┐${RESET}"
    local pkgs=("$@")
    local to_install=()
    for pkg in "${pkgs[@]}"; do
        echo -ne "  ${GRAY}${pkg}...${RESET}"
        if command -v "$pkg" &>/dev/null; then echo -e " ${GREEN}✓${RESET}"
        elif dpkg -s "$pkg" &>/dev/null 2>&1; then echo -e " ${GREEN}✓${RESET}"
        elif which "$pkg" &>/dev/null; then echo -e " ${GREEN}✓${RESET}"
        else echo -e " ${YELLOW}✗${RESET}"; to_install+=("$pkg"); fi
    done
    if [ ${#to_install[@]} -gt 0 ]; then
        read -p "Install missing packages? (y/n): " ans
        if [ "$ans" = "y" ]; then
            case "$OS_ID" in
                debian|ubuntu|linuxmint)
                    apt install -y "${to_install[@]}" ;;
                fedora|rhel|centos)
                    dnf install -y "${to_install[@]}" ;;
                arch|manjaro)
                    pacman -S --noconfirm "${to_install[@]}" ;;
                opensuse*)
                    zypper install -y "${to_install[@]}" ;;
                *)
                    echo -e "${RED}Unsupported distro. Manually install: ${to_install[*]}${RESET}" ;;
            esac
            echo -e "${GREEN}Done installing ${#to_install[@]} packages${RESET}"
        fi
    else
        echo -e "${GREEN}  All installed!${RESET}"
    fi
}

install_editors()       { install_category "EDITORS"        "vim" "neovim" "nano" "emacs" "code"; }
install_languages()     { install_category "LANGUAGES"      "gcc" "g++" "python3" "pip3" "nodejs" "npm" "rustc" "go" "openjdk-17-jdk" "php" "ruby" "perl"; }
install_shell_tools()   { install_category "SHELL TOOLS"    "curl" "wget" "git" "htop" "tmux" "zsh" "fish" "tree" "jq" "yq" "ripgrep" "fd-find" "fzf"; }
install_dbs()           { install_category "DATABASES"      "mysql-server" "postgresql" "redis" "mongodb" "sqlite3"; }
install_network()       { install_category "NETWORK"        "nmap" "net-tools" "tcpdump" "wireshark" "iperf3" "openssh-server" "openssh-client" "dnsutils"; }
install_docker()        { install_category "DOCKER"         "docker.io" "docker-compose"; }
install_cloud()         { install_category "CLOUD CLIS"     "awscli" "azure-cli" "doctl" "kubectl"; }
install_media()         { install_category "MEDIA"          "ffmpeg" "imagemagick" "vlc" "gimp" "inkscape"; }

install_all() {
    echo -e "\n${YELLOW}── INSTALLING ALL DEV TOOLS ──${RESET}"
    install_editors; install_languages; install_shell_tools
    install_dbs; install_network; install_docker
    install_media
    echo -e "\n${GREEN}✓ All dev tools installed!${RESET}"
}

show_menu() {
    show_banner
    echo -e " ${MAGENTA}── PACKAGE CATEGORIES ──${RESET}"
    echo "   1.  Editors (vim, neovim, nano, code)"
    echo "   2.  Languages (python, node, rust, go, java, php)"
    echo "   3.  Shell Tools (git, htop, tmux, jq, ripgrep)"
    echo "   4.  Databases (mysql, postgres, redis, mongo)"
    echo "   5.  Network Tools (nmap, tcpdump, wireshark)"
    echo "   6.  Docker (docker + compose)"
    echo "   7.  Cloud CLIs (aws, azure, kubernetes)"
    echo "   8.  Media Tools (ffmpeg, imagemagick)"
    echo ""
    echo -e " ${MAGENTA}── GENERAL ──${RESET}"
    echo "   9.  Install ALL Categories"
    echo "   0.  Exit"
    echo ""
}

main() {
    detect_distro
    check_root
    while true; do
        show_menu
        read -p "Select (0-9): " c
        case "$c" in
            1) install_editors ;;
            2) install_languages ;;
            3) install_shell_tools ;;
            4) install_dbs ;;
            5) install_network ;;
            6) install_docker ;;
            7) install_cloud ;;
            8) install_media ;;
            9) install_all ;;
            0) echo -e "${CYAN}Goodbye!${RESET}"; exit 0 ;;
            *) echo -e "${RED}Invalid${RESET}" ;;
        esac
        read -p "Press Enter..."
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

