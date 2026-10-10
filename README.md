# OS Resource Management & Simulation Suite

> **Full Project Implementation & Academic Blueprint**  
> Bash Shell Scripting • Linux Utilities • OS Algorithms

---

## 📋 Overview

The **OS Resource Management & Simulation Suite** is an interactive, menu-driven academic toolkit developed in pure GNU Bash. It models fundamental Operating System scheduling and resource allocation algorithms with mathematical accuracy while providing read-only live host telemetry from the underlying Linux environment.

### Key Capabilities
- **CPU Scheduling**: FCFS, Non-preemptive SJF, Preemptive SRTF, Priority (preemptive & non-preemptive), and Round Robin with ASCII Gantt charts, completion time (CT), turnaround time (TAT), waiting time (WT), and response time (RT).
- **Memory Management & Virtual Memory**: Contiguous partition allocation (First Fit, Best Fit, Worst Fit with internal & external fragmentation analysis) and Page Replacement (FIFO, LRU, Optimal) with aligned step-by-step frame trace tables.
- **Deadlocks & Process Synchronization**: Banker's Safety Algorithm, Matrix-based Deadlock Detection, and a Producer-Consumer bounded-buffer simulation demonstrating Semaphores, Mutex locks, and the 4 Coffman conditions.
- **Disk Head Scheduling & File Allocation**: FCFS, SSTF, SCAN (Elevator), C-SCAN, and LOOK seek calculations alongside simulated Contiguous, Linked, and Indexed block storage models.
- **Live System Monitor**: Safe, read-only system inspection using standard utilities (`uptime`, `free`, `df`, `ps`, `top`).
- **Persistence & Audit Reporting**: Automated CSV logging and detailed execution trace reports in `reports/`.
- **Automated Verification**: End-to-end acceptance test runner (`tests/test_runner.sh`) validating all algorithms against standard textbook test cases.

---

## 👥 Four-Member Work Distribution

| Member | Module Ownership | Key Deliverables |
|---|---|---|
| **Member 1** | Process Management & CPU Scheduling | FCFS, SJF, SRTF, Priority, Round Robin, Gantt chart renderer, timing metrics |
| **Member 2** | Memory Management & Virtual Memory | First Fit, Best Fit, Worst Fit, FIFO, LRU, Optimal page replacement, trace tables |
| **Member 3** | Deadlocks & Synchronization | Banker's safety algorithm, Deadlock detection routine, Producer-Consumer simulation |
| **Member 4** | Disk & Storage + Integration Lead | FCFS, SSTF, SCAN, C-SCAN, LOOK, File allocation models, Live monitor, Test harness |

---

## 🚀 Quick Start & Execution

### Prerequisites
- Bash 4.4+ (Linux, WSL, macOS, or Git Bash on Windows)
- Core utilities: `awk`, `sed`, `grep`, `column` (standard on all Linux distros)

### Launching the Application
```bash
# Clone or navigate to the repository
cd "os-sim"   # or workspace root

# Make scripts executable
chmod +x main.sh config.sh lib/*.sh modules/**/*.sh modules/*.sh tests/*.sh

# Run the interactive menu
./main.sh
```

### Running the Automated Test Suite
To verify all 19 algorithm test cases non-interactively:
```bash
bash tests/test_runner.sh
```

---

## 📂 Repository Structure

```
├── main.sh                       # Top-level interactive TUI menu
├── config.sh                     # Color codes, global constants, report paths
├── lib/
│   ├── input.sh                  # Safe input reader & boundary validator
│   ├── display.sh                # ASCII tables, banners, dividers, Gantt renderer
│   └── report.sh                 # Export to reports/*.csv and reports/*.txt
├── modules/
│   ├── cpu/                      # Module 1: CPU Scheduling
│   │   ├── menu.sh
│   │   ├── fcfs.sh
│   │   ├── sjf.sh
│   │   ├── srtf.sh
│   │   ├── priority.sh
│   │   └── round_robin.sh
│   ├── memory/                   # Module 2: Memory & Virtual Memory
│   │   ├── menu.sh
│   │   ├── allocation.sh
│   │   └── paging.sh
│   ├── safety/                   # Module 3: Deadlocks & Synchronization
│   │   ├── menu.sh
│   │   ├── banker.sh
│   │   ├── deadlock.sh
│   │   └── synchronization.sh
│   ├── storage/                  # Module 4: Disk & File Storage
│   │   ├── menu.sh
│   │   ├── disk.sh
│   │   └── file_allocation.sh
│   └── system_monitor.sh         # Module 5: Live Host Resource Monitor
├── tests/
│   └── test_runner.sh            # Automated verification test suite (19 test cases)
├── reports/                      # Auto-generated CSV and detailed trace logs
└── docs/
    ├── ARCHITECTURE.md           # Architecture design & module contracts
    └── VIVA_PREPARATION.md       # Viva defense questions and answers
```

---

## 📊 Sample Output: CPU Gantt Chart
```
Execution Gantt Chart:
  +-------+-------+-------+--------+
  | P1    | P2    | P1    | P3     |
  +-------+-------+-------+--------+
  0       2       4       7        12

Average Turnaround Time (TAT): 6.33
Average Waiting Time    (WT) : 2.33
Average Response Time   (RT) : 1.00
```

---

## 🧪 Acceptance Criteria Checklist
- [x] All 5 CPU algorithms correctly model idle intervals and tie rules.
- [x] Contiguous memory allocation documents fixed vs variable partitioning.
- [x] Page replacement verifies Optimal achieves minimum page faults.
- [x] Banker's algorithm distinguishes safe from unsafe matrices.
- [x] Deadlock detection accurately reports circular waiting sets.
- [x] Disk scheduling counts total head displacement across boundaries.
- [x] System monitor is strictly read-only and requires explicit confirmation for signals.
- [x] 100% test pass rate in `tests/test_runner.sh`.
