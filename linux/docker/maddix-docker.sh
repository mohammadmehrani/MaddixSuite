#!/bin/bash
# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
# Maddix-DockerManager - Docker Container & Image Manager
# Part of MaddixSuite by Mohammad Mehrani (Maddix)
# https://github.com/mohammadmehrani/MaddixSuite
#
# Run: bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/docker/maddix-docker.sh)
# =========================================================

# set -e (removed for testability)

CYAN='\033[0;96m'; GREEN='\033[0;92m'; YELLOW='\033[0;93m'; RED='\033[0;91m'; MAGENTA='\033[0;95m'; GRAY='\033[0;90m'; RESET='\033[0m'

check_root() { [[ $EUID -eq 0 ]] || { echo -e "${RED}Run with sudo for install.${RESET}"; return 1; } }

install_docker_linux() {
    echo -e "\n${YELLOW}── INSTALLING DOCKER ──${RESET}"
    check_root || return 1

    if command -v docker &>/dev/null; then
        echo -e "${GREEN}Docker already installed: $(docker --version 2>/dev/null)${RESET}"
        return 0
    fi

    echo "Detecting distro and installing..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu|linuxmint)
                apt update && apt install -y ca-certificates curl gnupg
                install -m 0755 -d /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/$ID/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                ;;
            fedora)
                dnf -y install dnf-plugins-core
                dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
                dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
                systemctl enable --now docker
                ;;
            arch|manjaro)
                pacman -S --noconfirm docker docker-compose
                systemctl enable --now docker
                ;;
            opensuse*)
                zypper install -y docker docker-compose
                systemctl enable --now docker
                ;;
            *)
                echo -e "${RED}Unsupported: $ID. Use: curl -fsSL https://get.docker.com | sh${RESET}"
                return 1
                ;;
        esac
    fi

    usermod -aG docker ${SUDO_USER:-$USER} 2>/dev/null || true
    echo -e "${GREEN}✓ Docker installed! Re-login to use without sudo.${RESET}"
}

check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Docker not installed.${RESET}"
        read -p "Install Docker now? (y/n): " ans
        if [ "$ans" = "y" ]; then install_docker_linux; else return 1; fi
    fi
    return 0
}

show_banner() {
    clear
    echo -e "${CYAN}================================================================${RESET}"
    echo -e "${CYAN}  Maddix-DockerManager v1.0 - Docker Management Suite${RESET}"
    echo -e "${CYAN}  Created by Mohammad Mehrani (Maddix)${RESET}"
    echo -e "${CYAN}================================================================${RESET}"
    echo ""
}

list_containers() {
    echo -e "\n${YELLOW}=== CONTAINERS ===${RESET}"
    echo -e "Running:"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  None"
    echo -e "\nAll containers:"
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}" 2>/dev/null || echo "  None"
    echo ""
    echo "Total: $(docker ps -q 2>/dev/null | wc -l) running / $(docker ps -aq 2>/dev/null | wc -l) total"
}

list_images() {
    echo -e "\n${YELLOW}=== IMAGES ===${RESET}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" 2>/dev/null || echo "  None"
    echo ""
    echo "Total: $(docker images -q 2>/dev/null | sort -u | wc -l) images"
    echo "Total size: $(docker system df 2>/dev/null | grep Images | awk '{print $2 " " $3}')"
}

container_menu() {
    while true; do
        show_banner
        list_containers
        echo -e "\n ${MAGENTA}---- CONTAINER ACTIONS ----${RESET}"
        echo "   1.  Start Container"
        echo "   2.  Stop Container"
        echo "   3.  Restart Container"
        echo "   4.  Remove Container"
        echo "   5.  View Logs"
        echo "   6.  Exec into Container (bash)"
        echo "   7.  Prune Stopped Containers"
        echo "   0.  Back"
        read -p "Select: " c
        case "$c" in
            1|2|3|4|5|6)
                read -p "Container name/ID: " cont
                case "$c" in
                    1) docker start "$cont"; echo -e "${GREEN}Started $cont${RESET}" ;;
                    2) docker stop "$cont"; echo -e "${GREEN}Stopped $cont${RESET}" ;;
                    3) docker restart "$cont"; echo -e "${GREEN}Restarted $cont${RESET}" ;;
                    4) read -p "Force remove? (y/n): " f; [ "$f" = "y" ] && docker rm -f "$cont" || docker rm "$cont"; echo -e "${GREEN}Removed $cont${RESET}" ;;
                    5) docker logs --tail 50 "$cont" ;;
                    6) docker exec -it "$cont" /bin/bash 2>/dev/null || docker exec -it "$cont" /bin/sh ;;
                esac ;;
            7) docker container prune -f; echo -e "${GREEN}Pruned.${RESET}" ;;
            0) break ;;
        esac
        read -p "Press Enter..."
    done
}

image_menu() {
    while true; do
        show_banner
        list_images
        echo -e "\n ${MAGENTA}---- IMAGE ACTIONS ----${RESET}"
        echo "   1.  Pull Image"
        echo "   2.  Remove Image"
        echo "   3.  Prune Unused Images"
        echo "   4.  Build from Dockerfile"
        echo "   5.  Search Docker Hub"
        echo "   6.  Show Image History"
        echo "   0.  Back"
        read -p "Select: " c
        case "$c" in
            1)
                read -p "Image name (e.g., nginx:latest): " img
                docker pull "$img"
                echo -e "${GREEN}Pulled $img${RESET}" ;;
            2)
                read -p "Image name/ID: " img
                docker rmi "$img"
                echo -e "${GREEN}Removed $img${RESET}" ;;
            3) docker image prune -a -f; echo -e "${GREEN}Pruned.${RESET}" ;;
            4)
                read -p "Path to Dockerfile: " df
                read -p "Tag name: " tag
                docker build -t "$tag" "$df"
                echo -e "${GREEN}Built $tag${RESET}" ;;
            5)
                read -p "Search term: " term
                docker search "$term" --format "table {{.Name}}\t{{.Description}}\t{{.Stars}}\t{{.Official}}" | head -20 ;;
            6)
                read -p "Image name: " img
                docker history "$img" ;;
            0) break ;;
        esac
        read -p "Press Enter..."
    done
}

system_menu() {
    while true; do
        show_banner
        echo -e " ${MAGENTA}---- DOCKER SYSTEM ----${RESET}"
        echo -e "\nDisk Usage:"
        docker system df 2>/dev/null
        echo -e "\nSystem Info:"
        docker info --format 'Containers: {{.Containers}}\nImages: {{.Images}}\nStorage: {{.Driver}}\nServer: {{.ServerVersion}}' 2>/dev/null
        echo ""
        echo "   1.  Prune Everything (containers, images, volumes, networks)"
        echo "   2.  Prune Volumes"
        echo "   3.  Prune Networks"
        echo "   4.  Show Events (monitor)"
        echo "   5.  Docker Compose Up"
        echo "   6.  Docker Compose Down"
        echo "   0.  Back"
        read -p "Select: " c
        case "$c" in
            1) docker system prune -a -f --volumes; echo -e "${GREEN}All pruned.${RESET}" ;;
            2) docker volume prune -f; echo -e "${GREEN}Volumes pruned.${RESET}" ;;
            3) docker network prune -f; echo -e "${GREEN}Networks pruned.${RESET}" ;;
            4) echo -e "${YELLOW}Monitoring events (Ctrl+C to stop)...${RESET}"; docker events --since 1m ;;
            5) read -p "Path to docker-compose.yml: " dc; docker-compose -f "$dc/docker-compose.yml" up -d 2>/dev/null || docker compose -f "$dc/docker-compose.yml" up -d; echo -e "${GREEN}Compose up.${RESET}" ;;
            6) read -p "Path to docker-compose.yml: " dc; docker-compose -f "$dc/docker-compose.yml" down 2>/dev/null || docker compose -f "$dc/docker-compose.yml" down; echo -e "${GREEN}Compose down.${RESET}" ;;
            0) break ;;
        esac
        read -p "Press Enter..."
    done
}

show_menu() {
    show_banner
    echo -e " ${MAGENTA}---- DOCKER MANAGEMENT ----${RESET}"
    echo "   1.  Install Docker (auto-detect distro)"
    echo "   2.  Container Manager (start/stop/logs/exec)"
    echo "   3.  Image Manager (pull/remove/build/search)"
    echo "   4.  System Manager (prune/info/compose)"
    echo "   5.  Quick Stats (live)"
    echo "   0.  Exit"
    echo ""
}

quick_stats() {
    echo -e "\n${YELLOW}=== DOCKER STATS (live, Ctrl+C to stop) ===${RESET}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    read -p "Stream stats continuously? (y/n): " ans
    if [ "$ans" = "y" ]; then docker stats; fi
}

main() {
    check_docker || exit 1
    while true; do
        show_menu
        read -p "Select option (0-5): " c
        case "$c" in
            1) install_docker_linux; read -p "Press Enter..." ;;
            2) container_menu ;;
            3) image_menu ;;
            4) system_menu ;;
            5) quick_stats; read -p "Press Enter..." ;;
            0) echo -e "${CYAN}Goodbye!${RESET}"; exit 0 ;;
            *) echo -e "${RED}Invalid.${RESET}"; read -p "Press Enter..." ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

