#!/usr/bin/env bash
# ==============================================================================
# tests/test_runner.sh - Automated Verification Test Suite
# Tests every algorithm against known answers and edge cases
# ==============================================================================

# Do not use set -e because (( var++ )) evaluating to 0 triggers exit in bash
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${SCRIPT_DIR}"

source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib/input.sh"
source "${SCRIPT_DIR}/lib/display.sh"
source "${SCRIPT_DIR}/lib/report.sh"
source "${SCRIPT_DIR}/modules/cpu/fcfs.sh"
source "${SCRIPT_DIR}/modules/cpu/sjf.sh"
source "${SCRIPT_DIR}/modules/cpu/srtf.sh"
source "${SCRIPT_DIR}/modules/cpu/priority.sh"
source "${SCRIPT_DIR}/modules/cpu/round_robin.sh"
source "${SCRIPT_DIR}/modules/memory/allocation.sh"
source "${SCRIPT_DIR}/modules/memory/paging.sh"
source "${SCRIPT_DIR}/modules/safety/banker.sh"
source "${SCRIPT_DIR}/modules/safety/deadlock.sh"
source "${SCRIPT_DIR}/modules/storage/disk.sh"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

assert_equal() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    TOTAL_TESTS=$(( TOTAL_TESTS + 1 ))

    if [[ "$expected" == "$actual" ]]; then
        echo -e "  ${COLOR_GREEN}[PASS]${COLOR_RESET} ${test_name} (Got: ${actual})"
        PASSED_TESTS=$(( PASSED_TESTS + 1 ))
    else
        echo -e "  ${COLOR_RED}[FAIL] ${test_name}${COLOR_RESET}: Expected '${expected}', got '${actual}'"
        FAILED_TESTS=$(( FAILED_TESTS + 1 ))
    fi
}

echo -e "\n${COLOR_BOLD}================================================================================${COLOR_RESET}"
echo -e "${COLOR_BOLD}     RUNNING OS SIMULATION AUTOMATED ACCEPTANCE TEST SUITE                       ${COLOR_RESET}"
echo -e "${COLOR_BOLD}================================================================================${COLOR_RESET}\n"

# ------------------------------------------------------------------------------
# Test Suite 1: CPU Scheduling
# ------------------------------------------------------------------------------
print_section "1. CPU Scheduling Known-Answer Tests"

# Test 1.1: FCFS with Idle Gap
# P1(AT=0, BT=3) -> CT=3; P2(AT=5, BT=2) -> start at 5, CT=7.
# TAT: P1=3, P2=2. Avg TAT = 2.50. WT: P1=0, P2=0. Avg WT = 0.00.
run_cpu_fcfs "--preset" 2 "P1 P2" "0 5" "3 2" > /dev/null
assert_equal "CPU FCFS with Idle Gap (Avg WT)" "0.00" "$LAST_AVG_WT"
assert_equal "CPU FCFS with Idle Gap (Avg TAT)" "2.50" "$LAST_AVG_TAT"

# Test 1.2: SJF Non-preemptive
# P1(AT=0, BT=4), P2(AT=1, BT=2), P3(AT=2, BT=1)
# At t=0: P1 runs until t=4.
# At t=4: P2(BT=2), P3(BT=1) available -> P3 runs till t=5, P2 runs till t=7.
# CT: P1=4, P3=5, P2=7.
# TAT: P1=4-0=4, P2=7-1=6, P3=5-2=3. Total TAT = 13. Avg TAT = 4.33
# WT: P1=0, P2=4, P3=2. Total WT = 6. Avg WT = 2.00
run_cpu_sjf "--preset" 3 "P1 P2 P3" "0 1 2" "4 2 1" > /dev/null
assert_equal "CPU SJF Non-preemptive (Avg WT)" "2.00" "$LAST_AVG_WT"
assert_equal "CPU SJF Non-preemptive (Avg TAT)" "4.33" "$LAST_AVG_TAT"

# Test 1.3: SRTF Preemptive
# P1(AT=0, BT=8), P2(AT=1, BT=4)
# At t=1: P1 has 7 left, P2 has 4 -> P2 preempts P1!
# P2 runs till t=5. Then P1 finishes at t=12.
# TAT: P1=12, P2=4. Avg TAT = 8.00. WT: P1=4, P2=0. Avg WT = 2.00
run_cpu_srtf "--preset" 2 "P1 P2" "0 1" "8 4" > /dev/null
assert_equal "CPU SRTF Preemption (Avg WT)" "2.00" "$LAST_AVG_WT"
assert_equal "CPU SRTF Preemption (Avg TAT)" "8.00" "$LAST_AVG_TAT"

# Test 1.4: Round Robin with arrival at slice boundary
# P1(AT=0, BT=4), P2(AT=2, BT=2), Quantum=2
# t=0..2: P1 runs. At t=2, P2 arrives. P2 enters queue, then P1 requeues.
# Ready queue: P2, P1.
# t=2..4: P2 runs and completes! CT(P2)=4.
# t=4..6: P1 runs and completes! CT(P1)=6.
# TAT: P1=6, P2=2. Avg TAT = 4.00. WT: P1=2, P2=0. Avg WT = 1.00
run_cpu_round_robin "--preset" 2 "P1 P2" "0 2" "4 2" 2 > /dev/null
assert_equal "CPU Round Robin Boundary Queueing (Avg WT)" "1.00" "$LAST_AVG_WT"
assert_equal "CPU Round Robin Boundary Queueing (Avg TAT)" "4.00" "$LAST_AVG_TAT"

# ------------------------------------------------------------------------------
# Test Suite 2: Memory Management & Paging
# ------------------------------------------------------------------------------
print_section "2. Memory Management & Paging Known-Answer Tests"

# Test 2.1: FIFO Page Replacement
# Ref: 7 0 1 2 0 3 0 4 2 3 0 3 2 1 2 0 1 7 0 1, Frames: 3
# Known textbook result: 15 Page Faults
run_page_replacement "fifo" 3 "7 0 1 2 0 3 0 4 2 3 0 3 2 1 2 0 1 7 0 1" true
assert_equal "FIFO Page Faults (3 frames, 20 refs)" "15" "$LAST_PAGE_FAULTS"

# Test 2.2: LRU Page Replacement
# Known textbook result: 12 Page Faults
run_page_replacement "lru" 3 "7 0 1 2 0 3 0 4 2 3 0 3 2 1 2 0 1 7 0 1" true
assert_equal "LRU Page Faults (3 frames, 20 refs)" "12" "$LAST_PAGE_FAULTS"

# Test 2.3: Optimal Page Replacement
# Known textbook result: 9 Page Faults
run_page_replacement "optimal" 3 "7 0 1 2 0 3 0 4 2 3 0 3 2 1 2 0 1 7 0 1" true
assert_equal "Optimal Page Faults (3 frames, 20 refs)" "9" "$LAST_PAGE_FAULTS"

# Test 2.4: Contiguous Memory Allocation
export -a PRESET_BLOCKS=(100 500 200 300 600)
export -a PRESET_PROCS=(212 417 112 426)
run_memory_allocation_sim "best_fit" "fixed" "true" > /dev/null
assert_equal "Memory Best Fit Allocated Process Count" "4" "$LAST_ALLOCATED_COUNT"

# ------------------------------------------------------------------------------
# Test Suite 3: Deadlocks & Safety
# ------------------------------------------------------------------------------
print_section "3. Deadlock Algorithms Known-Answer Tests"

# Test 3.1: Banker's Algorithm Safe State
run_bankers_algorithm "safe" > /tmp/banker_safe.log
if grep -q "\[SAFE STATE\]" /tmp/banker_safe.log; then
    assert_equal "Banker's Algorithm on Safe State" "SAFE" "SAFE"
else
    assert_equal "Banker's Algorithm on Safe State" "SAFE" "UNSAFE"
fi

# Test 3.2: Banker's Algorithm Unsafe State
run_bankers_algorithm "unsafe" > /tmp/banker_unsafe.log
if grep -q "\[UNSAFE STATE\]" /tmp/banker_unsafe.log; then
    assert_equal "Banker's Algorithm on Unsafe State" "UNSAFE" "UNSAFE"
else
    assert_equal "Banker's Algorithm on Unsafe State" "UNSAFE" "SAFE"
fi

# Test 3.3: Deadlock Detection on Deadlocked State
run_deadlock_detection "deadlocked" > /tmp/deadlock_det.log
if grep -q "\[DEADLOCK DETECTED!\]" /tmp/deadlock_det.log; then
    assert_equal "Deadlock Detection Cycle Test" "DEADLOCKED" "DEADLOCKED"
else
    assert_equal "Deadlock Detection Cycle Test" "DEADLOCKED" "NO_DEADLOCK"
fi

# ------------------------------------------------------------------------------
# Test Suite 4: Disk Scheduling
# ------------------------------------------------------------------------------
print_section "4. Disk Scheduling Known-Answer Tests"

# Silberschatz Queue: 98 183 37 122 14 124 65 67, Initial Head: 53
# FCFS: 53 -> 98(45) -> 183(85) -> 37(146) -> 122(85) -> 14(108) -> 124(110) -> 65(59) -> 67(2)
# Total FCFS Seek = 45+85+146+85+108+110+59+2 = 640
run_disk_algorithm "fcfs" 53 199 "up" "98 183 37 122 14 124 65 67" true
assert_equal "Disk FCFS Total Head Movement" "640" "$LAST_DISK_SEEK"

# SSTF: 53 -> 65(12) -> 67(2) -> 37(30) -> 14(23) -> 98(84) -> 122(24) -> 124(2) -> 183(59)
# Total SSTF Seek = 12+2+30+23+84+24+2+59 = 236
run_disk_algorithm "sstf" 53 199 "up" "98 183 37 122 14 124 65 67" true
assert_equal "Disk SSTF Total Head Movement" "236" "$LAST_DISK_SEEK"

# SCAN (Up, 0..199): 53 -> 65(12) -> 67(2) -> 98(31) -> 122(24) -> 124(2) -> 183(59) -> 199(16) -> 37(162) -> 14(23)
# Total SCAN Seek = (199 - 53) + (199 - 14) = 146 + 185 = 331
run_disk_algorithm "scan" 53 199 "up" "98 183 37 122 14 124 65 67" true
assert_equal "Disk SCAN Total Head Movement" "331" "$LAST_DISK_SEEK"

# LOOK (Up, reversing at last request 183):
# 53 -> 65 -> 67 -> 98 -> 122 -> 124 -> 183 -> 37 -> 14
# Total LOOK Seek = (183 - 53) + (183 - 14) = 130 + 169 = 299
run_disk_algorithm "look" 53 199 "up" "98 183 37 122 14 124 65 67" true
assert_equal "Disk LOOK Total Head Movement" "299" "$LAST_DISK_SEEK"

# ------------------------------------------------------------------------------
# Test Summary
# ------------------------------------------------------------------------------
echo -e "\n================================================================================"
echo -e "TEST EXECUTION SUMMARY:"
echo -e "  Total Tests  : ${TOTAL_TESTS}"
echo -e "  Passed Tests : ${COLOR_GREEN}${PASSED_TESTS}${COLOR_RESET}"
echo -e "  Failed Tests : ${COLOR_RED}${FAILED_TESTS}${COLOR_RESET}"
echo -e "================================================================================\n"

if (( FAILED_TESTS > 0 )); then
    exit 1
fi
exit 0
