#!/usr/bin/env bash
# ==============================================================================
# OS RESOURCE MANAGEMENT & SIMULATION SUITE
# Main Entrypoint - Interactive Terminal Menu
# ==============================================================================

set -o pipefail

# Locate script root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" || exit 1

# Load configuration and core utility libraries
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib/input.sh"
source "${SCRIPT_DIR}/lib/display.sh"
source "${SCRIPT_DIR}/lib/report.sh"

# Load modules
source "${SCRIPT_DIR}/modules/cpu/menu.sh"
source "${SCRIPT_DIR}/modules/memory/menu.sh"
source "${SCRIPT_DIR}/modules/safety/menu.sh"
source "${SCRIPT_DIR}/modules/storage/menu.sh"
source "${SCRIPT_DIR}/modules/system_monitor.sh"

# Trap interrupt signals cleanly
trap_clean_exit() {
    echo -e "\n\n${COLOR_YELLOW}Interrupted. Exiting OS Resource Management & Simulation Suite.${COLOR_RESET}"
    exit 0
}
trap trap_clean_exit SIGINT SIGTERM

main_menu() {
    while true; do
        show_banner "Main Control Console" "Academic Operating Systems Modeling & Linux Monitoring"

        echo -e "${COLOR_BOLD}1. Process Management & CPU Scheduling${COLOR_RESET}"
        echo -e "   ${COLOR_DIM}(FCFS, Non-preemptive SJF, SRTF, Priority, Round Robin, Gantt Charts)${COLOR_RESET}"
        echo ""
        echo -e "${COLOR_BOLD}2. Memory Allocation & Virtual Memory Paging${COLOR_RESET}"
        echo -e "   ${COLOR_DIM}(First Fit, Best Fit, Worst Fit, FIFO, LRU, Optimal Page Replacement)${COLOR_RESET}"
        echo ""
        echo -e "${COLOR_BOLD}3. Deadlocks & Process Synchronization${COLOR_RESET}"
        echo -e "   ${COLOR_DIM}(Banker's Avoidance, Matrix Detection, Producer-Consumer Simulation)${COLOR_RESET}"
        echo ""
        echo -e "${COLOR_BOLD}4. Disk Head Scheduling & File Allocation${COLOR_RESET}"
        echo -e "   ${COLOR_DIM}(FCFS, SSTF, SCAN, C-SCAN, LOOK, Contiguous, Linked & Indexed Models)${COLOR_RESET}"
        echo ""
        echo -e "${COLOR_BOLD}5. Live Linux Host System Monitor${COLOR_RESET}"
        echo -e "   ${COLOR_DIM}(Read-only live inspection of CPU, Memory, Disks, and Processes)${COLOR_RESET}"
        echo ""
        echo -e "${COLOR_BOLD}6. View Saved Simulation Reports & CSV Logs${COLOR_RESET}"
        echo -e "   ${COLOR_DIM}(Browse historical runs, view comparative tables and text traces)${COLOR_RESET}"
        echo ""
        echo -e "${COLOR_BOLD}0. Exit Suite${COLOR_RESET}"
        echo ""

        local main_choice
        read_int "Enter your selection" main_choice 0 6 1 || break

        case "$main_choice" in
            1) cpu_menu ;;
            2) memory_menu ;;
            3) safety_menu ;;
            4) storage_menu ;;
            5) system_monitor_menu ;;
            6) view_saved_reports ;;
            0)
                echo -e "\n${COLOR_GREEN}Thank you for using OS Resource Management & Simulation Suite!${COLOR_RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run main menu
main_menu
