# PULPino DV — RISC-V SoC Verification Workspace

A UVM-based verification environment for the [PULPino](https://github.com/pulp-platform/pulpino) RISC-V SoC from ETH Zurich / PULP platform.

`repo/pulpino/` is a git submodule containing the original RTL; all verification code lives in the outer workspace.

## Supported Cores

| Core | Pipeline | ISA | Use Case |
|------|----------|-----|----------|
| **RISCY** | 4-stage | RV32IMF + PULP extensions | Performance |
| **zero-riscy** | 2-stage | RV32IMC | Ultra-low-area |

Selected via `USE_ZERO_RISCY` parameter (0=RISCY, 1=zero-riscy).

## Quick Start

### Prerequisites

- Synopsys VCS (simulator)
- Synopsys SVT UART VIP (`/opt/sv_pkgs/uvm/svt_2018.09/svt_uart`)
- `riscv64-linux-gnu-gcc` toolchain
- Python 3.6+

### Run Tests

```bash
# List all available tests
python sim/run_case.py --list

# Run a single test
python sim/run_case.py tc_uart_tx_single_test

# Run all UART tests
python sim/run_case.py --tag uart

# Run loopback tests
python sim/run_case.py --tag loopback

# Parallel jobs (default 10)
python sim/run_case.py tc_uart_hello_test -j 4

# Dry run (print commands without executing)
python sim/run_case.py --list --tag uart
```

### Run from Docker (Windows host)

```bash
./windows_docker_bridge.bat          # interactive shell
./windows_docker_bridge_ci.bat <test>  # CI bridge
```

### Legacy Makefile Flow

```bash
cd sim
make fw    # compile C firmware
make comp  # VCS compile
make sim   # run simulation
make dump  # run with FSDB waveform
make verdi # open Verdi viewer
```

## Architecture

### Two-Layer Test System

| Layer | Language | Location | Purpose |
|-------|----------|----------|---------|
| **Python case manager** | Python | `sim/case_manager/` + `test/*.py` | Build/Test classes, VCS compile, parallel sim, results |
| **UVM test classes** | SystemVerilog | `tests/*.sv` | UVM test logic: env setup, stimulus, checking |

### Test Data Flow

```
python sim/run_case.py <test_spec>
  -> discovers test/*.py -> Build + Test classes
  -> auto-generates prerun: make -C c CTEST=<c_test> -> firmware.slm
  -> VCS compiles RTL (sim/filelist.f) -> simv
  -> runs simv with +UVM_TESTNAME + plusargs
     -> tb_top.sv: backdoor memory preload ($readmemh firmware.slm)
     -> CPU boots from 0x80, C firmware runs on RISC-V core
     -> uart_monitor samples uart_tx pin -> bytes to scoreboard
     -> SVT UART VIP DCE: loopback TX->RX via uart_dce_rx_sequence
     -> scoreboard: parses "TEST PASSED"/"TEST FAILED" strings
```

### UVM Environment

```
soc_env
+-- axi_agent (core_master_agent)    <- Passive, monitors core2axi
+-- axi_agent (periph_slave_agent)   <- Passive, monitors peripherals
+-- apb_agent (apb_mon_agent)        <- Passive, monitors APB bus
+-- uart_monitor                     <- Bit-level TX sampling -> scoreboard
+-- svt_uart_agent (dce_agent)       <- Synopsys SVT UART VIP DCE (active)
+-- soc_scoreboard                   <- Parses UART output for PASS/FAIL/EOT
```

### Boot Sequence (Force-based, no JTAG)

1. `force boot_adr_q = 0x0000_0000` -- bypass JTAG
2. `$readmemh` backdoor loads firmware into DUT RAM
3. `fetch_enable = 1` -- CPU starts executing from `0x80`

## Project Structure

```
pulpino_dv/
+-- c/                    # C firmware for tests
|   +-- lib/              # uart_init(), retarget, linker scripts
|   +-- tests/uart_tests/ # individual test programs (main.c each)
+-- test/                 # Python Build/Test class definitions
+-- sim/
|   +-- run_case.py       # main entry: test discovery, compile, run
|   +-- case_manager/     # base.py, discovery.py, runner.py, cli.py
|   +-- filelist.f        # VCS compile file list
|   +-- Makefile           # legacy Makefile flow
+-- tb/                   # UVM testbench: tb_top.sv, env, agents
+-- tests/                # UVM test classes (.sv)
+-- seq_lib/              # UVM sequences
+-- repo/pulpino/         # git submodule (DO NOT MODIFY)
```

## Adding a New Test

1. Create `c/tests/uart_tests/<name>/main.c` with firmware test logic
2. Add a Python Test class in `test/pulpino_uart_test.py`
3. Set `c_test = "<name>"` and optionally `c_defines` for compile-time config
4. For loopback tests, inherit from `tc_uart_loopback_test`

## Key Configuration

| Parameter | Default | Notes |
|-----------|---------|-------|
| `USE_ZERO_RISCY` | 0 | 0=RISCY, 1=zero-riscy |
| `UART_DIVISOR` | 31 | Baud = 25MHz/32 = 781250 |
| `TIMEOUT_NS` | 10000000 | Watchdog (10ms simulated) |
| `+define+VERILATOR` | always set | Selects SV UART IP (not VHDL) |

Toolchain: `riscv64-linux-gnu-gcc` with `-march=rv32i -mabi=ilp32 -ffreestanding`. Simulator: Synopsys VCS. VIP: Synopsys SVT UART.

## Rules

- **Do not** modify files within `repo/pulpino/`. All verification work goes in the outer workspace.
