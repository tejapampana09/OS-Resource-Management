#!/usr/bin/env bash
# ==============================================================================
# modules/cpu/priority.sh - Priority CPU Scheduling (Non-preemptive & Preemptive)
# ==============================================================================

run_cpu_priority() {
    local -a pids=()
    local -a arrivals=()
    local -a bursts=()
    local -a priorities=()
    local num_proc
    local mode="non-preemptive" # non-preemptive or preemptive

    if [[ "$1" == "--preset" ]]; then
        num_proc="$2"
        # shellcheck disable=SC2206
        pids=($3)
        # shellcheck disable=SC2206
        arrivals=($4)
        # shellcheck disable=SC2206
        bursts=($5)
        # shellcheck disable=SC2206
        priorities=($6)
        mode="${7:-non-preemptive}"
    else
        show_banner "CPU Scheduling - Priority Scheduling" \
                    "Convention: Lower integer represents HIGHER priority (e.g. 1 > 5)"

        read_int "Enter number of processes" num_proc 1 "$MAX_PROCESSES" 3 || return 1

        echo -e "\nSelect Mode:"
        echo "  [1] Non-preemptive Priority"
        echo "  [2] Preemptive Priority"
        local mode_sel
        read_int "Choice" mode_sel 1 2 1
        if (( mode_sel == 2 )); then mode="preemptive"; fi

        echo -e "\nEnter process details (PID, Arrival, Burst, Priority):"
        for (( i=0; i<num_proc; i++ )); do
            local pid="P$(( i + 1 ))"
            local at bt pr
            echo -e "${COLOR_BOLD}Process ${pid}:${COLOR_RESET}"
            read_int "  Arrival Time" at 0 1000 0 || return 1
            read_int "  Burst Time  " bt 1 1000 1 || return 1
            read_int "  Priority (1=high)" pr 1 1000 1 || return 1
            pids+=("$pid")
            arrivals+=("$at")
            bursts+=("$bt")
            priorities+=("$pr")
        done
    fi

    local -a ct=() tat=() wt=() rt=()
    local -a g_labels=() g_starts=() g_ends=()

    if [[ "$mode" == "non-preemptive" ]]; then
        local -a completed=()
        for (( i=0; i<num_proc; i++ )); do completed+=(0); done
        local current_time=0
        local completed_count=0

        while (( completed_count < num_proc )); do
            local best_idx=-1
            local best_prio=9999999

            for (( i=0; i<num_proc; i++ )); do
                if (( completed[i] == 0 && arrivals[i] <= current_time )); then
                    if (( priorities[i] < best_prio )); then
                        best_prio="${priorities[i]}"
                        best_idx="$i"
                    elif (( priorities[i] == best_prio )); then
                        # Tie break: earlier arrival time
                        if (( arrivals[i] < arrivals[best_idx] )); then
                            best_idx="$i"
                        fi
                    fi
                fi
            done

            if (( best_idx == -1 )); then
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
    else
        # Preemptive mode
        local -a rem_burst=()
        local -a first_start=()
        for (( i=0; i<num_proc; i++ )); do
            rem_burst+=("${bursts[i]}")
            first_start+=(-1)
            ct+=(0); tat+=(0); wt+=(0); rt+=(0)
        done

        local current_time=0
        local completed_count=0
        local prev_pid=""
        local block_start=0

        while (( completed_count < num_proc )); do
            local best_idx=-1
            local best_prio=9999999

            for (( i=0; i<num_proc; i++ )); do
                if (( arrivals[i] <= current_time && rem_burst[i] > 0 )); then
                    if (( priorities[i] < best_prio )); then
                        best_prio="${priorities[i]}"
                        best_idx="$i"
                    elif (( priorities[i] == best_prio )); then
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

        if [[ -n "$prev_pid" ]]; then
            g_labels+=("$prev_pid")
            g_starts+=("$block_start")
            g_ends+=("$current_time")
        fi
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
    print_section "Execution Results (Priority ${mode^})"
    printf "%-8s %-12s %-10s %-10s %-16s %-16s %-14s %-14s\n" \
           "PID" "Arrival" "Burst" "Priority" "Completion (CT)" "Turnaround (TAT)" "Waiting (WT)" "Response (RT)"
    print_divider 105
    for (( i=0; i<num_proc; i++ )); do
        printf "%-8s %-12s %-10s %-10s %-16s %-16s %-14s %-14s\n" \
               "${pids[i]}" "${arrivals[i]}" "${bursts[i]}" "${priorities[i]}" "${ct[i]}" "${tat[i]}" "${wt[i]}" "${rt[i]}"
    done
    print_divider 105
    echo -e "Average Turnaround Time (TAT): ${COLOR_GREEN}${avg_tat}${COLOR_RESET}"
    echo -e "Average Waiting Time    (WT) : ${COLOR_GREEN}${avg_wt}${COLOR_RESET}"
    echo -e "Average Response Time   (RT) : ${COLOR_GREEN}${avg_rt}${COLOR_RESET}"

    render_gantt_chart g_labels g_starts g_ends

    local input_summary=""
    for (( i=0; i<num_proc; i++ )); do
        input_summary+="${pids[i]}:AT=${arrivals[i]}:BT=${bursts[i]}:PR=${priorities[i]};"
    done
    local result_summary="mode=${mode};avg_tat=${avg_tat};avg_wt=${avg_wt};avg_rt=${avg_rt}"

    log_simulation_csv "cpu" "Priority" "$input_summary" "$result_summary" "Priority ${mode}"

    if [[ "$1" != "--preset" ]]; then
        pause_screen
    fi

    export LAST_AVG_TAT="$avg_tat"
    export LAST_AVG_WT="$avg_wt"
    export LAST_AVG_RT="$avg_rt"
}
