#!/usr/bin/env bash
# ==============================================================================
# modules/cpu/srtf.sh - Shortest Remaining Time First (SRTF) Preemptive
# ==============================================================================

run_cpu_srtf() {
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
        show_banner "CPU Scheduling - Shortest Remaining Time First (SRTF)" \
                    "Preemptive algorithm: dispatches process with shortest remaining burst"

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

    local -a rem_burst=()
    local -a first_start=()
    local -a ct=()
    local -a tat=()
    local -a wt=()
    local -a rt=()

    for (( i=0; i<num_proc; i++ )); do
        rem_burst+=("${bursts[i]}")
        first_start+=(-1)
        ct+=(0)
        tat+=(0)
        wt+=(0)
        rt+=(0)
    done

    local current_time=0
    local completed_count=0
    local prev_pid=""
    local block_start=0

    local -a g_labels=()
    local -a g_starts=()
    local -a g_ends=()

    while (( completed_count < num_proc )); do
        # Find arrived process with minimum remaining burst
        local best_idx=-1
        local min_rem=9999999

        for (( i=0; i<num_proc; i++ )); do
            if (( arrivals[i] <= current_time && rem_burst[i] > 0 )); then
                if (( rem_burst[i] < min_rem )); then
                    min_rem="${rem_burst[i]}"
                    best_idx="$i"
                elif (( rem_burst[i] == min_rem )); then
                    # Tie break: earlier arrival time
                    if (( arrivals[i] < arrivals[best_idx] )); then
                        best_idx="$i"
                    fi
                fi
            fi
        done

        local current_label=""
        if (( best_idx == -1 )); then
            current_label="IDLE"
        else
            current_label="${pids[best_idx]}"
            if (( first_start[best_idx] == -1 )); then
                first_start[best_idx]="$current_time"
            fi
            (( rem_burst[best_idx]-- ))
            if (( rem_burst[best_idx] == 0 )); then
                ct[best_idx]=$(( current_time + 1 ))
                tat[best_idx]=$(( ct[best_idx] - arrivals[best_idx] ))
                wt[best_idx]=$(( tat[best_idx] - bursts[best_idx] ))
                rt[best_idx]=$(( first_start[best_idx] - arrivals[best_idx] ))
                (( completed_count++ ))
            fi
        fi

        # Gantt coalescing
        if [[ "$current_label" != "$prev_pid" ]]; then
            if [[ -n "$prev_pid" ]]; then
                g_labels+=("$prev_pid")
                g_starts+=("$block_start")
                g_ends+=("$current_time")
            fi
            prev_pid="$current_label"
            block_start="$current_time"
        fi

        (( current_time++ ))
    done

    # Final block in Gantt chart
    if [[ -n "$prev_pid" ]]; then
        g_labels+=("$prev_pid")
        g_starts+=("$block_start")
        g_ends+=("$current_time")
    fi

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
    print_section "Execution Results (SRTF Preemptive)"
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

    log_simulation_csv "cpu" "SRTF" "$input_summary" "$result_summary" "SRTF Preemptive"

    if [[ "$1" != "--preset" ]]; then
        pause_screen
    fi

    export LAST_AVG_TAT="$avg_tat"
    export LAST_AVG_WT="$avg_wt"
    export LAST_AVG_RT="$avg_rt"
}
