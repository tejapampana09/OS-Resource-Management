#!/usr/bin/env bash
# ==============================================================================
# modules/storage/file_allocation.sh - File Allocation Strategies Simulation
# (Contiguous, Linked, Indexed)
# ==============================================================================

# Simulated disk storage pool (32 blocks)
TOTAL_DISK_BLOCKS=32
declare -a DISK_BLOCK_MAP=()
declare -a FILE_NAMES=()
declare -a FILE_TYPES=()
declare -a FILE_DETAILS=()

init_file_system() {
    DISK_BLOCK_MAP=()
    for (( i=0; i<TOTAL_DISK_BLOCKS; i++ )); do
        DISK_BLOCK_MAP+=("FREE")
    done
    FILE_NAMES=()
    FILE_TYPES=()
    FILE_DETAILS=()
}

# Display visual disk block grid
display_disk_map() {
    echo -e "\n${COLOR_BOLD}Simulated Disk Block Map (${TOTAL_DISK_BLOCKS} Blocks of 4KB):${COLOR_RESET}"
    for (( i=0; i<TOTAL_DISK_BLOCKS; i++ )); do
        if (( i % 8 == 0 )); then printf "\n  [%02d-%02d]: " "$i" "$(( i + 7 ))"; fi
        local status="${DISK_BLOCK_MAP[i]}"
        if [[ "$status" == "FREE" ]]; then
            printf "${COLOR_DIM}[ . ]${COLOR_RESET} "
        elif [[ "$status" =~ ^IDX_ ]]; then
            printf "${COLOR_YELLOW}[${status:4:3}]${COLOR_RESET} "
        else
            printf "${COLOR_GREEN}[${status:0:3}]${COLOR_RESET} "
        fi
    done
    echo -e "\n"
}

run_contiguous_allocation_demo() {
    show_banner "Contiguous File Allocation" \
                "Allocates contiguous blocks; suffers from external fragmentation"
    display_disk_map

    local fname fsize
    echo -ne "${COLOR_CYAN}Enter File Name (e.g., fileA): ${COLOR_RESET}"
    read -r fname
    read_int "Enter file size in blocks" fsize 1 "$TOTAL_DISK_BLOCKS" 4 || return 1

    # Search for a contiguous chunk of fsize FREE blocks
    local start_block=-1
    local current_run=0
    local run_start=0

    for (( i=0; i<TOTAL_DISK_BLOCKS; i++ )); do
        if [[ "${DISK_BLOCK_MAP[i]}" == "FREE" ]]; then
            if (( current_run == 0 )); then run_start="$i"; fi
            (( current_run++ ))
            if (( current_run == fsize )); then
                start_block="$run_start"
                break
            fi
        else
            current_run=0
        fi
    done

    if (( start_block != -1 )); then
        for (( b=start_block; b<start_block+fsize; b++ )); do
            DISK_BLOCK_MAP[b]="$fname"
        done
        FILE_NAMES+=("$fname")
        FILE_TYPES+=("Contiguous")
        FILE_DETAILS+=("Start=${start_block}, Length=${fsize}")
        msg_success "File '${fname}' allocated contiguously from block ${start_block} to $(( start_block + fsize - 1 ))."
    else
        # Count total free blocks
        local total_free=0
        for (( i=0; i<TOTAL_DISK_BLOCKS; i++ )); do
            [[ "${DISK_BLOCK_MAP[i]}" == "FREE" ]] && (( total_free++ ))
        done
        msg_error "Allocation failed! Could not find ${fsize} contiguous blocks."
        if (( total_free >= fsize )); then
            msg_warn "External Fragmentation Detected: Total free blocks (${total_free}) >= requested (${fsize}), but no single contiguous run exists!"
        fi
    fi

    display_disk_map
    pause_screen
}

run_linked_allocation_demo() {
    show_banner "Linked File Allocation" \
                "Non-contiguous blocks connected via pointers (No external fragmentation)"
    display_disk_map

    local fname fsize
    echo -ne "${COLOR_CYAN}Enter File Name (e.g., fileB): ${COLOR_RESET}"
    read -r fname
    read_int "Enter file size in blocks" fsize 1 "$TOTAL_DISK_BLOCKS" 4 || return 1

    # Find any fsize free blocks
    local -a free_indices=()
    for (( i=0; i<TOTAL_DISK_BLOCKS; i++ )); do
        if [[ "${DISK_BLOCK_MAP[i]}" == "FREE" ]]; then
            free_indices+=("$i")
            (( ${#free_indices[@]} == fsize )) && break
        fi
    done

    if (( ${#free_indices[@]} < fsize )); then
        msg_error "Not enough free blocks on disk (Available: ${#free_indices[@]}, Requested: ${fsize})."
        pause_screen
        return 1
    fi

    local chain_str=""
    for (( i=0; i<fsize; i++ )); do
        local b="${free_indices[i]}"
        DISK_BLOCK_MAP[b]="$fname"
        chain_str+="$b"
        if (( i < fsize - 1 )); then chain_str+=" -> "; fi
    done

    FILE_NAMES+=("$fname")
    FILE_TYPES+=("Linked")
    FILE_DETAILS+=("Start=${free_indices[0]}, Chain=[${chain_str}]")
    msg_success "File '${fname}' allocated using Linked allocation."
    echo -e "Block Pointer Chain: ${COLOR_GREEN}${chain_str}${COLOR_RESET}"
    echo -e "${COLOR_DIM}(Note: 4 bytes per block reserved for next-block pointer metadata)${COLOR_RESET}"

    display_disk_map
    pause_screen
}

run_indexed_allocation_demo() {
    show_banner "Indexed File Allocation" \
                "Allocates an Index Block pointing to discrete data blocks"
    display_disk_map

    local fname fsize
    echo -ne "${COLOR_CYAN}Enter File Name (e.g., fileC): ${COLOR_RESET}"
    read -r fname
    read_int "Enter data size in blocks" fsize 1 "$(( TOTAL_DISK_BLOCKS - 1 ))" 3 || return 1

    local total_needed=$(( fsize + 1 )) # 1 index block + fsize data blocks
    local -a free_indices=()
    for (( i=0; i<TOTAL_DISK_BLOCKS; i++ )); do
        if [[ "${DISK_BLOCK_MAP[i]}" == "FREE" ]]; then
            free_indices+=("$i")
            (( ${#free_indices[@]} == total_needed )) && break
        fi
    done

    if (( ${#free_indices[@]} < total_needed )); then
        msg_error "Insufficient disk space (Needed 1 Index + ${fsize} Data blocks = ${total_needed})."
        pause_screen
        return 1
    fi

    local index_block="${free_indices[0]}"
    DISK_BLOCK_MAP[index_block]="IDX_${fname}"

    local data_blocks=()
    for (( i=1; i<=fsize; i++ )); do
        local b="${free_indices[i]}"
        DISK_BLOCK_MAP[b]="$fname"
        data_blocks+=("$b")
    done

    FILE_NAMES+=("$fname")
    FILE_TYPES+=("Indexed")
    FILE_DETAILS+=("IndexBlock=${index_block}, DataBlocks=[${data_blocks[*]}]")
    msg_success "File '${fname}' allocated using Indexed allocation."
    echo -e "Index Block: ${COLOR_YELLOW}${index_block}${COLOR_RESET} -> Pointers: [${COLOR_GREEN}${data_blocks[*]}${COLOR_RESET}]"
    echo -e "${COLOR_DIM}(Index block allows direct access to any file block in O(1))${COLOR_RESET}"

    display_disk_map
    pause_screen
}

list_and_delete_files() {
    show_banner "File Allocation Table & Directory"
    if (( ${#FILE_NAMES[@]} == 0 )); then
        echo "No files currently allocated."
        pause_screen
        return 0
    fi

    printf "%-6s | %-12s | %-14s | %-30s\n" "No." "File Name" "Allocation" "Metadata Details"
    print_divider 75
    for (( i=0; i<${#FILE_NAMES[@]}; i++ )); do
        printf "%-6s | %-12s | %-14s | %-30s\n" \
               "$(( i + 1 ))" "${FILE_NAMES[i]}" "${FILE_TYPES[i]}" "${FILE_DETAILS[i]}"
    done
    print_divider 75

    echo -e "\nOptions: [1] Delete a File  [0] Back"
    local opt
    read_int "Choice" opt 0 1 0
    if (( opt == 1 )); then
        local del_idx
        read_int "Enter file number to delete" del_idx 1 "${#FILE_NAMES[@]}" 1
        local target_name="${FILE_NAMES[$(( del_idx - 1 ))]}"

        # Free all blocks owned by target_name
        for (( b=0; b<TOTAL_DISK_BLOCKS; b++ )); do
            if [[ "${DISK_BLOCK_MAP[b]}" == "$target_name" || "${DISK_BLOCK_MAP[b]}" == "IDX_${target_name}" ]]; then
                DISK_BLOCK_MAP[b]="FREE"
            fi
        done

        unset "FILE_NAMES[$(( del_idx - 1 ))]"
        unset "FILE_TYPES[$(( del_idx - 1 ))]"
        unset "FILE_DETAILS[$(( del_idx - 1 ))]"
        FILE_NAMES=("${FILE_NAMES[@]}")
        FILE_TYPES=("${FILE_TYPES[@]}")
        FILE_DETAILS=("${FILE_DETAILS[@]}")

        msg_success "File '${target_name}' deleted and its blocks freed."
        display_disk_map
        pause_screen
    fi
}
