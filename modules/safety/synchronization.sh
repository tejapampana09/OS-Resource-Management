#!/usr/bin/env bash
# ==============================================================================
# modules/safety/synchronization.sh - Process Synchronization & Bounded-Buffer Simulation
# ==============================================================================

# Interactive Bounded-Buffer Producer-Consumer Simulation
run_synchronization_demo() {
    local buffer_size=5
    local -a buffer=()
    for (( i=0; i<buffer_size; i++ )); do buffer+=("EMPTY"); done

    local mutex=1       # Binary semaphore (1=free, 0=locked)
    local empty_slots=$buffer_size # Counting semaphore
    local full_slots=0  # Counting semaphore
    local item_id=1
    local in_idx=0
    local out_idx=0

    render_buffer_status() {
        echo -e "\n${COLOR_BOLD}Bounded Buffer State (Capacity: ${buffer_size}):${COLOR_RESET}"
        echo -ne "  [ "
        for (( i=0; i<buffer_size; i++ )); do
            if [[ "${buffer[i]}" == "EMPTY" ]]; then
                echo -ne "${COLOR_DIM}[EMPTY]${COLOR_RESET} "
            else
                echo -ne "${COLOR_GREEN}[${buffer[i]}]${COLOR_RESET} "
            fi
        done
        echo -e "]"
        echo -e "  Semaphores -> ${COLOR_CYAN}mutex=${mutex}${COLOR_RESET} | ${COLOR_YELLOW}empty=${empty_slots}${COLOR_RESET} | ${COLOR_GREEN}full=${full_slots}${COLOR_RESET}"
        echo -e "  Indices    -> in=${in_idx} (next write) | out=${out_idx} (next read)"
    }

    while true; do
        show_banner "Process Synchronization: Producer-Consumer Simulation" \
                    "Controlled simulation demonstrating Semaphores, Mutex & Bounded Buffer"

        render_buffer_status

        echo -e "\n${COLOR_BOLD}Actions:${COLOR_RESET}"
        echo -e "  [1] Produce an Item (Producer)"
        echo -e "  [2] Consume an Item (Consumer)"
        echo -e "  [3] Run Automated Mixed Burst (10 operations)"
        echo -e "  [4] Explain 4 Coffman Conditions (Deadlock Theory)"
        echo -e "  [0] Return to Safety Menu"
        echo ""

        local act
        read_int "Choose action" act 0 4 1 || return 0

        case "$act" in
            1)
                # Produce
                if (( empty_slots == 0 )); then
                    msg_warn "Buffer is FULL! Producer must WAIT on semaphore 'empty'."
                elif (( mutex == 0 )); then
                    msg_warn "Critical Section LOCKED! Producer must WAIT on semaphore 'mutex'."
                else
                    (( empty_slots-- ))
                    mutex=0 # lock
                    local item="Item#${item_id}"
                    buffer[in_idx]="$item"
                    msg_success "Producer produced '${item}' at buffer index ${in_idx}."
                    in_idx=$(( (in_idx + 1) % buffer_size ))
                    (( item_id++ ))
                    mutex=1 # unlock
                    (( full_slots++ ))
                fi
                pause_screen
                ;;
            2)
                # Consume
                if (( full_slots == 0 )); then
                    msg_warn "Buffer is EMPTY! Consumer must WAIT on semaphore 'full'."
                elif (( mutex == 0 )); then
                    msg_warn "Critical Section LOCKED! Consumer must WAIT on semaphore 'mutex'."
                else
                    (( full_slots-- ))
                    mutex=0 # lock
                    local consumed="${buffer[out_idx]}"
                    buffer[out_idx]="EMPTY"
                    msg_success "Consumer consumed '${consumed}' from buffer index ${out_idx}."
                    out_idx=$(( (out_idx + 1) % buffer_size ))
                    mutex=1 # unlock
                    (( empty_slots++ ))
                fi
                pause_screen
                ;;
            3)
                echo -e "\n${COLOR_BOLD}Executing 10 automated interleaved steps:${COLOR_RESET}"
                for (( step=1; step<=10; step++ )); do
                    local op=$(( RANDOM % 2 ))
                    if (( op == 0 && empty_slots > 0 )); then
                        # Produce
                        (( empty_slots-- ))
                        local item="Auto#${item_id}"
                        buffer[in_idx]="$item"
                        echo "  Step ${step}: Producer -> Inserted ${item} at slot ${in_idx}"
                        in_idx=$(( (in_idx + 1) % buffer_size ))
                        (( item_id++ ))
                        (( full_slots++ ))
                    elif (( full_slots > 0 )); then
                        # Consume
                        (( full_slots-- ))
                        local c_item="${buffer[out_idx]}"
                        buffer[out_idx]="EMPTY"
                        echo "  Step ${step}: Consumer <- Removed ${c_item} from slot ${out_idx}"
                        out_idx=$(( (out_idx + 1) % buffer_size ))
                        (( empty_slots++ ))
                    else
                        echo "  Step ${step}: Buffer empty, consumer waiting."
                    fi
                done
                pause_screen
                ;;
            4)
                show_banner "OS Synchronization & Deadlock Theory: Coffman Conditions"
                echo -e "${COLOR_BOLD}For a deadlock to arise, all 4 Coffman conditions must hold simultaneously:${COLOR_RESET}\n"
                echo -e "1. ${COLOR_GREEN}Mutual Exclusion:${COLOR_RESET} At least one resource must be held in a non-shareable mode."
                echo -e "2. ${COLOR_GREEN}Hold and Wait:${COLOR_RESET} A process must be holding at least one resource and waiting to acquire additional resources held by others."
                echo -e "3. ${COLOR_GREEN}No Preemption:${COLOR_RESET} Resources cannot be forcibly taken; they can only be released voluntarily."
                echo -e "4. ${COLOR_GREEN}Circular Wait:${COLOR_RESET} A closed chain of processes exists, where each process holds a resource needed by the next."
                echo -e "\n${COLOR_CYAN}Deadlock Prevention Strategy:${COLOR_RESET} Invalidate at least one of these 4 conditions (e.g., impose strict global resource ordering to eliminate circular wait)."
                pause_screen
                ;;
            0)
                return 0
                ;;
        esac
    done
}
