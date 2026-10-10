#!/usr/bin/env bash
# ==============================================================================
# modules/memory/paging.sh - Virtual Memory Page Replacement Simulation
# (FIFO, LRU, Optimal)
# ==============================================================================

# Generic page replacement runner
# $1: policy (fifo, lru, optimal)
# $2: num_frames
# $3: ref_string (e.g. "7 0 1 2 0 3 0 4 2 3 0 3 2")
# $4: silent (optional, for benchmarks)
run_page_replacement() {
    local policy="$1"
    local num_frames="$2"
    local ref_str="$3"
    local silent="${4:-false}"

    local -a pages
    # shellcheck disable=SC2206
    pages=($ref_str)
    local num_refs=${#pages[@]}

    if (( num_refs == 0 || num_frames <= 0 )); then
        msg_error "Invalid references or frame count."
        return 1
    fi

    # Frames array initialized to empty (-1)
    local -a frames=()
    for (( i=0; i<num_frames; i++ )); do frames+=(-1); done

    # Policy specific helpers
    local -a load_order=() # For FIFO
    for (( i=0; i<num_frames; i++ )); do load_order+=(-1); done
    local -a last_used=()  # For LRU
    for (( i=0; i<num_frames; i++ )); do last_used+=(-1); done

    local page_faults=0
    local page_hits=0

    # Trace logs
    local -a trace_pages=()
    local -a trace_frames=() # flattened representation
    local -a trace_status=()

    for (( step=0; step<num_refs; step++ )); do
        local page="${pages[step]}"
        local is_hit=false
        local hit_frame=-1

        for (( f=0; f<num_frames; f++ )); do
            if (( frames[f] == page )); then
                is_hit=true
                hit_frame="$f"
                break
            fi
        done

        if $is_hit; then
            (( page_hits++ ))
            last_used[hit_frame]="$step"
            trace_status+=("HIT")
        else
            (( page_faults++ ))
            trace_status+=("FAULT")

            # Find empty frame first
            local empty_frame=-1
            for (( f=0; f<num_frames; f++ )); do
                if (( frames[f] == -1 )); then
                    empty_frame="$f"
                    break
                fi
            done

            local target_frame=-1
            if (( empty_frame != -1 )); then
                target_frame="$empty_frame"
            else
                # Eviction policy
                if [[ "$policy" == "fifo" ]]; then
                    # Find frame with minimum load_order
                    local min_load=9999999
                    for (( f=0; f<num_frames; f++ )); do
                        if (( load_order[f] < min_load )); then
                            min_load="${load_order[f]}"
                            target_frame="$f"
                        fi
                    done
                elif [[ "$policy" == "lru" ]]; then
                    # Find frame with minimum last_used
                    local min_used=9999999
                    for (( f=0; f<num_frames; f++ )); do
                        if (( last_used[f] < min_used )); then
                            min_used="${last_used[f]}"
                            target_frame="$f"
                        fi
                    done
                elif [[ "$policy" == "optimal" ]]; then
                    # Look ahead in reference string
                    local farthest_step=-1
                    local replace_idx=0
                    for (( f=0; f<num_frames; f++ )); do
                        local next_use=9999999
                        for (( k=step+1; k<num_refs; k++ )); do
                            if (( pages[k] == frames[f] )); then
                                next_use="$k"
                                break
                            fi
                        done
                        if (( next_use > farthest_step )); then
                            farthest_step="$next_use"
                            replace_idx="$f"
                        fi
                    done
                    target_frame="$replace_idx"
                fi
            fi

            frames[target_frame]="$page"
            load_order[target_frame]="$step"
            last_used[target_frame]="$step"
        fi

        # Record snapshot
        local snap=""
        for (( f=0; f<num_frames; f++ )); do
            if (( frames[f] == -1 )); then
                snap+="- "
            else
                snap+="${frames[f]} "
            fi
        done
        trace_frames+=("$snap")
        trace_pages+=("$page")
    done

    local fault_rate
    fault_rate=$(awk "BEGIN {printf \"%.2f\", ($page_faults / $num_refs) * 100}")

    export LAST_PAGE_FAULTS="$page_faults"
    export LAST_PAGE_HITS="$page_hits"
    export LAST_FAULT_RATE="$fault_rate"

    if [[ "$silent" == "true" ]]; then
        return 0
    fi

    # Print Trace Table
    print_section "Page Replacement Trace (${policy^^} - ${num_frames} Frames)"
    printf "%-6s | %-8s | %-$(( num_frames * 4 + 2 ))s | %-8s\n" "Step" "Ref Page" "Frames" "Status"
    print_divider "$(( num_frames * 4 + 32 ))"

    for (( i=0; i<num_refs; i++ )); do
        local stat_color="${COLOR_GREEN}"
        if [[ "${trace_status[i]}" == "FAULT" ]]; then
            stat_color="${COLOR_RED}"
        fi
        printf "%-6s | %-8s | %-$(( num_frames * 4 + 2 ))s | ${stat_color}%-8s${COLOR_RESET}\n" \
               "$(( i + 1 ))" "${trace_pages[i]}" "${trace_frames[i]}" "${trace_status[i]}"
    done
    print_divider "$(( num_frames * 4 + 32 ))"

    echo -e "Total References : ${COLOR_BOLD}${num_refs}${COLOR_RESET}"
    echo -e "Page Hits        : ${COLOR_GREEN}${page_hits}${COLOR_RESET}"
    echo -e "Page Faults      : ${COLOR_RED}${page_faults}${COLOR_RESET}"
    echo -e "Fault Rate       : ${COLOR_YELLOW}${fault_rate}%${COLOR_RESET}"

    # Log to CSV
    log_simulation_csv "memory" "Paging_${policy^^}" "Frames=${num_frames};Refs=${ref_str}" \
                       "Faults=${page_faults};Hits=${page_hits};Rate=${fault_rate}%" "Page replacement trace"
}

run_paging_interactive() {
    local policy="$1"
    show_banner "Page Replacement - ${policy^^}" \
                "Simulates step-by-step frame contents and page faults"

    local num_frames
    read_int "Enter number of page frames" num_frames 1 "$MAX_FRAMES" 3 || return 1

    local -a ref_array=()
    read_int_array "Enter page reference string (space-separated, e.g., 7 0 1 2 0 3 0 4 2 3)" \
                   ref_array 0 99 || return 1

    run_page_replacement "$policy" "$num_frames" "${ref_array[*]}" false
    pause_screen
}

run_paging_comparative_benchmark() {
    show_banner "Page Replacement Comparative Benchmark" \
                "Direct comparison of FIFO, LRU, and Optimal on the same reference string"

    local num_frames
    read_int "Enter number of page frames" num_frames 1 "$MAX_FRAMES" 3 || return 1

    local -a ref_array=()
    read_int_array "Enter page reference string (e.g., 7 0 1 2 0 3 0 4 2 3 0 3 2 1 2 0 1 7 0 1)" \
                   ref_array 0 99 || return 1
    local ref_str="${ref_array[*]}"

    # Run FIFO
    run_page_replacement "fifo" "$num_frames" "$ref_str" true
    local fifo_f="$LAST_PAGE_FAULTS" fifo_h="$LAST_PAGE_HITS" fifo_r="$LAST_FAULT_RATE"

    # Run LRU
    run_page_replacement "lru" "$num_frames" "$ref_str" true
    local lru_f="$LAST_PAGE_FAULTS" lru_h="$LAST_PAGE_HITS" lru_r="$LAST_FAULT_RATE"

    # Run Optimal
    run_page_replacement "optimal" "$num_frames" "$ref_str" true
    local opt_f="$LAST_PAGE_FAULTS" opt_h="$LAST_PAGE_HITS" opt_r="$LAST_FAULT_RATE"

    show_banner "Paging Comparison Summary" "Frames: ${num_frames} | References: ${#ref_array[@]}"
    printf "%-18s %-14s %-14s %-16s\n" "Policy" "Page Faults" "Page Hits" "Fault Rate"
    print_divider 65
    printf "%-18s %-14s %-14s %-16s\n" "FIFO" "$fifo_f" "$fifo_h" "${fifo_r}%"
    printf "%-18s %-14s %-14s %-16s\n" "LRU" "$lru_f" "$lru_h" "${lru_r}%"
    printf "%-18s %-14s %-14s %-16s\n" "Optimal (MIN)" "$opt_f" "$opt_h" "${opt_r}%"
    print_divider 65

    msg_info "Theoretical guarantee: Optimal replacement achieves the absolute minimum page faults."
    pause_screen
}
