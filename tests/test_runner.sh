#!/usr/bin/env bash
# ==============================================================================
# tests/test_runner.sh - Automated Verification Test Suite
# Tests every algorithm against known answers and edge cases
# ==============================================================================

# Do not use set -e because (( var++ )) evaluating to 0 triggers exit in bash
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${SCRIPT_DIR}"

test_dir=$(mktemp -d) || exit 1
trap 'rm -rf -- "$test_dir"' EXIT
export REPORTS_DIR="$test_dir"
export REPORT_CSV="$test_dir/simulations.csv"
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
source "${SCRIPT_DIR}/modules/safety/synchronization.sh"
source "${SCRIPT_DIR}/modules/system_monitor.sh"
source "${SCRIPT_DIR}/modules/storage/disk.sh"
source "${SCRIPT_DIR}/modules/storage/file_allocation.sh"

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

# P3 arrives before P2 during P1's first slice, despite being entered later.
run_cpu_round_robin "--preset" 3 "P1 P2 P3" "0 3 1" "5 3 1" 4 > /dev/null
assert_equal "CPU Round Robin Chronological Arrivals (Avg WT)" "3.00" "$LAST_AVG_WT"
run_cpu_priority "--preset" 3 "P1 P2 P3" "0 1 2" "4 3 1" "2 1 3" "non-preemptive" > /dev/null
assert_equal "Priority Non-preemptive Average WT" "2.67" "$LAST_AVG_WT"
assert_equal "Priority Non-preemptive Average TAT" "5.33" "$LAST_AVG_TAT"
run_cpu_priority "--preset" 3 "P1 P2 P3" "0 1 2" "8 4 1" "2 1 0" "preemptive" > /dev/null
assert_equal "Priority Preemptive Average WT" "2.00" "$LAST_AVG_WT"
assert_equal "Priority Preemptive Average TAT" "6.33" "$LAST_AVG_TAT"

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
if run_page_replacement "clock" 3 "1 2 3" true > /dev/null 2>&1; then status=0; else status=$?; fi
assert_equal "Paging Rejects Unsupported Policy" "1" "$status"
if run_page_replacement "fifo" 3 "1 -2 3" true > /dev/null 2>&1; then status=0; else status=$?; fi
assert_equal "Paging Rejects Negative Page Reference" "1" "$status"
if run_page_replacement "fifo" 0 "1 2 3" true > /dev/null 2>&1; then status=0; else status=$?; fi
assert_equal "Paging Rejects Zero Frames" "1" "$status"
if run_page_replacement "fifo" 11 "1 2 3" true > /dev/null 2>&1; then status=0; else status=$?; fi
assert_equal "Paging Rejects Frames Above Configured Maximum" "1" "$status"

# Test 2.4: Contiguous Memory Allocation
export -a PRESET_BLOCKS=(100 500 200 300 600)
export -a PRESET_PROCS=(212 417 112 426)
run_memory_allocation_sim "best_fit" "fixed" "true" > /dev/null
assert_equal "Memory Best Fit Allocated Process Count" "4" "$LAST_ALLOCATED_COUNT"
run_memory_allocation_sim "first_fit" "fixed" "true" > /dev/null
assert_equal "Memory First Fit Allocated Process Count" "3" "$LAST_ALLOCATED_COUNT"
run_memory_allocation_sim "worst_fit" "fixed" "true" > /dev/null
assert_equal "Memory Worst Fit Allocated Process Count" "3" "$LAST_ALLOCATED_COUNT"
run_memory_allocation_sim "best_fit" "variable" "true" > /dev/null
assert_equal "Memory Best Fit Variable Allocated Process Count" "4" "$LAST_ALLOCATED_COUNT"
if run_memory_allocation_sim "unknown" "fixed" "true" > /dev/null 2>&1; then status=0; else status=$?; fi
assert_equal "Memory Rejects Unsupported Allocation Policy" "1" "$status"

# ------------------------------------------------------------------------------
# Test Suite 3: Deadlocks & Safety
# ------------------------------------------------------------------------------
print_section "3. Deadlock Algorithms Known-Answer Tests"

# Test 3.1: Banker's Algorithm Safe State
run_bankers_algorithm "safe" > "$test_dir/banker_safe.log"
if grep -q "\[SAFE STATE\]" "$test_dir/banker_safe.log"; then
    assert_equal "Banker's Algorithm on Safe State" "SAFE" "SAFE"
else
    assert_equal "Banker's Algorithm on Safe State" "SAFE" "UNSAFE"
fi

# Test 3.2: Banker's Algorithm Unsafe State
run_bankers_algorithm "unsafe" > "$test_dir/banker_unsafe.log"
if grep -q "\[UNSAFE STATE\]" "$test_dir/banker_unsafe.log"; then
    assert_equal "Banker's Algorithm on Unsafe State" "UNSAFE" "UNSAFE"
else
    assert_equal "Banker's Algorithm on Unsafe State" "UNSAFE" "SAFE"
fi

# Test 3.3: Deadlock Detection on Deadlocked State
run_deadlock_detection "deadlocked" > "$test_dir/deadlock_det.log"
if grep -q "\[DEADLOCK DETECTED!\]" "$test_dir/deadlock_det.log"; then
    assert_equal "Deadlock Detection Cycle Test" "DEADLOCKED" "DEADLOCKED"
else
    assert_equal "Deadlock Detection Cycle Test" "DEADLOCKED" "NO_DEADLOCK"
fi

# ------------------------------------------------------------------------------
# Test Suite 4: Disk Scheduling
# ------------------------------------------------------------------------------
run_deadlock_detection "nodeadlock" > "$test_dir/no_deadlock.log"
if grep -q "\[NO DEADLOCK DETECTED\]" "$test_dir/no_deadlock.log"; then
    assert_equal "Deadlock Detection Safe Completion Test" "NO_DEADLOCK" "NO_DEADLOCK"
else
    assert_equal "Deadlock Detection Safe Completion Test" "NO_DEADLOCK" "DEADLOCKED"
fi
if run_deadlock_detection false <<< $'1\n1\n0\n1\n2\n' > /dev/null 2>&1; then status=0; else status=$?; fi
assert_equal "Deadlock Detection Rejects Impossible Resource Request" "1" "$status"

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
run_disk_algorithm "c-scan" 53 199 "up" "98 183 37 122 14 124 65 67" true
assert_equal "Disk C-SCAN Up Total Head Movement" "382" "$LAST_DISK_SEEK"
run_disk_algorithm "c-scan" 53 199 "down" "98 183 37 122 14 124 65 67" true
assert_equal "Disk C-SCAN Down Total Head Movement" "386" "$LAST_DISK_SEEK"

run_disk_algorithm "look" 50 199 "down" "50 40 60" false > "$test_dir/look.log"
assert_equal "Disk LOOK Down Services Initial Head First" "50 -> 50 -> 40 -> 60" "$(awk '/ -> / { sub(/^ +/, ""); print }' "$test_dir/look.log")"
run_disk_algorithm "fcfs" 250 199 "up" "10" true > /dev/null 2>&1
assert_equal "Disk Rejects Head Beyond Final Cylinder" "1" "$?"
if run_disk_algorithm "fcfs" 50 199 "up" "10 200" true > /dev/null 2>&1; then status=0; else status=$?; fi
assert_equal "Disk Rejects Request Beyond Final Cylinder" "1" "$status"
if run_disk_algorithm "unknown" 50 199 "up" "10" true > /dev/null 2>&1; then status=0; else status=$?; fi
assert_equal "Disk Rejects Unsupported Algorithm" "1" "$status"
if run_disk_algorithm "fcfs" 50 199 "sideways" "10" true > /dev/null 2>&1; then status=0; else status=$?; fi
assert_equal "Disk Rejects Invalid Direction" "1" "$status"

print_section "5. File Allocation and Input Regression Tests"

init_file_system
run_contiguous_allocation_demo <<< $'same\n2\n' > /dev/null
run_linked_allocation_demo <<< $'same\nFREE\nIDX_other\nother\n2\n' > /dev/null
assert_equal "File Allocation Rejects Duplicate and Reserved Names" "same other" "${FILE_NAMES[*]}"
list_and_delete_files <<< $'1\n1\n' > /dev/null
assert_equal "File Deletion Preserves Another File's Blocks" "FREE FREE other other" "${DISK_BLOCK_MAP[*]:0:4}"

init_file_system
run_indexed_allocation_demo <<< $'indexed\n2\n\n' > /dev/null
assert_equal "Indexed Allocation Reserves Index Block" "IDX_indexed" "${DISK_BLOCK_MAP[0]}"
assert_equal "Indexed Allocation Reserves Data Blocks" "indexed indexed" "${DISK_BLOCK_MAP[1]} ${DISK_BLOCK_MAP[2]}"
list_and_delete_files <<< $'1\n1\n\n' > /dev/null
assert_equal "Indexed File Deletion Frees Index and Data Blocks" "FREE FREE FREE" "${DISK_BLOCK_MAP[*]:0:3}"

read_int "Enter a number" actual_num 0 10 <<< $'18446744073709551624\n08' > /dev/null
assert_equal "Integer Input Rejects Overflow and Normalizes Decimal" "8" "$actual_num"
read_int_array "Enter numbers" actual_nums 0 20 <<< $'08\t010' > /dev/null
assert_equal "Integer Array Input Normalizes Decimal" "8 10" "${actual_nums[*]}"

for (( record=1; record<=20; record++ )); do
    log_simulation_csv "test" "TEST_RECORD_$record" "" "" > /dev/null
done
view_saved_reports <<< $'1\n' > "$test_dir/recent.log"
assert_equal "Report Browser Displays Only the Latest 15 Records" "15" "$(grep -c 'TEST_RECORD_' "$test_dir/recent.log")"

save_detailed_trace "test" "COLLISION" "first trace" > /dev/null
save_detailed_trace "test" "COLLISION" "second trace" > /dev/null
assert_equal "Detailed Trace Writer Preserves Consecutive Runs" "2" "$(find "$test_dir" -maxdepth 1 -type f -name '*_test_COLLISION.txt' | wc -l | tr -d ' ')"

print_section "6. Synchronization & Host Safety Tests"
test_sync_valid_state() {
    local buffer_size=5 mutex=1 empty_slots=5 full_slots=0 in_idx=0 out_idx=0
    local -a buffer=(EMPTY EMPTY EMPTY EMPTY EMPTY)
    synchronization_state_is_valid
}
test_sync_full_state() {
    local buffer_size=5 mutex=1 empty_slots=0 full_slots=5 in_idx=0 out_idx=0
    local -a buffer=(A B C D E)
    synchronization_state_is_valid
}
test_sync_invalid_counter_state() {
    local buffer_size=5 mutex=1 empty_slots=1 full_slots=5 in_idx=0 out_idx=0
    local -a buffer=(A B C D E)
    synchronization_state_is_valid
}
if test_sync_valid_state; then status=0; else status=1; fi
assert_equal "Synchronization Accepts Empty Buffer State" "0" "$status"
if test_sync_full_state; then status=0; else status=1; fi
assert_equal "Synchronization Accepts Full Buffer State" "0" "$status"
if test_sync_invalid_counter_state; then status=0; else status=1; fi
assert_equal "Synchronization Rejects Inconsistent Semaphore Counts" "1" "$status"

show_live_processes < <(printf '4\n1\n') > "$test_dir/monitor_pid1.log"
if grep -q "Cannot terminate PID 1" "$test_dir/monitor_pid1.log"; then status=0; else status=1; fi
assert_equal "System Monitor Protects PID 1" "0" "$status"
self_pid="$BASHPID"
show_live_processes < <(printf '4\n%s\n' "$self_pid") > "$test_dir/monitor_self.log"
if grep -q "Cannot terminate the simulator process" "$test_dir/monitor_self.log"; then status=0; else status=1; fi
assert_equal "System Monitor Protects Its Own Process" "0" "$status"
parent_pid=$(ps -o ppid= -p "$self_pid" | tr -d '[:space:]')
show_live_processes < <(printf '4\n%s\n' "$parent_pid") > "$test_dir/monitor_parent.log"
if grep -q "Cannot terminate the parent terminal" "$test_dir/monitor_parent.log"; then status=0; else status=1; fi
assert_equal "System Monitor Protects Parent Terminal" "0" "$status"

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

