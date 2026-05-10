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
- Synopsys SVT VIPs:
  - UART (`svt_uart`)
  - SPI (`svt_spi`)
  - I2C, GPIO (optional)
- `riscv64-linux-gnu-gcc` toolchain
- Python 3.6+

### Run Tests

```bash
# List all available tests
python sim/run_case.py --list

# Run a single UART test
python sim/run_case.py tc_uart_tx_single_test

# Run SPI parameterized tests
python sim/run_case.py tc_spi_data_transfer

# Run all tests with a specific tag
python sim/run_case.py --tag spi

# Parallel jobs (default 10)
python sim/run_case.py tc_uart_hello_test -j 4
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
  -> auto-generates firmware: make -C c CTEST=<c_test> -> firmware.slm
  -> VCS compiles RTL (sim/filelist.f) -> simv
  -> runs simv with +UVM_TESTNAME + plusargs
     -> tb_top.sv: backdoor memory preload ($readmemh firmware.slm)
     -> CPU boots from 0x80, C firmware runs on RISC-V core
     -> Scoreboard: monitors bus activity or UART strings for PASS/FAIL
```

### UVM Environment

```
soc_env
+-- axi_agent (core_master_agent)    <- Passive, monitors core2axi
+-- axi_agent (periph_slave_agent)   <- Passive, monitors peripherals
+-- apb_agent (apb_mon_agent)        <- Passive, monitors APB bus
+-- uart_mon                         <- Bit-level sampling for UART TUBE
+-- stdout_mon                       <- APB write monitor for printf debugging
+-- svt_uart_agent (dce_agent)       <- Synopsys SVT UART VIP
+-- svt_spi_agent (spi_master_agent) <- Synopsys SVT SPI VIP (Slave role)
+-- svt_spi_agent (spi_slave_agent)  <- Synopsys SVT SPI VIP (Master role)
+-- soc_scoreboard                   <- Global verification scoreboard
```

### Boot Sequence (Force-based, no JTAG)

1. `force boot_adr_q = 0x0000_0000` -- bypass JTAG
2. `$readmemh` backdoor loads firmware into DUT RAM
3. `fetch_enable = 1` -- CPU starts executing from `0x80`

## Project Structure

```
pulpino_dv/
+-- c/                    # C firmware for tests
|   +-- tests/uart_tests/ # UART test programs
|   +-- tests/spi_tests/  # SPI parameterized test programs
+-- test/                 # Python Build/Test class definitions
+-- sim/
|   +-- run_case.py       # main entry for regression and debug
|   +-- case_manager/     # discovery, runner, and CLI logic
+-- tb/                   # UVM testbench structure
|   +-- env/              # soc_env, scoreboard, agents
+-- tests/                # UVM test classes (.sv)
+-- repo/pulpino/         # git submodule (DO NOT MODIFY)
```

## Adding a New Test

1. Create firmware in `c/tests/<module>_tests/<name>/main.c`.
2. Add a Python Test class in `test/pulpino_<module>_test.py`.
3. Inherit from base classes to leverage parallel sim and auto-compilation.

## Key Configuration

| Parameter | Default | Notes |
|-----------|---------|-------|
| `USE_ZERO_RISCY` | 0 | 0=RISCY, 1=zero-riscy |
| `UART_DIVISOR` | 31 | Baud rate config |
| `TIMEOUT_NS` | 10000000 | Watchdog timeout |

## Rules

- **Do not** modify files within `repo/pulpino/`. All verification work goes in the outer workspace.
