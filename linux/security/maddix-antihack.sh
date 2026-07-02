#!/bin/bash
# ============================================================================
# MaddixSuite — https://github.com/mohammadmehrani/MaddixSuite
# Author: Mohammad Mehrani (Maddix) — https://iodeck.ir
# ============================================================================
# maddix-antihack.sh — Advanced Anti-Hack, Rootkit & Exploit Detection for Linux
# Supports: Debian, Ubuntu, Fedora, RHEL, Arch, openSUSE, and derivatives
# Run: bash <(curl -s https://raw.githubusercontent.com/mohammadmehrani/MaddixSuite/main/linux/security/maddix-antihack.sh)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; GRAY='\033[1;30m'; NC='\033[0m'
THREATS=0; FINDINGS=()

header() { echo -e "\n${CYAN}╔══════════════════════════════════════╗${NC}"; echo -e "${CYAN}║  $1${NC}"; echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"; }
info() { echo -e "  ${GRAY}$1${NC}"; }
ok() { echo -e "  ${GREEN}[+] $1${NC}"; }
warn() { echo -e "  ${YELLOW}[!] $1${NC}"; }
crit() { echo -e "  ${RED}[!!] $1${NC}"; }
finding() { local sev="$1" cat="$2" msg="$3" sug="$4"; FINDINGS+=("$sev|$cat|$msg|$sug"); if [[ "$sev" == "CRITICAL" || "$sev" == "HIGH" ]]; then THREATS=$((THREATS+1)); fi; }

confirm() {
    echo -en "  ${YELLOW}Proceed? (Y/N): ${NC}"; read -r r
    [[ "$r" =~ ^[Yy]$ ]]
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"; DISTRO_LIKE="$ID_LIKE"
    else
        DISTRO=$(uname -s); DISTRO_LIKE=""
    fi
    
    if [[ "$DISTRO_LIKE" =~ (debian|ubuntu) || "$DISTRO" =~ (debian|ubuntu|mint|kali) ]]; then
        PKG_MGR="apt"; INSTALL="sudo apt-get install -y"; UPDATE="sudo apt-get update"
    elif [[ "$DISTRO_LIKE" =~ (fedora|rhel) || "$DISTRO" =~ (fedora|rhel|centos) ]]; then
        PKG_MGR="dnf"; INSTALL="sudo dnf install -y"; UPDATE="sudo dnf check-update"
    elif [[ "$DISTRO" =~ (arch|manjaro|endeavour) ]]; then
        PKG_MGR="pacman"; INSTALL="sudo pacman -S --noconfirm"; UPDATE="sudo pacman -Sy"
    elif [[ "$DISTRO" =~ (suse|opensuse) ]]; then
        PKG_MGR="zypper"; INSTALL="sudo zypper install -y"; UPDATE="sudo zypper refresh"
    else
        PKG_MGR="apt"; INSTALL="sudo apt-get install -y"; UPDATE="sudo apt-get update"
    fi
    info "Distro: $DISTRO | Package Manager: $PKG_MGR"
}

# ===========================================================================
# MODULE 1 — ROOTKIT DETECTION
# ===========================================================================
scan_rootkits() {
    header "Module 1: Rootkit Detection"
    
    # 1A — Install and run chkrootkit
    info "Checking chkrootkit..."
    if ! command -v chkrootkit &>/dev/null; then
        if confirm; then
            $UPDATE &>/dev/null
            $INSTALL chkrootkit &>/dev/null && ok "chkrootkit installed" || warn "Install failed"
        fi
    fi
    if command -v chkrootkit &>/dev/null; then
        info "Running chkrootkit (may take a minute)..."
        local out
        out=$(sudo chkrootkit -q 2>/dev/null)
        if [ -n "$out" ]; then
            while IFS= read -r line; do
                finding "CRITICAL" "Rootkit" "chkrootkit: $line" "Run: sudo chkrootkit to investigate"
                crit "INFECTED: $line"
            done <<< "$out"
        else
            ok "chkrootkit: no infections detected"
        fi
    else
        warn "chkrootkit not available — skipping"
    fi

    # 1B — Install and run rkhunter
    info "Checking rkhunter..."
    if ! command -v rkhunter &>/dev/null; then
        if confirm; then
            $INSTALL rkhunter &>/dev/null && ok "rkhunter installed" || warn "Install failed"
        fi
    fi
    if command -v rkhunter &>/dev/null; then
        info "Updating rkhunter DB..."
        sudo rkhunter --update &>/dev/null
        info "Running rkhunter check..."
        local rkout
        rkout=$(sudo rkhunter --check --skip-keypress --quiet 2>/dev/null)
        if echo "$rkout" | grep -qi "warning\|infected\|found"; then
            local warnings
            warnings=$(echo "$rkout" | grep -i "warning\|infected" | head -10)
            finding "HIGH" "Rootkit" "rkhunter warnings detected" "Review: sudo rkhunter --check"
            warn "rkhunter warnings found"
            echo "$warnings" | while IFS= read -r line; do info "  $line"; done
        else
            ok "rkhunter: clean"
        fi
    else
        warn "rkhunter not available — skipping"
    fi

    # 1C — Check hidden kernel modules
    info "Checking for hidden kernel modules..."
    local known_modules
    known_modules=$(lsmod | awk '{print $1}' | sort -u)
    local proc_modules
    proc_modules=$(cat /proc/modules 2>/dev/null | awk '{print $1}' | sort -u)
    local hidden=$(comm -13 <(echo "$known_modules") <(echo "$proc_modules") 2>/dev/null)
    if [ -n "$hidden" ]; then
        finding "CRITICAL" "Rootkit" "Hidden kernel module(s): $hidden" "Check: lsmod | grep -E '$(echo $hidden | tr ' ' '|')'"
        crit "Hidden kernel modules detected"
    else
        ok "No hidden kernel modules"
    fi

    # 1D — Check /dev for suspicious entries
    info "Checking /dev for suspicious entries..."
    local dev_sus
    dev_sus=$(find /dev -name "*key*" -o -name "*hook*" -o -name "*log*" 2>/dev/null | head -5)
    if [ -n "$dev_sus" ]; then
        finding "HIGH" "Rootkit" "Suspicious /dev entries: $dev_sus" "Investigate with: ls -la $dev_sus"
        warn "Suspicious /dev entries found"
    fi
}

# ===========================================================================
# MODULE 2 — KEYLOGGER DETECTION
# ===========================================================================
scan_keyloggers() {
    header "Module 2: Keylogger Detection"
    
    # 2A — Check input device permissions (keyboard sniffing)
    info "Checking input device permissions..."
    local input_devs
    input_devs=$(find /dev/input -type c -perm /o+r 2>/dev/null)
    if [ -n "$input_devs" ]; then
        finding "MEDIUM" "Keylogger" "Input devices world-readable — possible keylog access" "Restrict: sudo chmod 640 /dev/input/*"
        warn "Input devices are world-readable (possible keylogging)"
    fi

    # 2B — Check for kmod keyloggers
    info "Checking kernel module keyloggers..."
    local keylog_kmods=("ukc" "keylogger" "kbdhook" "lkl" "klog" "keyboard-hook")
    for km in "${keylog_kmods[@]}"; do
        if lsmod | grep -qi "$km"; then
            finding "CRITICAL" "Keylogger" "Kernel module keylogger: $km" "Remove: sudo modprobe -r $km && echo 'blacklist $km' | sudo tee -a /etc/modprobe.d/blacklist.conf"
            crit "Kernel module keylogger detected: $km"
        fi
    done

    # 2C — Check for running keylogger processes
    info "Scanning for keylogger processes..."
    local kl_procs=("logkeys" "pykeylogger" "xspy" "keylog" "uvk" "lkl" "klogd" "keylogger")
    for kp in "${kl_procs[@]}"; do
        local pid
        pid=$(pgrep -x "$kp" 2>/dev/null)
        if [ -n "$pid" ]; then
            finding "CRITICAL" "Keylogger" "Keylogger process running: $kp (PID: $pid)" "Kill: sudo kill -9 $pid && sudo killall $kp"
            crit "Keylogger $kp running with PID $pid"
        fi
    done

    # 2D — Check /proc for keyboard polling
    info "Checking for keyboard interrupt polling..."
    for pid_dir in /proc/[0-9]*; do
        local pid
        pid=$(basename "$pid_dir")
        local maps
        maps=$(grep -l "atkbd\|i8042\|kbd\|keyboard" "$pid_dir/maps" 2>/dev/null)
        if [ -n "$maps" ]; then
            local pname
            pname=$(cat "$pid_dir/comm" 2>/dev/null)
            if [[ "$pname" != "systemd" && "$pname" != "kworker"* && "$pname" != "Xorg" && "$pname" != "X" ]]; then
                finding "HIGH" "Keylogger" "Keyboard memory mapped in PID $pid ($pname)" "Investigate: sudo cat /proc/$pid/maps | grep -i keyboard"
                warn "Process $pname (PID $pid) maps keyboard memory"
            fi
        fi
    done

    ok "Keylogger scan complete"
}

# ===========================================================================
# MODULE 3 — BACKDOOR & PERSISTENCE
# ===========================================================================
scan_backdoors() {
    header "Module 3: Backdoor & Persistence Detection"

    # 3A — Scan cron jobs
    info "Scanning cron jobs..."
    local cron_dirs=("/var/spool/cron/crontabs" "/var/spool/cron" "/etc/cron.d" "/etc/cron.daily" "/etc/cron.hourly" "/etc/cron.weekly" "/etc/cron.monthly")
    for cd in "${cron_dirs[@]}"; do
        if [ -d "$cd" ]; then
            local sus_cron
            sus_cron=$(grep -r -l "bash\|python\|perl\|curl\|wget\|nc\|ncat\|sh -c\|/dev/tcp\|/dev/udp\|base64" "$cd" 2>/dev/null)
            if [ -n "$sus_cron" ]; then
                finding "HIGH" "Backdoor" "Suspicious cron entries in: $sus_cron" "Review: cat $sus_cron"
                warn "Suspicious cron jobs found in $cd"
            fi
        fi
    done

    # 3B — Check SSH authorized_keys for unauthorized keys
    info "Checking SSH authorized_keys..."
    for home in /root /home/*; do
        local ak="$home/.ssh/authorized_keys"
        if [ -f "$ak" ]; then
            local key_count
            key_count=$(wc -l < "$ak")
            if [ "$key_count" -gt 5 ]; then
                finding "MEDIUM" "Backdoor" "Many SSH keys ($key_count) in $ak" "Review: cat $ak"
                warn "$key_count SSH keys in $ak"
            fi
            # Check for keys with known backdoor comments
            local sus_keys
            sus_keys=$(grep -i "backdoor\|hack\|root\|admin\|test\|default" "$ak" 2>/dev/null)
            if [ -n "$sus_keys" ]; then
                finding "HIGH" "Backdoor" "Suspicious SSH key comment in $ak" "Remove suspicious entries: ssh-keygen -R host"
                warn "SSH keys with suspicious comments in $ak"
            fi
        fi
    done

    # 3C — Check for SUID/SGID backdoors
    info "Scanning SUID/SGID binaries..."
    local suid_files
    suid_files=$(find / -type f \( -perm -4000 -o -perm -2000 \) -not -path "/sys/*" -not -path "/proc/*" 2>/dev/null | head -50)
    local known_suid=("/bin/su" "/bin/ping" "/bin/mount" "/bin/umount" "/usr/bin/su" "/usr/bin/sudo" "/usr/bin/passwd" "/usr/bin/chsh" "/usr/bin/chfn" "/usr/bin/gpasswd" "/usr/bin/newgrp" "/usr/bin/pkexec" "/usr/bin/crontab" "/usr/lib/polkit-1/polkit-agent-helper-1" "/usr/libexec/polkit-agent-helper-1")
    while IFS= read -r sf; do
        local is_known=0
        for ksf in "${known_suid[@]}"; do
            if [ "$sf" = "$ksf" ]; then is_known=1; break; fi
        done
        if [ "$is_known" -eq 0 ]; then
            finding "HIGH" "Backdoor" "Unknown SUID binary: $sf" "Investigate: ls -la $sf && file $sf"
            warn "Unknown SUID: $sf"
        fi
    done <<< "$suid_files"

    # 3D — Check systemd services for suspicious entries
    info "Scanning systemd services..."
    local sus_svc
    sus_svc=$(find /etc/systemd/system /usr/lib/systemd/system -name "*.service" -newer /etc/passwd 2>/dev/null | head -10)
    if [ -n "$sus_svc" ]; then
        while IFS= read -r svc; do
            local svc_cmd
            svc_cmd=$(grep -i "ExecStart" "$svc" 2>/dev/null | head -1)
            if echo "$svc_cmd" | grep -qiE "bash|python|perl|curl|wget|nc|ncat|base64|/dev/tcp"; then
                finding "CRITICAL" "Backdoor" "Suspicious systemd service: $svc → $svc_cmd" "Disable: sudo systemctl disable $(basename $svc .service)"
                crit "Backdoor systemd service: $svc"
            fi
        done <<< "$sus_svc"
    fi

    # 3E — Check .bashrc / .profile for persistence
    info "Checking shell config persistence..."
    local rc_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.bash_profile" "/root/.bashrc" "/root/.profile")
    for rc in "${rc_files[@]}"; do
        if [ -f "$rc" ]; then
            local sus_rc
            sus_rc=$(grep -nE "(curl|wget|nc|ncat|/dev/tcp|/dev/udp|python.*http|bash.*-c|base64.*-d)" "$rc" 2>/dev/null | grep -v "^#")
            if [ -n "$sus_rc" ]; then
                finding "HIGH" "Persistence" "Suspicious commands in $rc: $sus_rc" "Review and clean: nano $rc"
                warn "Suspicious entries in $rc"
            fi
        fi
    done

    ok "Backdoor scan complete"
}

# ===========================================================================
# MODULE 4 — NETWORK ATTACK DETECTION
# ===========================================================================
scan_network() {
    header "Module 4: Network Attack Detection"

    # 4A — Check for suspicious listening ports
    info "Checking listening ports..."
    if command -v ss &>/dev/null; then
        local listening
        listening=$(ss -tlnp 2>/dev/null | awk '{print $4}' | grep -oP '\d+$' | sort -u)
        local sus_ports=(4444 5555 6666 6667 7777 8443 9001 9050 9051 10000 12345 20034 27374 31337 41414 65000)
        for port in $listening; do
            for sp in "${sus_ports[@]}"; do
                if [ "$port" = "$sp" ]; then
                    local proc
                    proc=$(ss -tlnp 2>/dev/null | grep ":$port " | grep -oP 'users:\(\("[^"]+' | grep -oP '[^"]+$')
                    finding "HIGH" "Network" "Suspicious listening port: $port ($proc)" "Investigate: sudo ss -tlnp | grep ':$port '"
                    warn "Suspicious port $port listening ($proc)"
                fi
            done
        done
    fi

    # 4B — Check ARP for spoofing
    info "Checking ARP table for spoofing..."
    if command -v arp &>/dev/null; then
        local gateway
        gateway=$(ip route | grep default | awk '{print $3}' | head -1)
        if [ -n "$gateway" ]; then
            local gw_count
            gw_count=$(arp -n 2>/dev/null | grep -c "$gateway")
            if [ "$gw_count" -gt 1 ]; then
                finding "CRITICAL" "Network" "ARP spoofing possible: gateway $gateway has $gw_count entries" "Check: arp -n | grep $gateway"
                crit "ARP spoofing indicator detected!"
            fi
        fi
    fi

    # 4C — Check promiscuous mode
    info "Checking for promiscuous mode..."
    local promisc
    promisc=$(ip link 2>/dev/null | grep -i "PROMISC")
    if [ -n "$promisc" ]; then
        finding "HIGH" "Network" "Promiscuous mode detected — possible packet sniffing" "Disable: sudo ip link set <interface> -promisc"
        warn "Network interface in promiscuous mode"
    fi

    # 4D — Check DNS config
    info "Checking DNS configuration..."
    if [ -f /etc/resolv.conf ]; then
        local dns_servers
        dns_servers=$(grep -oP '(?<=nameserver )\S+' /etc/resolv.conf)
        local known_dns=("8.8.8.8" "8.8.4.4" "1.1.1.1" "1.0.0.1" "208.67.222.222" "208.67.220.220" "9.9.9.9" "149.112.112.112")
        for dns in $dns_servers; do
            local safe=0
            for kd in "${known_dns[@]}"; do [ "$dns" = "$kd" ] && { safe=1; break; } done
            if [ "$safe" -eq 0 ] && [[ ! "$dns" =~ ^192\.168\.|^10\.|^172\. ]]; then
                finding "MEDIUM" "Network" "Unusual DNS server: $dns" "Verify in /etc/resolv.conf"
                warn "Unusual DNS: $dns"
            fi
        done
    fi

    # 4E — Check iptables for suspicious rules
    info "Checking firewall for suspicious rules..."
    if command -v iptables &>/dev/null; then
        local sus_rules
        sus_rules=$(sudo iptables -L -n 2>/dev/null | grep -E "ACCEPT.*tcp.*(4444|5555|6666|6667|7777|8443|12345|27374|31337)")
        if [ -n "$sus_rules" ]; then
            finding "HIGH" "Network" "Firewall allows suspicious ports" "Review: sudo iptables -L -n"
            warn "Suspicious firewall rules"
        fi
    fi

    ok "Network scan complete"
}

# ===========================================================================
# MODULE 5 — PROCESS & MEMORY
# ===========================================================================
scan_processes() {
    header "Module 5: Process & Memory Analysis"

    # 5A — Check malicious process names
    info "Scanning for known malicious processes..."
    local bad_names=("mimikatz" "nc" "netcat" "ncat" "beacon" "cobaltstrike" "meterpreter" "metasploit" "empire" "pwn" "hydra" "john" "hashcat" "miner" "xmrig" "cpuminer" "ccminer")
    for bn in "${bad_names[@]}"; do
        local found_pid
        found_pid=$(pgrep -x "$bn" 2>/dev/null)
        if [ -z "$found_pid" ]; then
            found_pid=$(pgrep "$bn" 2>/dev/null)
        fi
        if [ -n "$found_pid" ]; then
            finding "CRITICAL" "Process" "Malicious process: $bn (PID: $found_pid)" "Kill: sudo kill -9 $found_pid && sudo killall $bn"
            crit "Malicious process $bn running (PID $found_pid)"
        fi
    done

    # 5B — Check for reverse shell connections
    info "Checking for reverse shells..."
    local unique_connections
    unique_connections=$(ss -tnp 2>/dev/null | grep ESTAB | grep -oP '\d+\.\d+\.\d+\.\d+:\d+' | sort -u)
    while IFS= read -r conn; do
        local proc_info
        proc_info=$(ss -tnp 2>/dev/null | grep "$conn" | grep -oP 'users:\(\("[^"]+' | head -1)
        if [[ "$conn" =~ ^(10\.|192\.168\.|172\.|127\.) ]]; then
            continue
        fi
        local port
        port=$(echo "$conn" | grep -oP '\d+$')
        if [ "$port" = "4444" ] || [ "$port" = "5555" ] || [ "$port" = "6666" ] || [ "$port" = "6667" ] || [ "$port" = "7777" ] || [ "$port" = "8443" ] || [ "$port" = "12345" ] || [ "$port" = "27374" ] || [ "$port" = "31337" ]; then
            finding "CRITICAL" "Network" "Possible reverse shell: $conn ($proc_info)" "Investigate immediately"
            crit "Reverse shell connection: $conn"
        fi
    done <<< "$unique_connections"

    # 5C — Check for LD_PRELOAD injection
    info "Checking for LD_PRELOAD injection..."
    for pid_dir in /proc/[0-9]*; do
        local ldp
        ldp=$(cat "$pid_dir/environ" 2>/dev/null | tr '\0' '\n' | grep "^LD_PRELOAD=")
        if [ -n "$ldp" ]; then
            local pid
            pid=$(basename "$pid_dir")
            local pname
            pname=$(cat "$pid_dir/comm" 2>/dev/null)
            finding "HIGH" "Process" "LD_PRELOAD in PID $pid ($pname): $ldp" "Check the injected library"
            warn "LD_PRELOAD injection in $pname (PID $pid)"
        fi
    done

    ok "Process scan complete"
}

# ===========================================================================
# MODULE 6 — FILE INTEGRITY & SYSTEM AUDIT
# ===========================================================================
scan_files() {
    header "Module 6: File Integrity & System Audit"

    # 6A — Check for sensitive file modifications
    info "Checking sensitive file integrity..."
    local sensitive=("/etc/passwd" "/etc/shadow" "/etc/sudoers" "/etc/ssh/sshd_config" "/etc/hosts")
    for sf in "${sensitive[@]}"; do
        if [ -f "$sf" ]; then
            local changed
            changed=$(stat -c '%y' "$sf" 2>/dev/null)
            local days
            days=$(( ($(date +%s) - $(stat -c '%Y' "$sf")) / 86400 ))
            if [ "$days" -lt 1 ]; then
                finding "HIGH" "Integrity" "$sf modified today ($changed)" "Review recent changes to $sf"
                warn "$sf modified recently"
            fi
        fi
    done

    # 6B — Check world-writable directories
    info "Scanning world-writable directories..."
    local ww_dirs
    ww_dirs=$(find / -type d -perm -o+w -not -path "/proc/*" -not -path "/sys/*" -not -path "/dev/*" -not -path "/run/*" -not -path "/tmp/*" -not -path "/var/tmp/*" 2>/dev/null | head -20)
    if [ -n "$ww_dirs" ]; then
        finding "MEDIUM" "Integrity" "World-writable directories exist" "Check: find / -type d -perm -o+w -not -path /proc -not -path /sys 2>/dev/null"
        warn "World-writable directories found (potential privilege escalation vector)"
    fi

    # 6C — Check kernel log for exploits
    info "Checking kernel log for exploit attempts..."
    if command -v dmesg &>/dev/null; then
        local exploit_logs
        exploit_logs=$(sudo dmesg 2>/dev/null | grep -i "exploit\|segfault\|spoof\|attack\|unauthorized" | tail -5)
        if [ -n "$exploit_logs" ]; then
            finding "HIGH" "Exploit" "Kernel log shows exploit indicators" "Review: sudo dmesg | grep -i exploit"
            warn "Exploit indicators in kernel log"
        fi
    fi

    ok "File integrity scan complete"
}

# ===========================================================================
# REPORT
# ===========================================================================
show_report() {
    header "SCAN RESULTS"
    echo -e "  Total threats found: ${YELLOW}$THREATS${NC}"
    echo ""

    if [ ${#FINDINGS[@]} -eq 0 ]; then
        echo -e "  ${GREEN}[i] System appears clean.${NC}"
    else
        local i=0
        for f in "${FINDINGS[@]}"; do
            ((i++))
            IFS='|' read -r sev cat msg sug <<< "$f"
            local color
            case "$sev" in
                CRITICAL) color="$RED" ;;
                HIGH) color="$YELLOW" ;;
                *) color="$GRAY" ;;
            esac
            echo -e "  ${color}#$i [$cat] $sev${NC}"
            echo -e "     $msg"
            echo -e "     ${GRAY}=> $sug${NC}"
            echo ""
        done
    fi

    # Save report
    local report_dir
    report_dir="$HOME/MaddixSuite/AntiHack_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$report_dir"
    
    {
        echo "MaddixSuite — AntiHack Report"
        echo "Date: $(date)"
        echo "Host: $(hostname)"
        echo "Distro: $DISTRO"
        echo "Threats: $THREATS"
        echo "---"
        for f in "${FINDINGS[@]}"; do
            IFS='|' read -r sev cat msg sug <<< "$f"
            echo "[$sev] [$cat] $msg => $sug"
        done
    } > "$report_dir/Report.txt"

    echo -e "  ${GREEN}Report saved: $report_dir/Report.txt${NC}"
    echo
    echo -e "  ${YELLOW}Note: Some scans require root tools (chkrootkit/rkhunter).${NC}"
    echo -e "  ${YELLOW}Run with sudo for full detection capability.${NC}"
}

main() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║       MaddixSuite — Advanced Anti-Hack Scanner            ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo -e "  ${GRAY}GitHub: https://github.com/mohammadmehrani/MaddixSuite${NC}"
    echo -e "  ${GRAY}Website: https://iodeck.ir${NC}"
    echo -e "  ${GRAY}Detecting: Rootkits, Keyloggers, Backdoors, Network Attacks, Exploits${NC}"
    echo ""

    detect_distro

    echo ""
    echo -e "  ${YELLOW}The following modules will be executed:${NC}"
    echo -e "  ${GRAY}  1. Rootkit Detection (chkrootkit, rkhunter, kernel modules)${NC}"
    echo -e "  ${GRAY}  2. Keylogger Detection (processes, kernel modules, input devices)${NC}"
    echo -e "  ${GRAY}  3. Backdoor & Persistence (cron, SSH, systemd, shell config)${NC}"
    echo -e "  ${GRAY}  4. Network Attack (listeners, ARP, promiscuous, DNS, firewall)${NC}"
    echo -e "  ${GRAY}  5. Process & Memory (malicious names, reverse shells, LD_PRELOAD)${NC}"
    echo -e "  ${GRAY}  6. File Integrity (sensitive files, permissions, kernel logs)${NC}"
    echo ""
    if confirm; then
        echo ""
        scan_rootkits
        scan_keyloggers
        scan_backdoors
        scan_network
        scan_processes
        scan_files
        show_report
    else
        echo -e "  ${YELLOW}Scan cancelled.${NC}"
    fi

    echo -e "\n  ${GRAY}Scan complete. Visit https://iodeck.ir for more tools.${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
