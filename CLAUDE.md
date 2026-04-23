# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PULPino is an open-source single-core RISC-V microcontroller SoC from ETH Zurich / PULP platform. The `repo/pulpino/` subdirectory is the actual git repo; the outer `pulpino_dv/` is a DV workspace wrapper.

Two interchangeable cores are supported:
- **RISCY**: 4-stage pipeline, RV32IM(F) + PULP extensions (hardware loops, SIMD, MAC, dot product)
- **zero-riscy**: 2-stage pipeline, RV32I(M)(C)(E), ultra-low-area target

Core selection is controlled at RTL via `USE_ZERO_RISCY` parameter and at SW build time via CMake flags.

## Architecture (RTL)

`pulpino_top.sv` is the top module. Key hierarchy:

```
pulpino_top
├── clk_rst_gen          # Clock/reset generation with FLL
├── core_region          # CPU core + local memories + debug
│   ├── riscv_core / zeroriscy_core  (from IPS, selected by parameter)
│   ├── core2axi_wrap    # Core request → AXI master
│   ├── axi_slice_wrap   # Pipeline isolation
│   ├── instr_ram_wrap   + axi_mem_if_SP_wrap + ram_mux  # Instruction memory
│   ├── sp_ram_wrap      + axi_mem_if_SP_wrap + ram_mux  # Data memory
│   └── adv_dbg_if       # JTAG debug unit → AXI master
├── peripherals          # APB peripheral subsystem
│   ├── axi2apb_wrap + periph_bus_wrap  # AXI→APB bridge + address decode
│   ├── UART, SPI, I2C, GPIO, Timer, Event Unit, FLL, SoC Ctrl, Debug
│   ├── axi_spi_slave_wrap  # SPI slave for external boot
│   └── boot_rom_wrap       # Boot ROM
├── axi_node_intf_wrap   # AXI interconnect (3 masters → 4 slaves)
├── dp_ram_wrap          # Shared dual-port RAM
└── axi_slice_wrap(s)    # Pipeline slices on AXI paths
```

Bus system: AXI4 for core/peripherals interconnect, APB for individual peripheral registers. The `axi_bus.sv` and `apb_bus.sv` interfaces in `rtl/includes/` define the bus types.

Address decoding: `core_region` demuxes LSU by address prefix — `0x001xxxxx` → local data RAM, otherwise → AXI bus. `periph_bus_wrap` maps APB slaves by address ranges defined as macros.

Config defines in `rtl/includes/config.sv`: `RISCV`, `ROM_ADDR_WIDTH`, optional `DATA_STALL_RANDOM`/`INSTR_STALL_RANDOM` for stress testing.

## Development Rules

> [!IMPORTANT]
> **DO NOT modify any files within the `repo/pulpino/` directory.**
> The `repo/pulpino/` directory is a git submodule (sub-repo) containing the original SoC RTL and libraries. All verification-related additions or fixes should be implemented in the outer `pulpino_dv/` workspace (e.g., in `tb/`, `sim/`, `tests/`) or via wrapper modules/system-level overrides.


## IPS (IP Submodules)

Peripheral IPs (UART, SPI, I2C, GPIO, Timer, core RTL, AXI nodes, etc.) live in `ips/` and are managed as git sub-repos via `ips_list.yml`. Run `./update-ips.py` to clone/update them.

## Software Build & Simulation

Requires: riscv32-unknown-elf-gcc (ETH or Berkeley), CMake ≥2.8, ModelSim ≥10.2c, tcsh.

### Building software and running simulation

```bash
# 1. Setup — copy and edit a cmake-configure script from sw/
cp sw/cmake_configure.riscv.gcc.sh sw/build/
cd sw/build/
# Edit the script: set compiler paths, choose core (USE_ZERO_RISCY), ISA flags, VSIM path
./cmake_configure.riscv.gcc.sh

# 2. Compile RTL libraries in ModelSim
make vcompile

# 3. Run simulation (GUI)
make <testname>.vsim

# 4. Run simulation (batch/console)
make <testname>.vsimc
```

Replace `cmake_configure.riscv.gcc.sh` with the appropriate variant:
- `cmake_configure.riscv.gcc.sh` — RISCY with PULP extensions (march=IMXpulpv2)
- `cmake_configure.riscvfloat.gcc.sh` — RISCY with FPU (march=IMFXpulpv2)
- `cmake_configure.zeroriscy.gcc.sh` — zero-riscy with M extension (march=RV32IM)
- `cmake_configure.microriscy.gcc.sh` — zero-riscy minimal (march=RV32I, -m16r for RV32E)

Key CMake variables: `USE_ZERO_RISCY`, `RISCY_RV32F`, `ZERO_RV32M`, `ZERO_RV32E`, `RVC`, `GCC_MARCH`, `PULP_MODELSIM_DIRECTORY`.

### Running tests

```bash
# Batch test all riscv_tests
cd sw/build && ctest -L riscv_test -j4 --timeout 3000 --output-on-failure

# Disassemble a program
make <testname>.read

# Regenerate boot code
make boot_code.install
```

### CI test stages

GitLab CI (`.gitlab-ci.yml`) runs 4 stages: `test_riscy`, `test_riscy_fp`, `test_zero`, `test_micro`. Each runs `ci/rtl-basic.csh` (basic tests) and `ci/rtl-sequential.csh` (sequential tests), with RVC variants.

## Verilator

Optional Verilator support exists under `vsim/verilator/`. Requires verilator 3.884. See `ci/verilator.csh`.

## FPGA

FPGA synthesis for ZedBoard is under `fpga/`. See `fpga/README.md`.
