#!/usr/bin/env bash
# ==============================================================================
# OS Resource Management & Simulation Suite
# config.sh - Global configuration, paths, and display styles
# ==============================================================================

# Determine base directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OS_SIM_ROOT="${SCRIPT_DIR}"
export REPORTS_DIR="${OS_SIM_ROOT}/reports"
export DOCS_DIR="${OS_SIM_ROOT}/docs"

# Ensure reports directory exists
mkdir -p "${REPORTS_DIR}"

# ANSI Color Codes
if [[ -t 1 ]]; then
    export COLOR_RESET="\033[0m"
    export COLOR_BOLD="\033[1m"
    export COLOR_DIM="\033[2m"
    export COLOR_RED="\033[31m"
    export COLOR_GREEN="\033[32m"
    export COLOR_YELLOW="\033[33m"
    export COLOR_BLUE="\033[34m"
    export COLOR_MAGENTA="\033[35m"
    export COLOR_CYAN="\033[36m"
    export COLOR_WHITE="\033[37m"
    export BG_BLUE="\033[44m"
    export BG_DARK="\033[40m"
else
    export COLOR_RESET=""
    export COLOR_BOLD=""
    export COLOR_DIM=""
    export COLOR_RED=""
    export COLOR_GREEN=""
    export COLOR_YELLOW=""
    export COLOR_BLUE=""
    export COLOR_MAGENTA=""
    export COLOR_CYAN=""
    export COLOR_WHITE=""
    export BG_BLUE=""
    export BG_DARK=""
fi

# Application metadata
export APP_NAME="OS Resource Management & Simulation Suite"
export APP_VERSION="1.0.0"

# Simulation constants
export MAX_PROCESSES=20
export MAX_MEMORY_BLOCKS=20
export MAX_PAGES=50
export MAX_FRAMES=10
export MAX_DISK_REQUESTS=30
export DEFAULT_DISK_CYLINDERS=200
export REPORT_CSV="${REPORTS_DIR}/simulations.csv"

# Initialize report CSV if not exists
if [[ ! -f "${REPORT_CSV}" ]]; then
    echo "timestamp,module,algorithm,input_summary,result_summary,notes" > "${REPORT_CSV}"
fi
