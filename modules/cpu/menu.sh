#!/usr/bin/env bash
# ==============================================================================
# modules/cpu/menu.sh - CPU Scheduling Module Menu & Comparative Benchmark
# ==============================================================================

# Source algorithms
source "${OS_SIM_ROOT}/modules/cpu/fcfs.sh"
source "${OS_SIM_ROOT}/modules/cpu/sjf.sh"
source "${OS_SIM_ROOT}/modules/cpu/srtf.sh"
source "${OS_SIM_ROOT}/modules/cpu/priority.sh"
source "${OS_SIM_ROOT}/modules/cpu/round_robin.sh"

run_cpu_comparative_benchmark() {
    show_banner "CPU Comparative Benchmark" \
                "Run FCFS, SJF, SRTF, and Round Robin on the identical workload"

    local num_proc quantum
    read_int "Enter number of processes" num_proc 1 "$MAX_PROCESSES" 4 || return 1
    read_int "Enter Round Robin Quantum" quantum 1 50 2 || return 1

    local -a pids=() arrivals=() bursts=() priorities=()
    echo -e "\nEnter process details:"
    for (( i=0; i<num_proc; i++ )); do
        local pid="P$(( i + 1 ))"
        local at bt pr
        echo -e "${COLOR_BOLD}Process ${pid}:${COLOR_RESET}"
        read_int "  Arrival Time" at 0 1000 0 || return 1
        read_int "  Burst Time  " bt 1 1000 1 || return 1
        read_int "  Priority (1=high)" pr 1 1000 "$(( i + 1 ))" || return 1
        pids+=("$pid")
        arrivals+=("$at")
        bursts+=("$bt")
        priorities+=("$pr")
    done

    local pids_str="${pids[*]}"
    local at_str="${arrivals[*]}"
    local bt_str="${bursts[*]}"
    local pr_str="${priorities[*]}"

    # Run FCFS
    run_cpu_fcfs "--preset" "$num_proc" "$pids_str" "$at_str" "$bt_str" > /dev/null
    local fcfs_tat="$LAST_AVG_TAT" fcfs_wt="$LAST_AVG_WT" fcfs_rt="$LAST_AVG_RT"

    # Run SJF
    run_cpu_sjf "--preset" "$num_proc" "$pids_str" "$at_str" "$bt_str" > /dev/null
    local sjf_tat="$LAST_AVG_TAT" sjf_wt="$LAST_AVG_WT" sjf_rt="$LAST_AVG_RT"

    # Run SRTF
    run_cpu_srtf "--preset" "$num_proc" "$pids_str" "$at_str" "$bt_str" > /dev/null
    local srtf_tat="$LAST_AVG_TAT" srtf_wt="$LAST_AVG_WT" srtf_rt="$LAST_AVG_RT"

    # Run Priority Non-preemptive
    run_cpu_priority "--preset" "$num_proc" "$pids_str" "$at_str" "$bt_str" "$pr_str" "non-preemptive" > /dev/null
    local prio_tat="$LAST_AVG_TAT" prio_wt="$LAST_AVG_WT" prio_rt="$LAST_AVG_RT"

    # Run Round Robin
    run_cpu_round_robin "--preset" "$num_proc" "$pids_str" "$at_str" "$bt_str" "$quantum" > /dev/null
    local rr_tat="$LAST_AVG_TAT" rr_wt="$LAST_AVG_WT" rr_rt="$LAST_AVG_RT"

    show_banner "Comparative CPU Benchmark Summary" "Direct side-by-side performance comparison"
    printf "%-25s %-18s %-18s %-18s\n" "Algorithm" "Avg Turnaround (TAT)" "Avg Waiting (WT)" "Avg Response (RT)"
    print_divider 85
    printf "%-25s %-18s %-18s %-18s\n" "FCFS" "$fcfs_tat" "$fcfs_wt" "$fcfs_rt"
    printf "%-25s %-18s %-18s %-18s\n" "SJF (Non-preemptive)" "$sjf_tat" "$sjf_wt" "$sjf_rt"
    printf "%-25s %-18s %-18s %-18s\n" "SRTF (Preemptive SJF)" "$srtf_tat" "$srtf_wt" "$srtf_rt"
    printf "%-25s %-18s %-18s %-18s\n" "Priority (Non-preempt)" "$prio_tat" "$prio_wt" "$prio_rt"
    printf "%-25s %-18s %-18s %-18s\n" "Round Robin (Q=${quantum})" "$rr_tat" "$rr_wt" "$rr_rt"
    print_divider 85

    msg_info "Observation: SRTF/SJF minimizes average waiting time when burst times vary."
    pause_screen
}

load_cpu_preset_demo() {
    show_banner "CPU Preset Demo (Silberschatz Standard Example)"
    echo "Running FCFS on Preset: P1(AT=0, BT=5), P2(AT=1, BT=3), P3(AT=2, BT=8), P4(AT=3, BT=6)"
    run_cpu_fcfs "--preset" 4 "P1 P2 P3 P4" "0 1 2 3" "5 3 8 6"
    pause_screen
}

cpu_menu() {
    while true; do
        show_banner "Module 1: Process Management & CPU Scheduling" \
                    "Owner: Member 1 | FCFS, SJF, SRTF, Priority, Round Robin"

        echo -e "${COLOR_BOLD}1. First-Come First-Served (FCFS)${COLOR_RESET}"
        echo -e "${COLOR_BOLD}2. Shortest Job First (SJF - Non-preemptive)${COLOR_RESET}"
        echo -e "${COLOR_BOLD}3. Shortest Remaining Time First (SRTF - Preemptive)${COLOR_RESET}"
        echo -e "${COLOR_BOLD}4. Priority Scheduling (Non-preemptive & Preemptive)${COLOR_RESET}"
        echo -e "${COLOR_BOLD}5. Round Robin (RR)${COLOR_RESET}"
        echo -e "${COLOR_BOLD}6. Run Side-by-Side Comparative Benchmark${COLOR_RESET}"
        echo -e "${COLOR_BOLD}7. Quick Run Textbook Preset Example${COLOR_RESET}"
        echo -e "${COLOR_BOLD}0. Return to Main Menu${COLOR_RESET}"
        echo ""

        local choice
        read_int "Select algorithm" choice 0 7 1 || return 0

        case "$choice" in
            1) run_cpu_fcfs ;;
            2) run_cpu_sjf ;;
            3) run_cpu_srtf ;;
            4) run_cpu_priority ;;
            5) run_cpu_round_robin ;;
            6) run_cpu_comparative_benchmark ;;
            7) load_cpu_preset_demo ;;
            0) return 0 ;;
        esac
    done
}
