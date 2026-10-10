#!/usr/bin/env bash
# ==============================================================================
# modules/cpu/round_robin.sh - Round Robin (RR) CPU Scheduling
# ==============================================================================

run_cpu_round_robin() {
    local -a pids=()
    local -a arrivals=()
    local -a bursts=()
    local num_proc quantum

    if [[ "$1" == "--preset" ]]; then
        num_proc="$2"
        # shellcheck disable=SC2206
        pids=($3)
        # shellcheck disable=SC2206
        arrivals=($4)
        # shellcheck disable=SC2206
        bursts=($5)
        quantum="$6"
    else
        show_banner "CPU Scheduling - Round Robin (RR)" \
                    "Preemptive time-sliced scheduling using a FIFO ready queue"

        read_int "Enter number of processes" num_proc 1 "$MAX_PROCESSES" 3 || return 1
        read_int "Enter Time Quantum" quantum 1 100 2 || return 1

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
    local -a in_queue=()
    local -a ct=() tat=() wt=() rt=()

    for (( i=0; i<num_proc; i++ )); do
        rem_burst+=("${bursts[i]}")
        first_start+=(-1)
        in_queue+=(0)
        ct+=(0); tat+=(0); wt+=(0); rt+=(0)
    done

    # Sort initial arrivals to manage arrival events
    local -a ready_queue=()
    local current_time=0
    local completed_count=0

    local -a g_labels=()
    local -a g_starts=()
    local -a g_ends=()

    # Function to enqueue all arrived processes up to current_time
    enqueue_arrivals() {
        local up_to="$1"
        for (( i=0; i<num_proc; i++ )); do
            if (( arrivals[i] <= up_to && in_queue[i] == 0 && rem_burst[i] > 0 )); then
                ready_queue+=("$i")
                in_queue[i]=1
            fi
        done
    }

    # Initial enqueue at time 0
    enqueue_arrivals "$current_time"

    while (( completed_count < num_proc )); do
        if (( ${#ready_queue[@]} == 0 )); then
            # Queue empty: find nearest arrival
            local next_arrival=9999999
            for (( i=0; i<num_proc; i++ )); do
                if (( rem_burst[i] > 0 && arrivals[i] < next_arrival )); then
                    next_arrival="${arrivals[i]}"
                fi
            done
            g_labels+=("IDLE")
            g_starts+=("$current_time")
            g_ends+=("$next_arrival")
            current_time="$next_arrival"
            enqueue_arrivals "$current_time"
            continue
        fi

        # Pop from ready queue
        local curr_idx="${ready_queue[0]}"
        ready_queue=("${ready_queue[@]:1}")

        if (( first_start[curr_idx] == -1 )); then
            first_start[curr_idx]="$current_time"
        fi

        local slice=$quantum
        if (( rem_burst[curr_idx] < quantum )); then
            slice="${rem_burst[curr_idx]}"
        fi

        local start_time="$current_time"
        current_time=$(( current_time + slice ))
        rem_burst[curr_idx]=$(( rem_burst[curr_idx] - slice ))

        g_labels+=("${pids[curr_idx]}")
        g_starts+=("$start_time")
        g_ends+=("$current_time")

        # Crucial edge case: new arrivals during this slice (up to current_time)
        # must enter ready queue BEFORE the current process is requeued!
        enqueue_arrivals "$current_time"

        if (( rem_burst[curr_idx] == 0 )); then
            ct[curr_idx]="$current_time"
            tat[curr_idx]=$(( ct[curr_idx] - arrivals[curr_idx] ))
            wt[curr_idx]=$(( tat[curr_idx] - bursts[curr_idx] ))
            rt[curr_idx]=$(( first_start[curr_idx] - arrivals[curr_idx] ))
            (( completed_count++ ))
        else
            # Re-enqueue
            ready_queue+=("$curr_idx")
        fi
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
    print_section "Execution Results (Round Robin, Quantum=${quantum})"
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
    local result_summary="quantum=${quantum};avg_tat=${avg_tat};avg_wt=${avg_wt};avg_rt=${avg_rt}"

    log_simulation_csv "cpu" "RoundRobin" "$input_summary" "$result_summary" "RR Quantum ${quantum}"

    if [[ "$1" != "--preset" ]]; then
        pause_screen
    fi

    export LAST_AVG_TAT="$avg_tat"
    export LAST_AVG_WT="$avg_wt"
    export LAST_AVG_RT="$avg_rt"
}
