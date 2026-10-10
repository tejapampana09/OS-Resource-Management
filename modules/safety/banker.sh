#!/usr/bin/env bash
# ==============================================================================
# modules/safety/banker.sh - Banker's Safety and Resource Request Algorithm
# ==============================================================================

# Parse and run Banker's safety check
# Expects matrices as flattened arrays or user prompts
run_bankers_algorithm() {
    local is_preset="${1:-false}"
    local num_p num_r
    local -a alloc=()
    local -a max=()
    local -a avail=()

    if [[ "$is_preset" == "safe" ]]; then
        # Standard textbook safe state: 5 processes, 3 resource types (A, B, C)
        num_p=5; num_r=3
        # Allocation matrix (5x3)
        alloc=(0 1 0  2 0 0  3 0 2  2 1 1  0 0 2)
        # Max matrix (5x3)
        max=(7 5 3  3 2 2  9 0 2  2 2 2  4 3 3)
        # Available vector (3)
        avail=(3 3 2)
    elif [[ "$is_preset" == "unsafe" ]]; then
        # Known unsafe state
        num_p=4; num_r=3
        alloc=(2 0 0  1 1 2  2 1 1  0 0 2)
        max=(3 2 2  2 2 2  4 3 3  1 1 2)
        avail=(0 0 0)
    else
        show_banner "Deadlock Avoidance - Banker's Safety Algorithm" \
                    "Calculates Need matrix, Work vector, and safe execution sequence"

        read_int "Enter number of processes" num_p 1 "$MAX_PROCESSES" 5 || return 1
        read_int "Enter number of resource types" num_r 1 10 3 || return 1

        echo -e "\nEnter Available Resource Vector (${num_r} values):"
        for (( j=0; j<num_r; j++ )); do
            local val
            read_int "  Available R$(( j + 1 ))" val 0 1000 3 || return 1
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

        echo -e "\nEnter Max Demand Matrix (${num_p} x ${num_r}):"
        for (( i=0; i<num_p; i++ )); do
            echo "  Process P$(( i + 1 )) Max Demand:"
            for (( j=0; j<num_r; j++ )); do
                local val
                local a_idx=$(( i * num_r + j ))
                read_int "    R$(( j + 1 ))" val "${alloc[a_idx]}" 1000 "${alloc[a_idx]}" || return 1
                max+=("$val")
            done
        done
    fi

    # Calculate Need matrix: Need[i][j] = Max[i][j] - Alloc[i][j]
    local -a need=()
    for (( i=0; i<num_p; i++ )); do
        for (( j=0; j<num_r; j++ )); do
            local idx=$(( i * num_r + j ))
            local diff=$(( max[idx] - alloc[idx] ))
            if (( diff < 0 )); then
                msg_error "Inconsistent matrix: Allocation exceeds Max for P$(( i + 1 )) at R$(( j + 1 ))."
                return 1
            fi
            need+=("$diff")
        done
    done

    # Print input state table
    print_section "Resource Allocation State"
    echo -ne "PID       | "
    echo -ne "Allocation       | "
    echo -ne "Max Demand       | "
    echo -e "Need Matrix"
    print_divider 65

    for (( i=0; i<num_p; i++ )); do
        printf "P%-8s | " "$(( i + 1 ))"
        
        # Alloc
        for (( j=0; j<num_r; j++ )); do printf "%-2s " "${alloc[i*num_r + j]}"; done
        printf "%*s| " "$(( 17 - num_r * 3 ))" ""
        
        # Max
        for (( j=0; j<num_r; j++ )); do printf "%-2s " "${max[i*num_r + j]}"; done
        printf "%*s| " "$(( 17 - num_r * 3 ))" ""

        # Need
        for (( j=0; j<num_r; j++ )); do printf "%-2s " "${need[i*num_r + j]}"; done
        echo ""
    done
    print_divider 65

    echo -ne "Available: [ "
    for (( j=0; j<num_r; j++ )); do echo -ne "R$(( j + 1 ))=${avail[j]} "; done
    echo -e "]\n"

    # Banker's Safety Algorithm
    local -a work=("${avail[@]}")
    local -a finish=()
    local -a safe_seq=()
    for (( i=0; i<num_p; i++ )); do finish+=(0); done

    local count=0
    local step_trace=""

    while (( count < num_p )); do
        local found=false

        for (( i=0; i<num_p; i++ )); do
            if (( finish[i] == 0 )); then
                local can_allocate=true
                for (( j=0; j<num_r; j++ )); do
                    if (( need[i*num_r + j] > work[j] )); then
                        can_allocate=false
                        break
                    fi
                done

                if $can_allocate; then
                    # Process can finish
                    step_trace+="Step $(( count + 1 )): P$(( i + 1 )) can finish. Work before: [${work[*]}]. "
                    for (( j=0; j<num_r; j++ )); do
                        work[j]=$(( work[j] + alloc[i*num_r + j] ))
                    done
                    finish[i]=1
                    safe_seq+=("P$(( i + 1 ))")
                    (( count++ ))
                    found=true
                    step_trace+="Work after release: [${work[*]}]\n"
                    break
                fi
            fi
        done

        if ! $found; then
            break
        fi
    done

    # Output Evaluation
    print_section "Safety Evaluation Result"
    echo -e "${step_trace}"

    if (( count == num_p )); then
        echo -e "${COLOR_GREEN}${COLOR_BOLD}[SAFE STATE]${COLOR_RESET} The system is in a safe state."
        echo -ne "${COLOR_CYAN}Safe Sequence:${COLOR_RESET} "
        for (( s=0; s<num_p; s++ )); do
            echo -ne "${COLOR_GREEN}${COLOR_BOLD}${safe_seq[s]}${COLOR_RESET}"
            if (( s < num_p - 1 )); then echo -n " -> "; fi
        done
        echo -e "\n"
        log_simulation_csv "safety" "Bankers_Safety" "P=${num_p};R=${num_r}" "Status=SAFE;Seq=${safe_seq[*]}" "Safe execution found"
    else
        echo -e "${COLOR_RED}${COLOR_BOLD}[UNSAFE STATE]${COLOR_RESET} No safe sequence exists! Deadlock could occur."
        echo -ne "${COLOR_YELLOW}Unfinished Processes:${COLOR_RESET} "
        for (( i=0; i<num_p; i++ )); do
            if (( finish[i] == 0 )); then echo -n "P$(( i + 1 )) "; fi
        done
        echo -e "\n"
        log_simulation_csv "safety" "Bankers_Safety" "P=${num_p};R=${num_r}" "Status=UNSAFE;Finished=${count}/${num_p}" "Deadlock potential detected"
    fi

    if [[ "$is_preset" == "false" ]]; then
        pause_screen
    fi
}
