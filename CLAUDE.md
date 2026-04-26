# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PULPino DV workspace for verifying a PULPino RISC-V SoC (from ETH Zurich / PULP platform). The `repo/pulpino/` subdirectory is a git submodule containing the original RTL; the outer `pulpino_dv/` is the verification workspace.

Two interchangeable cores: **RISCY** (4-stage, RV32IMF + PULP extensions) and **zero-riscy** (2-stage, RV32IMC, ultra-low-area). Selected via `USE_ZERO_RISCY` parameter.

## Superpowers 设计文档

Superpowers skill 生成的 design spec 和 implementation plan 统一放在 `doc/` 目录下，不要用 `docs/superpowers/specs/`。

## Development Rules

> [!IMPORTANT]
> **DO NOT modify any files within `repo/pulpino/`.** All verification work goes in the outer workspace: `tb/`, `sim/`, `tests/`, `test/`, `c/`, `seq_lib/`.

## Key Commands

### Run tests (Python case manager — primary flow)

```bash
# List all available tests
python sim/run_case.py --list

# Run a single test by name
python sim/run_case.py tc_uart_tx_single_test

# Run by full spec (file:parent.test_name)
python sim/run_case.py pulpino_uart_test:uart_base_test.tc_uart_tx_single_test

# Run all tests with a tag
python sim/run_case.py --tag uart
python sim/run_case.py --tag loopback

# Dry run (print commands without executing)
python sim/run_case.py --list --tag uart

# Parallel jobs (default 10)
python sim/run_case.py tc_uart_hello_test -j 4

# Extra plusargs
python sim/run_case.py tc_uart_hello_test +TIMEOUT_NS=20000000
```

### Run from Docker (Windows host)

```bash
# Interactive shell into Docker container
./windows_docker_bridge.bat

# Run tests via CI bridge
./windows_docker_bridge_ci.bat <test_spec>
```

### Compile C firmware standalone

```bash
cd c
make CTEST=tc_uart_hello OUT=./build/tc_uart_hello all
make clean
```

### Legacy Makefile flow (sim/Makefile)

```bash
cd sim
make fw      # compile C firmware
make comp    # VCS compile
make sim     # run simulation
make dump    # run with FSDB waveform
make verdi   # open Verdi viewer
```

## Architecture

### Two-Layer Test System

| Layer | Language | Location | Purpose |
|-------|----------|----------|---------|
| **Python case manager** | Python | `sim/case_manager/` + `test/*.py` | Build/Test class inheritance, VCS compile, parallel sim, results |
| **UVM test classes** | SystemVerilog | `tests/*.sv` | UVM test logic: env setup, stimulus, checking |

The Python `Build` class controls VCS compilation. The Python `Test` class references a Build, specifies `uvm_test`, `c_test`, `sim_opt`, and auto-generates a prerun script that compiles C firmware. `InheritableMeta` metaclass enables `+=` on class attributes without mutating parent classes.

### Test Data Flow

```
python sim/run_case.py <test_spec>
  → discovers test/*.py → Build + Test classes
  → auto-generates prerun: make -C c CTEST=<c_test> → firmware.slm
  → VCS compiles RTL (sim/filelist.f) → simv
  → runs simv with +UVM_TESTNAME + plusargs
     → tb_top.sv: backdoor memory preload ($readmemh firmware.slm)
     → CPU boots from 0x80, C firmware runs on RISC-V core
     → uart_monitor samples uart_tx pin → bytes to scoreboard
     → SVT UART VIP DCE: loopback TX→RX via uart_dce_rx_sequence
     → scoreboard: parses "TEST PASSED"/"TEST FAILED" strings
```

### Boot Sequence (Force-based, no JTAG)

1. `force boot_adr_q = 0x0000_0000` — bypass JTAG
2. `$readmemh` backdoor loads firmware into DUT RAM
3. `fetch_enable = 1` — CPU starts executing from `0x80`

### UVM Environment

```
soc_env
├── axi_agent (core_master_agent)    ← Passive, monitors core2axi
├── axi_agent (periph_slave_agent)   ← Passive, monitors peripherals
├── apb_agent (apb_mon_agent)        ← Passive, monitors APB bus
├── uart_monitor                     ← Bit-level TX sampling → scoreboard
├── svt_uart_agent (dce_agent)       ← Synopsys SVT VIP DCE (active)
└── soc_scoreboard                   ← Parses UART output for PASS/FAIL/EOT
```

### C Firmware Pattern

Each test in `c/tests/uart_tests/<test_name>/main.c` is a standalone bare-metal program:
- Calls `uart_init()` from `c/lib/retarget.c` to configure UART (DLAB, divisor, FIFO)
- Runs test logic, prints results via `printf()` (redirected to UART)
- Sends `"TEST PASSED\n"` or `"TEST FAILED\n"` followed by EOT (`0x04`)
- Linker script places `.text` at `0x80` (reset vector)

### Key Configuration

| Parameter | Default | Notes |
|-----------|---------|-------|
| `USE_ZERO_RISCY` | 0 | 0=RISCY, 1=zero-riscy |
| `UART_DIVISOR` | 31 | Baud = 25MHz/32 = 781250 |
| `TIMEOUT_NS` | 10000000 | Watchdog (10ms simulated) |
| `+define+VERILATOR` | always set | Selects SV UART IP (not VHDL) |

Toolchain: `riscv64-linux-gnu-gcc` with `-march=rv32i -mabi=ilp32 -ffreestanding` (not `riscv32-unknown-elf-gcc`). Simulator: Synopsys VCS. VIP: Synopsys SVT UART.

### Python Case Manager Internals (`sim/case_manager/`)

- **`base.py`**: `InheritableMeta` metaclass, `Build` and `Test` base classes. `Test.get_prerun_script()` auto-generates C firmware compilation.
- **`discovery.py`**: Scans `test/` for `.py` files, imports all `Build`/`Test` subclasses dynamically.
- **`runner.py`**: MD5-based build caching (`debug/.<hash>/simv`), `ThreadPoolExecutor` parallel sim, writes `results.log`.
- **`cli.py`**: argparse CLI with `--list`, `--tag`, `--dry-run`, `--cov`, `--debug`, `--xprop`, `-j`, `-o`.
- Test spec format: `pulpino_uart_test:uart_base_test.tc_uart_tx_single_test` (file:parent.child)

### Adding a New Test

1. Create `c/tests/uart_tests/<name>/main.c` with the firmware test logic
2. Add a Python Test class in `test/pulpino_uart_test.py` (inherit from `uart_base_test` or similar)
3. The Python class sets `c_test = "<name>"` and optionally `c_defines` for compile-time config
4. For loopback tests, inherit from `tc_uart_loopback_test` (which uses `uart_loopback_build`)
