#!/bin/bash
# Tool: SYS-004 — Bootloader Repair
# MaddixSuite https://github.com/mohammadmehrani/MaddixSuite

TOOL_ID="SYS-004"
TOOL_NAME="Bootloader Repair"
TOOL_CATEGORY="SYS"
TOOL_DESC="Reinstall GRUB for BIOS/UEFI"
TOOL_DANGER="High"
TOOL_CONFIRM="Reinstall GRUB bootloader?"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'

tool_action() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "  ${RED}[!!] This tool requires root privileges${NC}"
        exit 1
    fi
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ -d /sys/firmware/efi ]]; then
            echo -e "  ${GREEN}[+] Detected UEFI system${NC}"
            case "$ID" in
                debian|ubuntu|mint|kali)
                    apt-get install --reinstall grub-efi -y
                    update-grub
                    ;;
                fedora|rhel|centos|rocky|alma)
                    dnf reinstall grub2-efi -y
                    grub2-mkconfig -o /boot/grub2/grub.cfg
                    ;;
                arch|manjaro)
                    pacman -S --noconfirm grub
                    grub-mkconfig -o /boot/grub/grub.cfg
                    ;;
                *)
                    echo -e "  ${YELLOW}[!] Unsupported distro for UEFI GRUB reinstall${NC}"
                    ;;
            esac
        else
            echo -e "  ${GREEN}[+] Detected BIOS system${NC}"
            case "$ID" in
                debian|ubuntu|mint|kali)
                    apt-get install --reinstall grub-pc -y
                    update-grub
                    ;;
                fedora|rhel|centos|rocky|alma)
                    dnf reinstall grub2 -y
                    grub2-mkconfig -o /boot/grub2/grub.cfg
                    ;;
                arch|manjaro)
                    pacman -S --noconfirm grub
                    grub-mkconfig -o /boot/grub/grub.cfg
                    ;;
                *)
                    echo -e "  ${YELLOW}[!] Unsupported distro for BIOS GRUB reinstall${NC}"
                    ;;
            esac
        fi
        echo -e "  ${GREEN}[+] GRUB reinstalled successfully${NC}"
    else
        echo -e "  ${RED}[!!] Cannot detect OS${NC}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tool_action
fi
