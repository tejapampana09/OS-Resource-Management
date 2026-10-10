# Architecture and Design Specification

## 1. System Overview

The **OS Resource Management & Simulation Suite** is structured around three core design layers:
1. **Presentation & CLI Layer**: `main.sh`, `lib/display.sh`, module-specific submenus.
2. **Simulation & Algorithm Engine Layer**: Pure algorithmic functions in `modules/cpu/`, `modules/memory/`, `modules/safety/`, and `modules/storage/`.
3. **Data & Host Integration Layer**: `lib/report.sh` (persisting CSV and detailed trace logs) and `modules/system_monitor.sh` (reading host telemetry from Linux `/proc` and standard utilities).

```
                            +--------------------+
                            |      main.sh       |
                            | (Interactive Menu) |
                            +--------------------+
                                      |
         +----------------------------+----------------------------+
         |                            |                            |
         v                            v                            v
+------------------+         +------------------+         +------------------+
|   lib/input.sh   |         |  lib/display.sh  |         |  lib/report.sh   |
| (Validation &    |         | (TUI, Tables,    |         | (CSV Persistence |
|  Safe Prompts)   |         |  Gantt Renderer) |         |  & Text Traces)  |
+------------------+         +------------------+         +------------------+
         |                            |                            |
         +----------------------------+----------------------------+
                                      |
       +-----------------+------------+----+----------------+
       |                 |                 |                |
       v                 v                 v                v
+-------------+   +--------------+   +-----------+   +---------------+
| modules/cpu |   | modules/mem  |   | modules/  |   |   modules/    |
| (Scheduling |   | (Allocation  |   | safety    |   |    storage    |
|  & Gantt)   |   |  & Paging)   |   | (Banker & |   | (Disk & File  |
|             |   |              |   |  Sync)    |   |  Alloc Maps)  |
+-------------+   +--------------+   +-----------+   +---------------+
                                                            |
                                                            v
                                                   +-----------------+
                                                   | system_monitor  |
                                                   | (Live Host Telemetry) |
                                                   +-----------------+
```

---

## 2. Module Contracts & Coding Conventions

### Function and Variable Scoping
- All module internal variables are declared as `local` or `local -a` to prevent namespace pollution.
- Shared exported variables use uppercase prefix (e.g. `LAST_AVG_TAT`, `LAST_PAGE_FAULTS`).
- Return values: functions return `0` on success and `1` on invalid input or failure.

### Simulation vs Real Kernel
- Algorithm modules are **pure models** executed in user space. They do not alter kernel scheduling, swap space, or physical block allocation.
- The `system_monitor.sh` module explicitly identifies host hardware stats and never confuses simulator metrics with host metrics.

### Reporting Contract
All algorithm modules call `log_simulation_csv` with schema:
```csv
timestamp,module,algorithm,input_summary,result_summary,notes
```
Additionally, visual execution traces (Gantt timelines, page replacement frame matrices, disk seek step sequences) are written to `reports/YYYYMMDD_HHMMSS_<module>_<algorithm>.txt`.
