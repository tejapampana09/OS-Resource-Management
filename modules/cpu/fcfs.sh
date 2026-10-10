#!/usr/bin/env bash
# ==============================================================================
# modules/cpu/fcfs.sh - First-Come First-Served (FCFS) CPU Scheduling
# ==============================================================================

run_cpu_fcfs() {
    local -a pids=()
    local -a arrivals=()
    local -a bursts=()
    local num_proc

    if [[ "$1" == "--preset" ]]; then
        # Automated / preset mode
        # $2: num_proc, $3: "P1 P2 P3", $4: "0 1 2", $5: "5 3 8"
        num_proc="$2"
        # shellcheck disable=SC2206
        pids=($3)
        # shellcheck disable=SC2206
        arrivals=($4)
        # shellcheck disable=SC2206
        bursts=($5)
    else
        show_banner "CPU Scheduling - First-Come First-Served (FCFS)" \
                    "Non-preemptive algorithm executing in order of arrival"

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

    # Sort indices by arrival time, with original index as tie breaker
    local -a order=()
    for (( i=0; i<num_proc; i++ )); do order+=("$i"); done

    for (( i=0; i<num_proc-1; i++ )); do
        for (( j=0; j<num_proc-i-1; j++ )); do
            local idx1="${order[j]}"
            local idx2="${order[j+1]}"
            if (( arrivals[idx1] > arrivals[idx2] )) || \
               { (( arrivals[idx1] == arrivals[idx2] )) && (( idx1 > idx2 )); }; then
                order[j]="$idx2"
                order[j+1]="$idx1"
            fi
        done
    done

    # Simulation state
    local current_time=0
    local -a ct=()
    local -a tat=()
    local -a wt=()
    local -a rt=()

    # Timeline blocks for Gantt chart
    local -a g_labels=()
    local -a g_starts=()
    local -a g_ends=()

    for idx in "${order[@]}"; do
        local pid="${pids[idx]}"
        local at="${arrivals[idx]}"
        local bt="${bursts[idx]}"

        # Handle CPU idle period
        if (( current_time < at )); then
            g_labels+=("IDLE")
            g_starts+=("$current_time")
            g_ends+=("$at")
            current_time="$at"
        fi

        local start_time="$current_time"
        rt[idx]=$(( start_time - at ))
        current_time=$(( current_time + bt ))
        ct[idx]="$current_time"
        tat[idx]=$(( ct[idx] - at ))
        wt[idx]=$(( tat[idx] - bt ))

        g_labels+=("$pid")
        g_starts+=("$start_time")
        g_ends+=("$current_time")
    done

    # Compute averages
    local total_tat=0
    local total_wt=0
    local total_rt=0
    for (( i=0; i<num_proc; i++ )); do
        total_tat=$(( total_tat + tat[i] ))
        total_wt=$(( total_wt + wt[i] ))
        total_rt=$(( total_rt + rt[i] ))
    done

    local avg_tat avg_wt avg_rt
    avg_tat=$(awk "BEGIN {printf \"%.2f\", $total_tat / $num_proc}")
    avg_wt=$(awk "BEGIN {printf \"%.2f\", $total_wt / $num_proc}")
    avg_rt=$(awk "BEGIN {printf \"%.2f\", $total_rt / $num_proc}")

    # Display results
    print_section "Execution Results (FCFS)"
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

    # Render Gantt Chart
    render_gantt_chart g_labels g_starts g_ends

    # Prepare inputs & results summary for logging
    local input_summary=""
    for (( i=0; i<num_proc; i++ )); do
        input_summary+="${pids[i]}:AT=${arrivals[i]}:BT=${bursts[i]};"
    done
    local result_summary="avg_tat=${avg_tat};avg_wt=${avg_wt};avg_rt=${avg_rt}"

    # Trace text
    local trace_output="FCFS Execution Trace\n"
    trace_output+="Inputs: ${input_summary}\n"
    trace_output+="Results: ${result_summary}\n\nTimeline:\n"
    for (( i=0; i<${#g_labels[@]}; i++ )); do
        trace_output+="[${g_starts[i]} -> ${g_ends[i]}] : ${g_labels[i]}\n"
    done

    log_simulation_csv "cpu" "FCFS" "$input_summary" "$result_summary" "FCFS run"
    save_detailed_trace "cpu" "FCFS" "$trace_output"

    if [[ "$1" != "--preset" ]]; then
        pause_screen
    fi

    # Return exported metrics for comparison if needed
    export LAST_AVG_TAT="$avg_tat"
    export LAST_AVG_WT="$avg_wt"
    export LAST_AVG_RT="$avg_rt"
}
