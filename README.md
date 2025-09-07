# APB Protocol Verification using UVM

A complete UVM testbench for an **AMBA APB slave**. The bench uses a split-agent style:
- **Write agent (ACTIVE)** — sequencer + driver + write monitor  
- **Read agent (PASSIVE)** — read monitor only  
- **Scoreboard** and **functional coverage** wired via analysis ports

> **DUT**: `APB_slave_design.sv`  
> **Bus**: APB3/4-style (PSEL/PENABLE two-phase handshake)

---

## Testbench Architecture

> Put this image at `docs/TB_Architecture.png` in the repo so it renders on GitHub.

![Testbench Architecture](docs/TB_Architecture.png)

**Hierarchy:** `Top → Test → Env`

- **Env**
  - **W_agent (ACTIVE)**: `sequencer`, `driver`, `W_monitor (ap_write)`
  - **R_agent (PASSIVE)**: `R_monitor (ap_read)`
  - **Scoreboard**: checks readbacks vs. reference model
  - **Coverage Model**: samples addresses, data widths, R/W, PREADY/PSLVERR bins
- **Virtual Interface (`APB_if`)** shared by driver/monitors; connected to DUT pins in `APB_top.sv`

---

## Files & Roles

> These are the files in this repo’s `APB-Protocol-Verification-Using-UVM` project.

### Core package & interface
- **`APB_pkg.sv`**  
  Common params:
  - `DATA_W` (default 32)  
  - `ADDR_LSB = $clog2(DATA_W/8)` (word alignment)  
  - `DEPTH` (reference model/memory depth)

- **`APB_if.sv`**  
  Synthesizable APB interface (`PSEL, PENABLE, PADDR, PWRITE, PWDATA, PRDATA, PREADY, PSTRB`) with `master/slave` modports.  
  The top sets this into the UVM config DB:  
  `uvm_config_db#(virtual APB_if)::set(null, "*", "vif", vif);`

### Transactions, sequencer, driver
- **`APB_txn.sv`**  
  UVM `sequence_item` fields:
  - `write` (1=WR, 0=RD), `addr_byte`, `wdata`, `rdata`, `strb`
  - Constraints:
    - **alignment**: `addr_byte[ADDR_LSB-1:0] == '0`
    - **range**: `(addr_byte >> ADDR_LSB) inside {[0:DEPTH-1]}`

- **`APB_sequencer.sv`**  
  Type-specific `uvm_sequencer #(APB_txn)`.

- **`APB_driver.sv`**  
  Implements APB handshake:
  - **SETUP**: `PSEL=1, PENABLE=0`, drive `PADDR/PWRITE/PWDATA/PSTRB`
  - **ACCESS**: assert `PENABLE=1`, wait for `PREADY`
  - On reads, latches `PRDATA`; sends responses via `rsp_port`

### Monitors & agents
- **`APB_wr_monitor.sv`**  
  Observes the bus; when `PSEL & PENABLE & PWRITE & PREADY` it publishes an `APB_txn` on `ap_write`.

- **`APB_r_monitor.sv`**  
  Observes `PSEL & PENABLE & ~PWRITE & PREADY` and publishes on `ap_read`.

- **`APB_w_agent.sv`**  
  Builds **sequencer, driver, wr_monitor** (active).

- **`APB_r_agent.sv`**  
  Builds **r_monitor** only (passive).

### Scoreboard & coverage
- **`APB_scoreboard.sv`**  
  - `sb_export_write` updates a reference model array sized by `DEPTH`
  - `sb_export_read` compares `rdata` vs. expected; reports mismatches

- **`APB_coverage_model.sv`**  
  `uvm_subscriber` with write/read imps:
  - coverpoints: address ranges (min/max/in-range/invalid), data widths (8/16/24/32), R/W, PREADY, PSLVERR
  - crosses for protocol scenarios (e.g., R/W × enable)

### Environment, test, top, DUT
- **`APB_env.sv`**  
  Builds & connects:


- **`APB_test.sv`**  
Creates the env and starts sequences (see below). You can choose a specific sequence via plusargs.

- **`APB_top.sv`**  
Instantiates `APB_if` and the **DUT** (`APB_slave_design`), clocks/reset, config DB, and calls `run_test()`.

- **`APB_slave_design.sv`**  
Simple APB slave:
- FSM: `IDLE → SETUP → ACCESS`
- `mem[0:DEPTH-1]` model; writes store, reads return
- `PREADY` in ACCESS (one-cycle response by default)
- Easy to extend with wait-states or `PSLVERR` generation

---

## Sequences (Stimulus)

- **`APB_seq_WrData_RdData.sv`**  
Single write then single read back from the same address (sanity check).

- **`APB_seq_burstWrData_RdData.sv`**  
Burst of writes followed by burst of reads from the same base address. Ensures addresses are aligned and in-range using `DEPTH`.

- **`APB_seq_burstDiffWrData_RdData.sv`**  
Burst with **varying data sizes** (8/16/24/32) and matching `strb`.

> Sequences populate **semantic fields only** (`write/addr_byte/wdata/strb`).  
> **Handshake (`PSEL/PENABLE/...`) is owned by the driver.**

