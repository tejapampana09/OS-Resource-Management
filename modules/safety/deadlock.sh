#!/usr/bin/env bash
# ==============================================================================
# modules/safety/deadlock.sh - Deadlock Detection for Multiple Resource Instances
# ==============================================================================

run_deadlock_detection() {
    local is_preset="${1:-false}"
    local num_p num_r
    local -a alloc=()
    local -a request=()
    local -a avail=()

    if [[ "$is_preset" == "deadlocked" ]]; then
        # Silberschatz Example: P2 requests [0 0 1], leading to circular deadlock for P1, P2, P3, P4
        num_p=5; num_r=3
        avail=(0 0 0)
        alloc=(0 1 0  2 0 0  3 0 3  2 1 1  0 0 2)
        request=(0 0 0  2 0 2  0 0 1  1 0 0  0 0 2)
    elif [[ "$is_preset" == "nodeadlock" ]]; then
        num_p=5; num_r=3
        avail=(0 0 0)
        alloc=(0 1 0  2 0 0  3 0 3  2 1 1  0 0 2)
        request=(0 0 0  2 0 2  0 0 0  1 0 0  0 0 0)
    else
        show_banner "Deadlock Detection" \
                    "Multiple-instance resource model using Allocation & Request matrices"

        read_int "Enter number of processes" num_p 1 "$MAX_PROCESSES" 5 || return 1
        read_int "Enter number of resource types" num_r 1 10 3 || return 1

        echo -e "\nEnter Available Vector (${num_r} values):"
        for (( j=0; j<num_r; j++ )); do
            local val
            read_int "  Available R$(( j + 1 ))" val 0 1000 0 || return 1
            avail+=("$val")
        done

        echo -e "\nEnter Allocation Matrix (${num_p} x ${num_r}):"
        for (( i=0; i<num_p; i++ )); do
            echo "  Process P$(( i + 1 )) Allocation:"
            for (( j=0; j<num_r; j++ )); do
                local val
                read_int "    R$(( j + 1 ))" val 0 1000 0 || return 1
                alloc+=("$val")
            done
        done

        echo -e "\nEnter Current Request Matrix (${num_p} x ${num_r}):"
        for (( i=0; i<num_p; i++ )); do
            echo "  Process P$(( i + 1 )) Request:"
            for (( j=0; j<num_r; j++ )); do
                local val
                read_int "    R$(( j + 1 ))" val 0 1000 0 || return 1
                request+=("$val")
            done
        done
    fi

    # Display inputs
    print_section "Current Resource & Request Status"
    echo -ne "PID       | "
    echo -ne "Allocation       | "
    echo -e "Request Matrix"
    print_divider 50
    for (( i=0; i<num_p; i++ )); do
        printf "P%-8s | " "$(( i + 1 ))"
        for (( j=0; j<num_r; j++ )); do printf "%-2s " "${alloc[i*num_r + j]}"; done
        printf "%*s| " "$(( 17 - num_r * 3 ))" ""
        for (( j=0; j<num_r; j++ )); do printf "%-2s " "${request[i*num_r + j]}"; done
        echo ""
    done
    print_divider 50
    echo -ne "Available: [ "
    for (( j=0; j<num_r; j++ )); do echo -ne "R$(( j + 1 ))=${avail[j]} "; done
    echo -e "]\n"

    # Detection algorithm
    local -a work=("${avail[@]}")
    local -a finish=()

    # Step 1: If Allocation[i] != 0, Finish[i] = false; else Finish[i] = true
    for (( i=0; i<num_p; i++ )); do
        local has_alloc=false
        for (( j=0; j<num_r; j++ )); do
            if (( alloc[i*num_r + j] > 0 )); then
                has_alloc=true
                break
            fi
        done
        if $has_alloc; then
            finish+=(0)
        else
            finish+=(1)
        fi
    done

    # Step 2: Loop to find process with Finish[i] == false and Request[i] <= Work
    local changed=true
    local progress_trace=""

    while $changed; do
        changed=false
        for (( i=0; i<num_p; i++ )); do
            if (( finish[i] == 0 )); then
                local can_grant=true
                for (( j=0; j<num_r; j++ )); do
                    if (( request[i*num_r + j] > work[j] )); then
                        can_grant=false
                        break
                    fi
                done

                if $can_grant; then
                    # Process executes and releases resources
                    progress_trace+="Process P$(( i + 1 )) request granted. Releasing Allocation. Work: "
                    for (( j=0; j<num_r; j++ )); do
                        work[j]=$(( work[j] + alloc[i*num_r + j] ))
                    done
                    finish[i]=1
                    changed=true
                    progress_trace+="[${work[*]}]\n"
                fi
            fi
        done
    done

    # Step 3: Check for unfinished processes
    print_section "Deadlock Detection Results"
    echo -e "${progress_trace}"

    local -a deadlocked=()
    for (( i=0; i<num_p; i++ )); do
        if (( finish[i] == 0 )); then
            deadlocked+=("P$(( i + 1 ))")
        fi
    done

    if (( ${#deadlocked[@]} == 0 )); then
        echo -e "${COLOR_GREEN}${COLOR_BOLD}[NO DEADLOCK DETECTED]${COLOR_RESET} All processes can proceed to completion."
        log_simulation_csv "safety" "Deadlock_Detection" "P=${num_p};R=${num_r}" "Status=NO_DEADLOCK" "Detection run"
    else
        echo -e "${COLOR_RED}${COLOR_BOLD}[DEADLOCK DETECTED!]${COLOR_RESET} The system is deadlocked."
        echo -e "${COLOR_YELLOW}Deadlocked Processes:${COLOR_RESET} ${COLOR_RED}${deadlocked[*]}${COLOR_RESET}"
        echo -e "\n${COLOR_DIM}Explanation: The deadlocked processes are waiting for resources held by each other in a circular dependency.${COLOR_RESET}"
        log_simulation_csv "safety" "Deadlock_Detection" "P=${num_p};R=${num_r}" "Status=DEADLOCKED;Procs=${deadlocked[*]}" "Deadlock confirmed"
    fi

    if [[ "$is_preset" == "false" ]]; then
        pause_screen
    fi
}
