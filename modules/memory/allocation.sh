#!/usr/bin/env bash
# ==============================================================================
# modules/memory/allocation.sh - Contiguous Memory Allocation
# (First Fit, Best Fit, Worst Fit)
# ==============================================================================

# Simulates partition allocation
# $1: policy (first_fit, best_fit, worst_fit)
# $2: partitioning_model (fixed or variable)
# $3: preset_flag (optional)
run_memory_allocation_sim() {
    local policy="$1"
    local model="${2:-fixed}"
    local is_preset="${3:-false}"

    local -a block_sizes=()
    local -a process_sizes=()
    local num_blocks num_procs

    if [[ "$is_preset" == "true" ]]; then
        # Use passed preset globals or defaults
        num_blocks=${#PRESET_BLOCKS[@]}
        block_sizes=("${PRESET_BLOCKS[@]}")
        num_procs=${#PRESET_PROCS[@]}
        process_sizes=("${PRESET_PROCS[@]}")
    else
        local title_policy
        case "$policy" in
            first_fit) title_policy="First Fit" ;;
            best_fit)  title_policy="Best Fit" ;;
            worst_fit) title_policy="Worst Fit" ;;
        esac

        show_banner "Memory Allocation - ${title_policy}" \
                    "Contiguous allocation using ${model^} Partitioning"

        read_int "Enter number of memory blocks" num_blocks 1 "$MAX_MEMORY_BLOCKS" 5 || return 1
        echo -e "\nEnter block sizes (KB):"
        for (( i=0; i<num_blocks; i++ )); do
            local bs
            read_int "  Block $(( i + 1 )) size" bs 1 10000 100 || return 1
            block_sizes+=("$bs")
        done

        read_int "Enter number of processes" num_procs 1 "$MAX_PROCESSES" 4 || return 1
        echo -e "\nEnter process memory requirements (KB):"
        for (( i=0; i<num_procs; i++ )); do
            local ps
            read_int "  Process P$(( i + 1 )) size" ps 1 10000 50 || return 1
            process_sizes+=("$ps")
        done
    fi

    # Allocation arrays
    local -a orig_blocks=("${block_sizes[@]}")
    local -a rem_blocks=("${block_sizes[@]}")
    local -a alloc_block=() # Stores block index allocated to process i (-1 if not allocated)
    local -a internal_frag=()

    for (( i=0; i<num_procs; i++ )); do
        alloc_block+=(-1)
        internal_frag+=(0)
    done

    # Allocation logic
    for (( p=0; p<num_procs; p++ )); do
        local p_size="${process_sizes[p]}"
        local chosen_b=-1

        if [[ "$policy" == "first_fit" ]]; then
            for (( b=0; b<num_blocks; b++ )); do
                if (( rem_blocks[b] >= p_size )); then
                    chosen_b="$b"
                    break
                fi
            done
        elif [[ "$policy" == "best_fit" ]]; then
            local min_rem=9999999
            for (( b=0; b<num_blocks; b++ )); do
                if (( rem_blocks[b] >= p_size )); then
                    local diff=$(( rem_blocks[b] - p_size ))
                    if (( diff < min_rem )); then
                        min_rem="$diff"
                        chosen_b="$b"
                    fi
                fi
            done
        elif [[ "$policy" == "worst_fit" ]]; then
            local max_rem=-1
            for (( b=0; b<num_blocks; b++ )); do
                if (( rem_blocks[b] >= p_size )); then
                    local diff=$(( rem_blocks[b] - p_size ))
                    if (( diff > max_rem )); then
                        max_rem="$diff"
                        chosen_b="$b"
                    fi
                fi
            done
        fi

        if (( chosen_b != -1 )); then
            alloc_block[p]="$chosen_b"
            if [[ "$model" == "fixed" ]]; then
                # In fixed partitioning, block cannot be used by another process; remaining is internal fragmentation
                internal_frag[p]=$(( rem_blocks[chosen_b] - p_size ))
                rem_blocks[chosen_b]=0 # block fully consumed
            else
                # Variable partitioning: partition shrinks
                rem_blocks[chosen_b]=$(( rem_blocks[chosen_b] - p_size ))
            fi
        fi
    done

    # Print results
    print_section "Allocation Table (${policy^^} - ${model^} Partitions)"
    printf "%-10s %-12s %-16s %-16s %-20s\n" \
           "Process" "Size (KB)" "Allocated Block" "Block Orig Size" "Internal Frag (KB)"
    print_divider 80

    local allocated_count=0
    local total_internal_frag=0
    for (( p=0; p<num_procs; p++ )); do
        local b_idx="${alloc_block[p]}"
        if (( b_idx != -1 )); then
            (( allocated_count++ ))
            total_internal_frag=$(( total_internal_frag + internal_frag[p] ))
            printf "%-10s %-12s %-16s %-16s %-20s\n" \
                   "P$(( p + 1 ))" "${process_sizes[p]}" "Block $(( b_idx + 1 ))" "${orig_blocks[b_idx]}" "${internal_frag[p]}"
        else
            printf "%-10s %-12s %-16s %-16s %-20s\n" \
                   "P$(( p + 1 ))" "${process_sizes[p]}" "Not Allocated" "-" "-"
        fi
    done
    print_divider 80

    # Remaining blocks / External fragmentation summary
    echo -e "\n${COLOR_BOLD}Remaining Memory State:${COLOR_RESET}"
    local total_unallocated_mem=0
    for (( b=0; b<num_blocks; b++ )); do
        echo -e "  Block $(( b + 1 )) (Original: ${orig_blocks[b]} KB) -> Remaining: ${COLOR_GREEN}${rem_blocks[b]} KB${COLOR_RESET}"
        total_unallocated_mem=$(( total_unallocated_mem + rem_blocks[b] ))
    done

    if [[ "$model" == "fixed" ]]; then
        echo -e "\nTotal Internal Fragmentation: ${COLOR_YELLOW}${total_internal_frag} KB${COLOR_RESET}"
    else
        echo -e "\nTotal Free Space (External Fragmentation potential): ${COLOR_YELLOW}${total_unallocated_mem} KB${COLOR_RESET}"
    fi

    # Log results
    local input_sum="Blocks=${orig_blocks[*]};Procs=${process_sizes[*]}"
    local result_sum="Allocated=${allocated_count}/${num_procs};Unallocated_Mem=${total_unallocated_mem}KB"
    log_simulation_csv "memory" "${policy}_${model}" "$input_sum" "$result_sum" "Memory allocation"

    if [[ "$is_preset" != "true" ]]; then
        pause_screen
    fi

    export LAST_ALLOCATED_COUNT="$allocated_count"
    export LAST_UNALLOCATED_MEM="$total_unallocated_mem"
}

run_memory_allocation_comparison() {
    show_banner "Memory Allocation Comparison" \
                "Compare First Fit, Best Fit, and Worst Fit on the exact same inputs"

    local num_blocks num_procs
    read_int "Enter number of memory blocks" num_blocks 1 "$MAX_MEMORY_BLOCKS" 5 || return 1
    export -a PRESET_BLOCKS=()
    echo -e "\nEnter block sizes (KB):"
    for (( i=0; i<num_blocks; i++ )); do
        local bs
        read_int "  Block $(( i + 1 )) size" bs 1 10000 100 || return 1
        PRESET_BLOCKS+=("$bs")
    done

    read_int "Enter number of processes" num_procs 1 "$MAX_PROCESSES" 4 || return 1
    export -a PRESET_PROCS=()
    echo -e "\nEnter process sizes (KB):"
    for (( i=0; i<num_procs; i++ )); do
        local ps
        read_int "  Process P$(( i + 1 )) size" ps 1 10000 50 || return 1
        PRESET_PROCS+=("$ps")
    done

    echo -e "\nSelect Model: [1] Fixed Partitions  [2] Variable Partitions"
    local m_sel model="fixed"
    read_int "Choice" m_sel 1 2 1
    if (( m_sel == 2 )); then model="variable"; fi

    run_memory_allocation_sim "first_fit" "$model" "true"
    run_memory_allocation_sim "best_fit"  "$model" "true"
    run_memory_allocation_sim "worst_fit" "$model" "true"

    pause_screen
}
