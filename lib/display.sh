#!/usr/bin/env bash
# ==============================================================================
# lib/display.sh - Terminal UI formatting, tables, and ASCII Gantt chart renderer
# ==============================================================================

# Print clear screen and header banner
show_banner() {
    local title="$1"
    local subtitle="${2:-}"
    clear 2>/dev/null || echo -e "\n\n"
    echo -e "${COLOR_BLUE}================================================================================"
    echo -e "  ${COLOR_BOLD}${APP_NAME}${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}${title}${COLOR_RESET}"
    if [[ -n "$subtitle" ]]; then
        echo -e "  ${COLOR_DIM}${subtitle}${COLOR_RESET}"
    fi
    echo -e "${COLOR_BLUE}================================================================================${COLOR_RESET}\n"
}

# Section header
print_section() {
    local title="$1"
    echo -e "\n${COLOR_MAGENTA}${COLOR_BOLD}--- ${title} ---${COLOR_RESET}"
}

# Message helpers
msg_info()    { echo -e "${COLOR_CYAN}[INFO]${COLOR_RESET} $1"; }
msg_success() { echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $1"; }
msg_warn()    { echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $1"; }
msg_error()   { echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"; }

# Print a divider line
print_divider() {
    local len="${1:-80}"
    printf '%*s\n' "$len" '' | tr ' ' '-'
}

# Print horizontal double border
print_double_divider() {
    local len="${1:-80}"
    printf '%*s\n' "$len" '' | tr ' ' '='
}

# ASCII Gantt Chart Renderer
# Takes two parallel arrays:
# $1: array of block labels (e.g. "P1" "IDLE" "P2" "P1")
# $2: array of block start and finish times. Specifically, if N blocks,
#     there are N+1 time boundaries or pairs.
# Recommended invocation:
# render_gantt_chart block_labels_array start_times_array end_times_array
render_gantt_chart() {
    local -n _labels=$1
    local -n _starts=$2
    local -n _ends=$3
    local count=${#_labels[@]}

    if (( count == 0 )); then
        echo -e "${COLOR_DIM}(No execution timeline to display)${COLOR_RESET}"
        return
    fi

    echo -e "\n${COLOR_BOLD}Execution Gantt Chart:${COLOR_RESET}"

    # Top border
    echo -ne "  +"
    for (( i=0; i<count; i++ )); do
        local label="${_labels[i]}"
        local width=$(( ${#label} + 4 ))
        (( width < 7 )) && width=7
        for (( w=0; w<width; w++ )); do echo -n "-"; done
        echo -n "+"
    done
    echo ""

    # Process names / IDLE
    echo -ne "  |"
    for (( i=0; i<count; i++ )); do
        local label="${_labels[i]}"
        local width=$(( ${#label} + 4 ))
        (( width < 7 )) && width=7
        
        if [[ "$label" == "IDLE" ]]; then
            printf "${COLOR_DIM} %-${width}s${COLOR_RESET}|" "IDLE"
        else
            printf "${COLOR_GREEN}${COLOR_BOLD} %-${width}s${COLOR_RESET}|" "$label"
        fi
    done
    echo ""

    # Bottom border
    echo -ne "  +"
    for (( i=0; i<count; i++ )); do
        local label="${_labels[i]}"
        local width=$(( ${#label} + 4 ))
        (( width < 7 )) && width=7
        for (( w=0; w<width; w++ )); do echo -n "-"; done
        echo -n "+"
    done
    echo ""

    # Timeline numbers below
    echo -ne "  "
    printf "%-2s" "${_starts[0]}"
    for (( i=0; i<count; i++ )); do
        local label="${_labels[i]}"
        local width=$(( ${#label} + 4 ))
        (( width < 7 )) && width=7
        local pad=$(( width - 1 ))
        local end_time="${_ends[i]}"
        printf "%*s%-2s" "$pad" "" "$end_time"
    done
    echo -e "\n"
}
