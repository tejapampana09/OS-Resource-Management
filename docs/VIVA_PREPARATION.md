# OS Resource Management & Simulation Suite: Viva Preparation Guide

This document prepares the team for academic viva examinations and project demonstrations.

---

## 🎯 Core Viva Questions & Model Answers

### Q1: What is the difference between a simulator and a real OS kernel?
> **Answer:**
> A **simulator** is an educational model running entirely in user-space that calculates hypothetical scheduling timelines, page fault counts, or seek distances using theoretical equations. It does not control physical hardware.
> An **OS kernel** (e.g. Linux kernel) is the low-level software layer that directly manages physical CPU registers, Memory Management Units (MMU), interrupts, I/O devices, and hardware page tables in supervisor mode (Ring 0).

---

### Q2: Why does SJF reduce average waiting time, and what is its main drawback?
> **Answer:**
> SJF (Shortest Job First) is provably optimal in minimizing average waiting time because scheduling short processes first allows them to complete and leave the system quickly, reducing the cumulative queue waiting time for subsequent jobs.
> **Drawback:** Starvation (indefinite blocking) of long-burst processes if shorter processes continually arrive. Also, in real systems, the exact next CPU burst duration cannot be known in advance (it can only be estimated using exponential smoothing).

---

### Q3: What is the difference between Turnaround Time (TAT), Waiting Time (WT), and Response Time (RT)?
> **Answer:**
> - **Completion Time (CT):** Instant when a process finishes execution.
> - **Turnaround Time (TAT):** Total time elapsed from submission to completion:
>   $$\text{TAT} = \text{CT} - \text{AT}$$
> - **Waiting Time (WT):** Total time a process spent waiting in the ready queue:
>   $$\text{WT} = \text{TAT} - \text{BT}$$
> - **Response Time (RT):** Time from arrival until the process first gets CPU time:
>   $$\text{RT} = \text{First CPU Start Time} - \text{AT}$$

---

### Q4: Why can FIFO have more page faults than LRU? What is Belady's Anomaly?
> **Answer:**
> FIFO replaces the oldest resident page without considering how frequently or recently it was referenced, often evicting frequently used pages. LRU utilizes the principle of locality by evicting the page that hasn't been accessed for the longest duration.
> **Belady's Anomaly:** For certain page replacement policies (specifically FIFO), increasing the number of allocated physical frames can paradoxically *increase* the total number of page faults. Stack algorithms like LRU and Optimal never suffer from Belady's Anomaly.

---

### Q5: What is the difference between a Safe State and a Deadlock-Free State?
> **Answer:**
> - A **Safe State** guarantees that there exists at least one order (a safe sequence) in which all processes can finish their maximum declared demands, even in the worst-case scenario where all processes simultaneously request their maximum resource limit.
> - An **Unsafe State** is not necessarily a deadlocked state yet; however, the system cannot guarantee that deadlock will be prevented if processes demand their peak requirements. Deadlock is a subset of unsafe states.

---

### Q6: How does SCAN differ from LOOK in disk scheduling?
> **Answer:**
> - **SCAN (Elevator):** The disk arm moves in a given direction servicing requests until it hits the **physical boundary cylinder** (0 or maximum cylinder limit), even if there are no pending requests at the boundary, and then reverses.
> - **LOOK:** The disk arm services requests in a given direction but **reverses as soon as the last pending request in that direction is reached**, avoiding unnecessary head travel to the physical edge of the disk platters.

---

### Q7: Explain Internal vs. External Fragmentation.
> **Answer:**
> - **Internal Fragmentation:** Memory wasted inside an allocated partition when the requested process size is smaller than the assigned fixed partition block.
> - **External Fragmentation:** Unallocated memory exists in total to satisfy a request, but it is split into non-contiguous holes that cannot accommodate a single large contiguous process without compaction.

---

### Q8: What are the 4 Coffman Conditions required for Deadlock?
> **Answer:**
> 1. **Mutual Exclusion:** At least one resource is held in a non-shareable mode.
> 2. **Hold and Wait:** A process holding at least one resource is waiting to acquire additional resources held by other processes.
> 3. **No Preemption:** Resources cannot be forcibly revoked from a process holding them; they must be released voluntarily upon task completion.
> 4. **Circular Wait:** A closed chain of processes exists: $P_0$ waits for a resource held by $P_1$, $P_1$ waits for $P_2$, ..., and $P_n$ waits for $P_0$.

---

### Q9: Why use Bash shell scripting for this project instead of C or Python?
> **Answer:**
> Bash is the native command language of UNIX/Linux systems. It enables seamless integration with core operating system tools (`awk`, `grep`, `ps`, `top`, `free`, `df`, `lsblk`), allows rapid prototyping of CLI user interfaces, and directly exposes Linux process control primitives, making it exceptionally well-suited for systems programming coursework.
