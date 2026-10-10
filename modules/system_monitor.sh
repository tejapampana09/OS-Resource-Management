#!/usr/bin/env bash
# ==============================================================================
# modules/system_monitor.sh - Read-only Live Host Resource Monitoring
# ==============================================================================

# Check utility availability helper
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Display system summary: uptime, load averages, memory, CPU
show_system_overview() {
    show_banner "Live System Monitor - System Overview" \
                "Real-time host metrics (Read-only, no root privileges required)"

    echo -e "${COLOR_BOLD}1. Host & Uptime Information:${COLOR_RESET}"
    if has_cmd uptime; then
        echo -e "  $(uptime)"
    elif [[ -f /proc/uptime ]]; then
        local up_sec
        up_sec=$(awk '{print int($1)}' /proc/uptime)
        echo -e "  Uptime: $(( up_sec / 3600 )) hours, $(( (up_sec % 3600) / 60 )) mins"
    else
        echo -e "  ${COLOR_YELLOW}[N/A] Uptime utility not found.${COLOR_RESET}"
    fi

    echo -e "\n${COLOR_BOLD}2. CPU Architecture & Cores:${COLOR_RESET}"
    if [[ -f /proc/cpuinfo ]]; then
        local model_name cores
        model_name=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//')
        cores=$(grep -c "^processor" /proc/cpuinfo)
        echo -e "  Model: ${COLOR_CYAN}${model_name:-Generic x86_64/ARM}${COLOR_RESET}"
        echo -e "  Cores: ${COLOR_GREEN}${cores}${COLOR_RESET}"
    else
        echo -e "  ${COLOR_YELLOW}[N/A] /proc/cpuinfo not accessible.${COLOR_RESET}"
    fi

    echo -e "\n${COLOR_BOLD}3. Memory & Swap Utilization:${COLOR_RESET}"
    if has_cmd free; then
        free -h
    elif [[ -f /proc/meminfo ]]; then
        local mem_total mem_free mem_avail
        mem_total=$(grep "MemTotal" /proc/meminfo | awk '{print $2, $3}')
        mem_free=$(grep "MemFree" /proc/meminfo | awk '{print $2, $3}')
        mem_avail=$(grep "MemAvailable" /proc/meminfo | awk '{print $2, $3}')
        echo -e "  Total: ${mem_total} | Free: ${mem_free} | Available: ${mem_avail}"
    else
        echo -e "  ${COLOR_YELLOW}[N/A] Memory statistics unavailable.${COLOR_RESET}"
    fi

    echo -e "\n${COLOR_BOLD}4. Filesystem Storage Usage:${COLOR_RESET}"
    if has_cmd df; then
        df -h -x tmpfs -x devtmpfs 2>/dev/null || df -h
    else
        echo -e "  ${COLOR_YELLOW}[N/A] df utility not found.${COLOR_RESET}"
    fi

    echo -e "\n${COLOR_BOLD}5. Block Storage Devices:${COLOR_RESET}"
    if has_cmd lsblk; then
        lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS 2>/dev/null || lsblk
    else
        echo -e "  ${COLOR_DIM}[N/A] lsblk not installed on minimal environment.${COLOR_RESET}"
    fi

    pause_screen
}

# Live Process Table viewer
show_live_processes() {
    show_banner "Live Process Monitor" "Inspect currently running host processes"

    echo -e "${COLOR_BOLD}Select View:${COLOR_RESET}"
    echo "  [1] Top 15 CPU Consumers"
    echo "  [2] Top 15 Memory Consumers"
    echo "  [3] Search Process by Name"
    echo "  [4] Terminate a Process (Explicit Safe Mode)"
    echo "  [0] Back"
    echo ""

    local p_choice
    read_int "Choice" p_choice 0 4 1 || return 0

    case "$p_choice" in
        1)
            show_banner "Top 15 CPU Consuming Processes"
            if has_cmd ps; then
                ps aux --sort=-%cpu 2>/dev/null | head -n 16 || ps aux | head -n 16
            else
                echo "ps utility not available."
            fi
            pause_screen
            ;;
        2)
            show_banner "Top 15 Memory Consuming Processes"
            if has_cmd ps; then
                ps aux --sort=-%mem 2>/dev/null | head -n 16 || ps aux | head -n 16
            else
                echo "ps utility not available."
            fi
            pause_screen
            ;;
        3)
            echo -ne "${COLOR_CYAN}Enter process keyword to search: ${COLOR_RESET}"
            local kw
            read -r kw
            if [[ -n "$kw" ]]; then
                show_banner "Search Results for '${kw}'"
                ps aux | grep -i "$kw" | grep -v grep | head -n 25
            fi
            pause_screen
            ;;
        4)
            # Safe termination
            echo -ne "${COLOR_YELLOW}Enter PID to terminate: ${COLOR_RESET}"
            local t_pid
            read -r t_pid
            if ! is_positive_integer "$t_pid"; then
                msg_error "Invalid PID."
                pause_screen
                return 0
            fi

            if (( t_pid == 1 )); then
                msg_error "Security Alert: Cannot terminate PID 1 (Init/Systemd)."
                pause_screen
                return 0
            fi

            if (( t_pid == $$ )); then
                msg_error "Cannot terminate current shell session (${t_pid})."
                pause_screen
                return 0
            fi

            local p_info
            p_info=$(ps -p "$t_pid" -o pid,user,args 2>/dev/null | tail -n 1)
            if [[ -z "$p_info" ]]; then
                msg_error "PID ${t_pid} not found."
                pause_screen
                return 0
            fi

            echo -e "\nTarget Process: ${COLOR_RED}${p_info}${COLOR_RESET}"
            if confirm_action "Are you ABSOLUTELY sure you want to send SIGTERM to PID ${t_pid}?"; then
                kill -15 "$t_pid" 2>/dev/null && msg_success "Sent SIGTERM to ${t_pid}." || msg_error "Failed to kill process (Insufficient permissions?)."
            else
                msg_info "Termination cancelled."
            fi
            pause_screen
            ;;
        0) return 0 ;;
    esac
}

system_monitor_menu() {
    while true; do
        show_banner "Module 5: Live System Resource Monitor" \
                    "Read-only metrics from Linux Host (/proc, ps, free, df, uptime)"

        echo -e "${COLOR_BOLD}1. Host Overview & Hardware Stats (CPU, RAM, Disks)${COLOR_RESET}"
        echo -e "${COLOR_BOLD}2. Process Inspector & Utilization Tables${COLOR_RESET}"
        echo -e "${COLOR_BOLD}0. Return to Main Menu${COLOR_RESET}"
        echo ""

        local choice
        read_int "Select option" choice 0 2 1 || return 0

        case "$choice" in
            1) show_system_overview ;;
            2) show_live_processes ;;
            0) return 0 ;;
        esac
    done
}
