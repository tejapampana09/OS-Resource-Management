#!/usr/bin/env bash
# ==============================================================================
# modules/cpu/sjf.sh - Shortest Job First (SJF) Non-preemptive Scheduling
# ==============================================================================

run_cpu_sjf() {
    local -a pids=()
    local -a arrivals=()
    local -a bursts=()
    local num_proc

    if [[ "$1" == "--preset" ]]; then
        num_proc="$2"
        # shellcheck disable=SC2206
        pids=($3)
        # shellcheck disable=SC2206
        arrivals=($4)
        # shellcheck disable=SC2206
        bursts=($5)
    else
        show_banner "CPU Scheduling - Shortest Job First (SJF)" \
                    "Non-preemptive: dispatches the available process with smallest burst"

        read_int "Enter number of processes" num_proc 1 "$MAX_PROCESSES" 3 || return 1

        echo -e "\nEnter process details (PID, Arrival Time, Burst Time):"
        for (( i=0; i<num_proc; i++ )); do
            local pid="P$(( i + 1 ))"
            local at bt
            echo -e "${COLOR_BOLD}Process ${pid}:${COLOR_RESET}"
            read_int "  Arrival Time" at 0 1000 0 || return 1
            read_int "  Burst Time  " bt 1 1000 1 || return 1
            pids+=("$pid")
            arrivals+=("$at")
            bursts+=("$bt")
        done
    fi

    local -a completed=()
    local -a ct=()
    local -a tat=()
    local -a wt=()
    local -a rt=()
    for (( i=0; i<num_proc; i++ )); do completed+=(0); done

    local current_time=0
    local completed_count=0

    local -a g_labels=()
    local -a g_starts=()
    local -a g_ends=()

    while (( completed_count < num_proc )); do
        # Find arrived process with minimum burst
        local best_idx=-1
        local min_bt=9999999

        for (( i=0; i<num_proc; i++ )); do
            if (( completed[i] == 0 && arrivals[i] <= current_time )); then
                if (( bursts[i] < min_bt )); then
                    min_bt="${bursts[i]}"
                    best_idx="$i"
                elif (( bursts[i] == min_bt )); then
                    # Tie break: earlier arrival time, then earlier index
                    if (( arrivals[i] < arrivals[best_idx] )); then
                        best_idx="$i"
                    fi
                fi
            fi
        done

        if (( best_idx == -1 )); then
            # No process available, advance to nearest arrival
            local next_arrival=9999999
            for (( i=0; i<num_proc; i++ )); do
                if (( completed[i] == 0 && arrivals[i] < next_arrival )); then
                    next_arrival="${arrivals[i]}"
                fi
            done
            g_labels+=("IDLE")
            g_starts+=("$current_time")
            g_ends+=("$next_arrival")
            current_time="$next_arrival"
            continue
        fi

        # Dispatch selected process
        local start_time="$current_time"
        rt[best_idx]=$(( start_time - arrivals[best_idx] ))
        current_time=$(( current_time + bursts[best_idx] ))
        ct[best_idx]="$current_time"
        tat[best_idx]=$(( ct[best_idx] - arrivals[best_idx] ))
        wt[best_idx]=$(( tat[best_idx] - bursts[best_idx] ))
        completed[best_idx]=1
        (( completed_count++ ))

        g_labels+=("${pids[best_idx]}")
        g_starts+=("$start_time")
        g_ends+=("$current_time")
    done

    # Averages
    local total_tat=0 total_wt=0 total_rt=0
    for (( i=0; i<num_proc; i++ )); do
        total_tat=$(( total_tat + tat[i] ))
        total_wt=$(( total_wt + wt[i] ))
        total_rt=$(( total_rt + rt[i] ))
    done

    local avg_tat avg_wt avg_rt
    avg_tat=$(awk "BEGIN {printf \"%.2f\", $total_tat / $num_proc}")
    avg_wt=$(awk "BEGIN {printf \"%.2f\", $total_wt / $num_proc}")
    avg_rt=$(awk "BEGIN {printf \"%.2f\", $total_rt / $num_proc}")

    # Output
    print_section "Execution Results (SJF Non-preemptive)"
    printf "%-8s %-12s %-10s %-16s %-16s %-14s %-14s\n" \
           "PID" "Arrival (AT)" "Burst (BT)" "Completion (CT)" "Turnaround (TAT)" "Waiting (WT)" "Response (RT)"
    print_divider 95
    for (( i=0; i<num_proc; i++ )); do
        printf "%-8s %-12s %-10s %-16s %-16s %-14s %-14s\n" \
               "${pids[i]}" "${arrivals[i]}" "${bursts[i]}" "${ct[i]}" "${tat[i]}" "${wt[i]}" "${rt[i]}"
    done
    print_divider 95
    echo -e "Average Turnaround Time (TAT): ${COLOR_GREEN}${avg_tat}${COLOR_RESET}"
    echo -e "Average Waiting Time    (WT) : ${COLOR_GREEN}${avg_wt}${COLOR_RESET}"
    echo -e "Average Response Time   (RT) : ${COLOR_GREEN}${avg_rt}${COLOR_RESET}"

    render_gantt_chart g_labels g_starts g_ends

    local input_summary=""
    for (( i=0; i<num_proc; i++ )); do
        input_summary+="${pids[i]}:AT=${arrivals[i]}:BT=${bursts[i]};"
    done
    local result_summary="avg_tat=${avg_tat};avg_wt=${avg_wt};avg_rt=${avg_rt}"

    log_simulation_csv "cpu" "SJF" "$input_summary" "$result_summary" "SJF Non-preemptive"

    if [[ "$1" != "--preset" ]]; then
        pause_screen
    fi

    export LAST_AVG_TAT="$avg_tat"
    export LAST_AVG_WT="$avg_wt"
    export LAST_AVG_RT="$avg_rt"
}
