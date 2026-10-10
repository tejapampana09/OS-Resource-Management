#!/usr/bin/env bash
# ==============================================================================
# modules/safety/menu.sh - Deadlocks & Synchronization Module Menu
# ==============================================================================

source "${OS_SIM_ROOT}/modules/safety/banker.sh"
source "${OS_SIM_ROOT}/modules/safety/deadlock.sh"
source "${OS_SIM_ROOT}/modules/safety/synchronization.sh"

safety_menu() {
    while true; do
        show_banner "Module 3: Deadlocks & Synchronization" \
                    "Owner: Member 3 | Banker's Algorithm, Deadlock Detection, Producer-Consumer"

        echo -e "${COLOR_BOLD}--- Deadlock Avoidance (Banker's Algorithm) ---${COLOR_RESET}"
        echo -e "  [1] Run Banker's Algorithm (Interactive Input)"
        echo -e "  [2] Quick Run Known SAFE Preset (Silberschatz Example)"
        echo -e "  [3] Quick Run Known UNSAFE Preset"
        echo ""
        echo -e "${COLOR_BOLD}--- Deadlock Detection ---${COLOR_RESET}"
        echo -e "  [4] Run Deadlock Detection Routine (Interactive Input)"
        echo -e "  [5] Quick Run Preset: Deadlocked State"
        echo -e "  [6] Quick Run Preset: No Deadlock State"
        echo ""
        echo -e "${COLOR_BOLD}--- Process Synchronization ---${COLOR_RESET}"
        echo -e "  [7] Producer-Consumer Bounded-Buffer Simulation & Coffman Conditions"
        echo ""
        echo -e "  [0] Return to Main Menu"
        echo ""

        local choice
        read_int "Select option" choice 0 7 1 || return 0

        case "$choice" in
            1) run_bankers_algorithm "false" ;;
            2) run_bankers_algorithm "safe" ;;
            3) run_bankers_algorithm "unsafe" ;;
            4) run_deadlock_detection "false" ;;
            5) run_deadlock_detection "deadlocked" ;;
            6) run_deadlock_detection "nodeadlock" ;;
            7) run_synchronization_demo ;;
            0) return 0 ;;
        esac
    done
}
