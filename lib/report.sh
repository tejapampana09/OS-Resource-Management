#!/usr/bin/env bash
# ==============================================================================
# lib/report.sh - Shared reporting, CSV persistence, and execution trace logger
# ==============================================================================

# Append simulation record to shared CSV
# Usage: log_simulation_csv "cpu" "FCFS" "P1:0:5;P2:1:3" "avg_wt=2.0;avg_tat=5.0" "test run"
log_simulation_csv() {
    local module="$1"
    local algorithm="$2"
    local input_summary="$3"
    local result_summary="$4"
    local notes="${5:-None}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Ensure CSV exists
    if [[ ! -f "${REPORT_CSV}" ]]; then
        echo "timestamp,module,algorithm,input_summary,result_summary,notes" > "${REPORT_CSV}"
    fi

    # Escape quotes
    input_summary="${input_summary//\"/\"\"}"
    result_summary="${result_summary//\"/\"\"}"
    notes="${notes//\"/\"\"}"

    echo "${timestamp},${module},${algorithm},\"${input_summary}\",\"${result_summary}\",\"${notes}\"" >> "${REPORT_CSV}"
    msg_success "Appended run record to ${REPORT_CSV}"
}

# Save detailed text trace to reports/
# Usage: save_detailed_trace "cpu" "FCFS" "text content..."
save_detailed_trace() {
    local module="$1"
    local algorithm="$2"
    local content="$3"
    local file_ts
    file_ts=$(date +"%Y%m%d_%H%M%S")
    local filename="${REPORTS_DIR}/${file_ts}_${module}_${algorithm}.txt"

    {
        echo "================================================================================"
        echo "OS Simulation Suite - Detailed Execution Report"
        echo "Module:    ${module}"
        echo "Algorithm: ${algorithm}"
        echo "Generated: $(date)"
        echo "================================================================================"
        echo ""
        echo -e "${content}"
        echo ""
        echo "================================================================================"
        echo "End of Report"
        echo "================================================================================"
    } > "${filename}"

    msg_success "Detailed trace report saved to: ${filename}"
}

# Interactive Report Browser
view_saved_reports() {
    show_banner "Simulation Reports Browser" "Review past execution runs and CSV records"

    echo -e "${COLOR_BOLD}1. View Recent CSV Summary Records (Last 15)${COLOR_RESET}"
    echo -e "${COLOR_BOLD}2. Browse & Read Detailed Text Traces${COLOR_RESET}"
    echo -e "${COLOR_BOLD}3. Clear All Reports (Caution)${COLOR_RESET}"
    echo -e "${COLOR_BOLD}0. Back to Main Menu${COLOR_RESET}"
    echo ""

    local choice
    read_int "Select option" choice 0 3 1

    case "$choice" in
        1)
            show_banner "CSV Summary Records" "${REPORT_CSV}"
            if [[ -f "${REPORT_CSV}" ]]; then
                column -s, -t < "${REPORT_CSV}" 2>/dev/null || cat "${REPORT_CSV}"
            else
                echo "No CSV reports logged yet."
            fi
            pause_screen
            ;;
        2)
            show_banner "Detailed Trace Files" "${REPORTS_DIR}"
            local files=()
            while IFS= read -r file; do
                [[ -n "$file" ]] && files+=("$file")
            done < <(find "${REPORTS_DIR}" -type f -name "*.txt" | sort -r)

            if (( ${#files[@]} == 0 )); then
                echo "No detailed trace reports found."
                pause_screen
                return 0
            fi

            echo -e "${COLOR_CYAN}Available trace files:${COLOR_RESET}"
            for (( i=0; i<${#files[@]}; i++ )); do
                echo -e "  [$(( i + 1 ))] $(basename "${files[i]}")"
            done
            echo "  [0] Cancel"
            echo ""

            local sel
            read_int "Select file number to view" sel 0 "${#files[@]}" 0
            if (( sel > 0 )); then
                local selected_file="${files[$(( sel - 1 ))]}"
                show_banner "Viewing Trace" "$(basename "${selected_file}")"
                cat "${selected_file}"
                pause_screen
            fi
            ;;
        3)
            if confirm_action "Are you sure you want to delete all saved reports?"; then
                rm -f "${REPORTS_DIR}"/*.txt
                echo "timestamp,module,algorithm,input_summary,result_summary,notes" > "${REPORT_CSV}"
                msg_success "All reports cleared."
            else
                msg_info "Aborted."
            fi
            pause_screen
            ;;
        0)
            return 0
            ;;
    esac
}
