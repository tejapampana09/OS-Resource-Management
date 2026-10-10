#!/usr/bin/env bash
# ==============================================================================
# modules/storage/disk.sh - Disk Scheduling Algorithms
# (FCFS, SSTF, SCAN, C-SCAN, LOOK)
# ==============================================================================

# Generic disk algorithm executor
# $1: algorithm (fcfs, sstf, scan, c-scan, look)
# $2: initial_head
# $3: max_cylinder (e.g. 199 for 0..199)
# $4: direction (up / down)
# $5: request_str (e.g. "98 183 37 122 14 124 65 67")
# $6: silent (true / false)
run_disk_algorithm() {
    local algo="$1"
    local init_head="$2"
    local max_cyl="$3"
    local dir="$4"
    local req_str="$5"
    local silent="${6:-false}"

    local -a requests
    # shellcheck disable=SC2206
    requests=($req_str)
    local num_req=${#requests[@]}

    if (( num_req == 0 )); then
        msg_error "No requests provided."
        return 1
    fi

    local -a sequence=("$init_head")
    local -a step_moves=()
    local total_seek=0

    case "$algo" in
        fcfs)
            for req in "${requests[@]}"; do
                sequence+=("$req")
            done
            ;;

        sstf)
            local -a pending=("${requests[@]}")
            local curr="$init_head"
            while (( ${#pending[@]} > 0 )); do
                local best_idx=0
                local min_dist=9999999
                for (( i=0; i<${#pending[@]}; i++ )); do
                    local dist=$(( curr - pending[i] ))
                    (( dist < 0 )) && dist=$(( -dist ))
                    if (( dist < min_dist )); then
                        min_dist="$dist"
                        best_idx="$i"
                    fi
                done
                curr="${pending[best_idx]}"
                sequence+=("$curr")
                unset 'pending[best_idx]'
                pending=("${pending[@]}") # Re-index
            done
            ;;

        scan)
            local -a left=() right=()
            for req in "${requests[@]}"; do
                if (( req < init_head )); then left+=("$req"); else right+=("$req"); fi
            done
            # Sort left descending, right ascending
            IFS=$'\n' left=($(sort -n -r <<<"${left[*]}")); IFS=' '
            IFS=$'\n' right=($(sort -n <<<"${right[*]}")); IFS=' '

            if [[ "$dir" == "up" ]]; then
                for r in "${right[@]}"; do sequence+=("$r"); done
                # Travels to disk upper boundary
                sequence+=("$max_cyl")
                for r in "${left[@]}"; do sequence+=("$r"); done
            else
                for r in "${left[@]}"; do sequence+=("$r"); done
                # Travels to disk lower boundary (0)
                sequence+=(0)
                for r in "${right[@]}"; do sequence+=("$r"); done
            fi
            ;;

        c-scan)
            local -a left=() right=()
            for req in "${requests[@]}"; do
                if (( req < init_head )); then left+=("$req"); else right+=("$req"); fi
            done
            IFS=$'\n' left=($(sort -n <<<"${left[*]}")); IFS=' '
            IFS=$'\n' right=($(sort -n <<<"${right[*]}")); IFS=' '

            if [[ "$dir" == "up" ]]; then
                for r in "${right[@]}"; do sequence+=("$r"); done
                sequence+=("$max_cyl")
                sequence+=(0)
                for r in "${left[@]}"; do sequence+=("$r"); done
            else
                IFS=$'\n' left=($(sort -n -r <<<"${left[*]}")); IFS=' '
                IFS=$'\n' right=($(sort -n -r <<<"${right[*]}")); IFS=' '
                for r in "${left[@]}"; do sequence+=("$r"); done
                sequence+=(0)
                sequence+=("$max_cyl")
                for r in "${right[@]}"; do sequence+=("$r"); done
            fi
            ;;

        look)
            local -a left=() right=()
            for req in "${requests[@]}"; do
                if (( req < init_head )); then left+=("$req"); else right+=("$req"); fi
            done
            IFS=$'\n' left=($(sort -n -r <<<"${left[*]}")); IFS=' '
            IFS=$'\n' right=($(sort -n <<<"${right[*]}")); IFS=' '

            if [[ "$dir" == "up" ]]; then
                for r in "${right[@]}"; do sequence+=("$r"); done
                for r in "${left[@]}"; do sequence+=("$r"); done
            else
                for r in "${left[@]}"; do sequence+=("$r"); done
                for r in "${right[@]}"; do sequence+=("$r"); done
            fi
            ;;
    esac

    # Calculate step distances and total seek
    for (( i=1; i<${#sequence[@]}; i++ )); do
        local d=$(( sequence[i] - sequence[i-1] ))
        (( d < 0 )) && d=$(( -d ))
        step_moves+=("$d")
        total_seek=$(( total_seek + d ))
    done

    local avg_seek
    avg_seek=$(awk "BEGIN {printf \"%.2f\", $total_seek / $num_req}")

    export LAST_DISK_SEEK="$total_seek"
    export LAST_DISK_AVG="$avg_seek"

    if [[ "$silent" == "true" ]]; then
        return 0
    fi

    # Display results
    print_section "Disk Head Movement (${algo^^})"
    echo -e "${COLOR_BOLD}Initial Head:${COLOR_RESET} ${init_head} | ${COLOR_BOLD}Direction:${COLOR_RESET} ${dir^} | ${COLOR_BOLD}Max Cylinder:${COLOR_RESET} ${max_cyl}"
    echo -ne "\n${COLOR_CYAN}Head Travel Sequence:${COLOR_RESET}\n  "
    for (( i=0; i<${#sequence[@]}; i++ )); do
        echo -ne "${COLOR_GREEN}${COLOR_BOLD}${sequence[i]}${COLOR_RESET}"
        if (( i < ${#sequence[@]} - 1 )); then
            echo -ne " -> "
        fi
    done
    echo -e "\n"

    printf "%-6s | %-16s | %-16s | %-16s\n" "Step" "From Cylinder" "To Cylinder" "Seek Distance"
    print_divider 65
    for (( i=1; i<${#sequence[@]}; i++ )); do
        printf "%-6s | %-16s | %-16s | %-16s\n" \
               "$i" "${sequence[i-1]}" "${sequence[i]}" "${step_moves[i-1]}"
    done
    print_divider 65

    echo -e "Total Head Movement: ${COLOR_GREEN}${COLOR_BOLD}${total_seek}${COLOR_RESET} cylinders"
    echo -e "Average Seek Time  : ${COLOR_CYAN}${avg_seek}${COLOR_RESET} cylinders/request"

    log_simulation_csv "storage" "Disk_${algo^^}" "Head=${init_head};Queue=${req_str}" \
                       "TotalSeek=${total_seek};Avg=${avg_seek}" "Disk scheduling run"
}

run_disk_interactive() {
    local algo="$1"
    show_banner "Disk Scheduling - ${algo^^}" \
                "Models track seek operations, boundary handling, and total head displacement"

    local init_head max_cyl dir="up"
    read_int "Enter initial head position" init_head 0 5000 53 || return 1
    read_int "Enter max disk cylinder (e.g., 199 for 0..199)" max_cyl 1 5000 199 || return 1

    if [[ "$algo" == "scan" || "$algo" == "c-scan" || "$algo" == "look" ]]; then
        echo -e "\nSelect Initial Head Direction:"
        echo "  [1] Towards higher cylinders (Up / Right)"
        echo "  [2] Towards lower cylinders (Down / Left)"
        local d_choice
        read_int "Choice" d_choice 1 2 1
        if (( d_choice == 2 )); then dir="down"; fi
    fi

    local -a reqs=()
    read_int_array "Enter request queue (space-separated cylinder numbers)" reqs 0 "$max_cyl" || return 1

    run_disk_algorithm "$algo" "$init_head" "$max_cyl" "$dir" "${reqs[*]}" false
    pause_screen
}

run_disk_comparative_benchmark() {
    show_banner "Disk Scheduling Comparative Benchmark" \
                "Compare FCFS, SSTF, SCAN, C-SCAN, and LOOK on the exact same queue"

    local init_head max_cyl dir="up"
    read_int "Enter initial head position" init_head 0 5000 50 || return 1
    read_int "Enter max disk cylinder" max_cyl 1 5000 199 || return 1

    echo -e "\nSelect Direction for SCAN/LOOK algorithms:"
    echo "  [1] Up (towards higher cylinders)"
    echo "  [2] Down (towards lower cylinders)"
    local d_choice
    read_int "Choice" d_choice 1 2 1
    if (( d_choice == 2 )); then dir="down"; fi

    local -a reqs=()
    read_int_array "Enter request queue (e.g., 98 183 37 122 14 124 65 67)" reqs 0 "$max_cyl" || return 1
    local req_str="${reqs[*]}"

    run_disk_algorithm "fcfs"   "$init_head" "$max_cyl" "$dir" "$req_str" true
    local fcfs_s="$LAST_DISK_SEEK" fcfs_a="$LAST_DISK_AVG"

    run_disk_algorithm "sstf"   "$init_head" "$max_cyl" "$dir" "$req_str" true
    local sstf_s="$LAST_DISK_SEEK" sstf_a="$LAST_DISK_AVG"

    run_disk_algorithm "scan"   "$init_head" "$max_cyl" "$dir" "$req_str" true
    local scan_s="$LAST_DISK_SEEK" scan_a="$LAST_DISK_AVG"

    run_disk_algorithm "c-scan" "$init_head" "$max_cyl" "$dir" "$req_str" true
    local cscan_s="$LAST_DISK_SEEK" cscan_a="$LAST_DISK_AVG"

    run_disk_algorithm "look"   "$init_head" "$max_cyl" "$dir" "$req_str" true
    local look_s="$LAST_DISK_SEEK" look_a="$LAST_DISK_AVG"

    show_banner "Disk Scheduling Comparison Summary" "Initial Head: ${init_head} | Direction: ${dir^}"
    printf "%-18s %-22s %-22s\n" "Algorithm" "Total Head Movement" "Avg Seek Movement"
    print_divider 65
    printf "%-18s %-22s %-22s\n" "FCFS" "${fcfs_s} cyl" "${fcfs_a} cyl/req"
    printf "%-18s %-22s %-22s\n" "SSTF" "${sstf_s} cyl" "${sstf_a} cyl/req"
    printf "%-18s %-22s %-22s\n" "SCAN" "${scan_s} cyl" "${scan_a} cyl/req"
    printf "%-18s %-22s %-22s\n" "C-SCAN" "${cscan_s} cyl" "${cscan_a} cyl/req"
    printf "%-18s %-22s %-22s\n" "LOOK" "${look_s} cyl" "${look_a} cyl/req"
    print_divider 65

    msg_info "SSTF and LOOK typically minimize total head movement by serving local clusters."
    pause_screen
}
