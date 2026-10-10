#!/usr/bin/env bash
# ==============================================================================
# modules/storage/menu.sh - Disk Scheduling & File Allocation Module Menu
# ==============================================================================

source "${OS_SIM_ROOT}/modules/storage/disk.sh"
source "${OS_SIM_ROOT}/modules/storage/file_allocation.sh"

# Initialize disk block pool on module load
init_file_system

load_storage_preset_demo() {
    show_banner "Disk Scheduling Standard Preset" \
                "Silberschatz Example: Head=50, Direction=Up, Cylinders=0..199"
    echo "Request Queue: 98 183 37 122 14 124 65 67"
    run_disk_algorithm "scan" 50 199 "up" "98 183 37 122 14 124 65 67" false
    pause_screen
}

storage_menu() {
    while true; do
        show_banner "Module 4: Disk Scheduling & File Allocation" \
                    "Owner: Member 4 | FCFS, SSTF, SCAN, C-SCAN, LOOK & File Allocations"

        echo -e "${COLOR_BOLD}--- Disk Head Scheduling ---${COLOR_RESET}"
        echo -e "  [1] First-Come First-Served (FCFS)"
        echo -e "  [2] Shortest Seek Time First (SSTF)"
        echo -e "  [3] SCAN (Elevator Algorithm)"
        echo -e "  [4] Circular SCAN (C-SCAN)"
        echo -e "  [5] LOOK Scheduling"
        echo -e "  [6] Compare All 5 Disk Algorithms on Same Queue"
        echo ""
        echo -e "${COLOR_BOLD}--- File Allocation Simulation ---${COLOR_RESET}"
        echo -e "  [7] Allocate File (Contiguous Allocation)"
        echo -e "  [8] Allocate File (Linked Allocation)"
        echo -e "  [9] Allocate File (Indexed Allocation)"
        echo -e "  [10] View Simulated Disk Map & Directory"
        echo ""
        echo -e "${COLOR_BOLD}--- Presets ---${COLOR_RESET}"
        echo -e "  [11] Quick Run Standard Disk Preset (SCAN on 50)"
        echo -e "  [0] Return to Main Menu"
        echo ""

        local choice
        read_int "Select option" choice 0 11 1 || return 0

        case "$choice" in
            1) run_disk_interactive "fcfs" ;;
            2) run_disk_interactive "sstf" ;;
            3) run_disk_interactive "scan" ;;
            4) run_disk_interactive "c-scan" ;;
            5) run_disk_interactive "look" ;;
            6) run_disk_comparative_benchmark ;;
            7) run_contiguous_allocation_demo ;;
            8) run_linked_allocation_demo ;;
            9) run_indexed_allocation_demo ;;
            10) list_and_delete_files ;;
            11) load_storage_preset_demo ;;
            0) return 0 ;;
        esac
    done
}
