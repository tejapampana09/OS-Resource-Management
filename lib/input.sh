#!/usr/bin/env bash
# ==============================================================================
# lib/input.sh - Input validation and safe reader utilities
# ==============================================================================

# Check if a value is an integer (positive, negative, or zero)
is_integer() {
    local val="$1"
    [[ "$val" =~ ^-?[0-9]+$ ]]
}

# Check if a value is a non-negative integer (>= 0)
is_non_negative_integer() {
    local val="$1"
    [[ "$val" =~ ^[0-9]+$ ]]
}

# Check if a value is a positive integer (> 0)
is_positive_integer() {
    local val="$1"
    [[ "$val" =~ ^[0-9]+$ ]] && (( val > 0 ))
}

# Prompt user for an integer with bounds and optional default
# Usage: read_int "Enter process count" result_var [min] [max] [default]
read_int() {
    local prompt="$1"
    local var_name="$2"
    local min="${3:-}"
    local max="${4:-}"
    local default_val="${5:-}"
    local user_input

    while true; do
        if [[ -n "$default_val" ]]; then
            echo -ne "${COLOR_CYAN}${prompt} [default: ${default_val}]: ${COLOR_RESET}"
        else
            echo -ne "${COLOR_CYAN}${prompt}: ${COLOR_RESET}"
        fi

        read -r user_input || return 1
        user_input="${user_input:-$default_val}"

        if [[ -z "$user_input" ]]; then
            echo -e "${COLOR_RED}Error: Input cannot be empty.${COLOR_RESET}"
            continue
        fi

        if ! is_integer "$user_input"; then
            echo -e "${COLOR_RED}Error: Value must be a valid integer.${COLOR_RESET}"
            continue
        fi

        if [[ -n "$min" ]] && (( user_input < min )); then
            echo -e "${COLOR_RED}Error: Value must be >= ${min}.${COLOR_RESET}"
            continue
        fi

        if [[ -n "$max" ]] && (( user_input > max )); then
            echo -e "${COLOR_RED}Error: Value must be <= ${max}.${COLOR_RESET}"
            continue
        fi

        printf -v "$var_name" "%s" "$user_input"
        return 0
    done
}

# Prompt user for space-separated integers
# Usage: read_int_array "Enter page reference string" array_var [min_element] [max_element] [expected_count]
read_int_array() {
    local prompt="$1"
    local array_var="$2"
    local min_val="${3:-}"
    local max_val="${4:-}"
    local expected_count="${5:-}"
    local input_str
    local -a parsed

    while true; do
        echo -ne "${COLOR_CYAN}${prompt}: ${COLOR_RESET}"
        read -r input_str || return 1

        if [[ -z "$input_str" ]]; then
            echo -e "${COLOR_RED}Error: Input cannot be empty.${COLOR_RESET}"
            continue
        fi

        # Split string by whitespace
        # shellcheck disable=SC2206
        parsed=($input_str)

        if [[ -n "$expected_count" ]] && (( ${#parsed[@]} != expected_count )); then
            echo -e "${COLOR_RED}Error: Expected exactly ${expected_count} values, got ${#parsed[@]}.${COLOR_RESET}"
            continue
        fi

        local valid=true
        for val in "${parsed[@]}"; do
            if ! is_integer "$val"; then
                echo -e "${COLOR_RED}Error: '${val}' is not an integer.${COLOR_RESET}"
                valid=false
                break
            fi
            if [[ -n "$min_val" ]] && (( val < min_val )); then
                echo -e "${COLOR_RED}Error: Element '${val}' is less than minimum ${min_val}.${COLOR_RESET}"
                valid=false
                break
            fi
            if [[ -n "$max_val" ]] && (( val > max_val )); then
                echo -e "${COLOR_RED}Error: Element '${val}' exceeds maximum ${max_val}.${COLOR_RESET}"
                valid=false
                break
            fi
        done

        if $valid; then
            eval "${array_var}=(\"\${parsed[@]}\")"
            return 0
        fi
    done
}

# Yes/No confirmation prompt
confirm_action() {
    local prompt="${1:-Are you sure?}"
    local response
    while true; do
        echo -ne "${COLOR_YELLOW}${prompt} (y/n): ${COLOR_RESET}"
        read -r response || return 1
        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo -e "${COLOR_RED}Please answer 'y' or 'n'.${COLOR_RESET}" ;;
        esac
    done
}

# Wait for user enter key before continuing
pause_screen() {
    local msg="${1:-Press [Enter] to return to menu...}"
    echo ""
    echo -ne "${COLOR_DIM}${msg}${COLOR_RESET}"
    read -r
}
