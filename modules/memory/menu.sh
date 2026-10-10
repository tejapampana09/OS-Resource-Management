#!/usr/bin/env bash
# ==============================================================================
# modules/memory/menu.sh - Memory Management & Virtual Memory Module Menu
# ==============================================================================

source "${OS_SIM_ROOT}/modules/memory/allocation.sh"
source "${OS_SIM_ROOT}/modules/memory/paging.sh"

load_memory_preset_demo() {
    show_banner "Memory Module Preset Demo" "Testing standard textbook examples"
    echo -e "${COLOR_BOLD}1. Running Contiguous Allocation Preset:${COLOR_RESET}"
    echo "   Blocks: [100, 500, 200, 300, 600] KB"
    echo "   Processes: P1(212 KB), P2(417 KB), P3(112 KB), P4(426 KB)"
    export -a PRESET_BLOCKS=(100 500 200 300 600)
    export -a PRESET_PROCS=(212 417 112 426)
    run_memory_allocation_sim "first_fit" "fixed" "true"

    echo -e "\n${COLOR_BOLD}2. Running Page Replacement Preset:${COLOR_RESET}"
    echo "   Reference String: 7 0 1 2 0 3 0 4 2 3 0 3 2 1 2 0 1 7 0 1"
    echo "   Frames: 3"
    run_page_replacement "fifo" 3 "7 0 1 2 0 3 0 4 2 3 0 3 2 1 2 0 1 7 0 1" false

    pause_screen
}

memory_menu() {
    while true; do
        show_banner "Module 2: Memory Management & Virtual Memory" \
                    "Owner: Member 2 | First/Best/Worst Fit, FIFO/LRU/Optimal Paging"

        echo -e "${COLOR_BOLD}--- Contiguous Allocation ---${COLOR_RESET}"
        echo -e "  [1] First Fit Allocation"
        echo -e "  [2] Best Fit Allocation"
        echo -e "  [3] Worst Fit Allocation"
        echo -e "  [4] Compare All 3 Allocation Strategies"
        echo ""
        echo -e "${COLOR_BOLD}--- Virtual Memory Page Replacement ---${COLOR_RESET}"
        echo -e "  [5] FIFO Page Replacement"
        echo -e "  [6] LRU Page Replacement"
        echo -e "  [7] Optimal Page Replacement"
        echo -e "  [8] Compare FIFO, LRU, Optimal on Same Workload"
        echo ""
        echo -e "${COLOR_BOLD}--- Presets ---${COLOR_RESET}"
        echo -e "  [9] Quick Run Standard Textbook Presets"
        echo -e "  [0] Return to Main Menu"
        echo ""

        local choice
        read_int "Select option" choice 0 9 1 || return 0

        case "$choice" in
            1)
                local m="fixed"
                if confirm_action "Use Variable Partitioning? (Default: Fixed)"; then m="variable"; fi
                run_memory_allocation_sim "first_fit" "$m" "false"
                ;;
            2)
                local m="fixed"
                if confirm_action "Use Variable Partitioning? (Default: Fixed)"; then m="variable"; fi
                run_memory_allocation_sim "best_fit" "$m" "false"
                ;;
            3)
                local m="fixed"
                if confirm_action "Use Variable Partitioning? (Default: Fixed)"; then m="variable"; fi
                run_memory_allocation_sim "worst_fit" "$m" "false"
                ;;
            4) run_memory_allocation_comparison ;;
            5) run_paging_interactive "fifo" ;;
            6) run_paging_interactive "lru" ;;
            7) run_paging_interactive "optimal" ;;
            8) run_paging_comparative_benchmark ;;
            9) load_memory_preset_demo ;;
            0) return 0 ;;
        esac
    done
}
