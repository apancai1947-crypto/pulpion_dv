# Bug Fix Log — PULPino UVM DV Environment

## Bug 1: Firmware not executing — wrong linking address

**Symptom**: CPU fetches from address 0x80 but firmware is linked at 0x0. PC trace shows `0x80 → 0x84 → ... → 0x90 → 0x84` looping on uninitialized memory.

**Root Cause**: PULPino's reset vector is `{boot_addr[31:8], EXC_OFF_RST}` where `EXC_OFF_RST = 8'h80`. Even with boot address forced to 0x0, the CPU starts fetching at byte address 0x80. The firmware's linker script placed `.text` at 0x0, so the actual code never reached the reset vector address.

**Fix**:
- Changed `c/sys/link.ld` to place `.text` at `0x00000080`
- `hex2slm.py` already converts byte addresses to word addresses (÷4), so `objcopy -O verilog` outputs `@00000080` which becomes `@00000020` (word index 32) in the SLM file
- Addresses `0x00`–`0x7C` are unused exception vector slots (not needed for basic firmware)

**Files changed**: `c/sys/link.ld`

---

## Bug 2: UART TX never starts — baud rate divisor not initialized

**Symptom**: Firmware executes correctly (PC advances through printf loop), but the UART monitor never detects a start bit on `uart_tx`. The TX pin stays at idle (1'b1) forever.

**Root Cause**: The `apb_uart_sv` module's baud rate divisor registers (`DLM`, `DLL`) default to 0 after reset. With `cfg_div = 0`, the internal baud counter fires `bit_done` every 2 clock cycles (counter: 0→1→0→1...). However, the real issue is that writing directly to the THR register without first configuring the UART (setting DLAB, divisor, FIFO) does not properly trigger TX. The UART needs initialization before it can transmit.

Additionally, the UART monitor was configured for 781250 baud (bit_period = 32 clk cycles), but the unconfigured UART with divisor=0 runs at a completely different rate, causing the monitor's start bit sampling to miss entirely.

**Fix**: Added UART initialization in `c/lib/retarget.c`:
```c
static void uart_init(void) {
    *UART_REG_LCR = 0x83;          // 8N1, DLAB=1
    *UART_REG_DLM = (31 >> 8) & 0xFF;  // divisor MSB
    *UART_REG_DLL = 31 & 0xFF;         // divisor LSB
    *UART_REG_LCR = 0x03;          // 8N1, DLAB=0
    *UART_REG_FCR = 0x07;          // enable + clear FIFOs
}
```
Divisor 31 gives `25MHz / (31+1) = 781250` baud, matching the UART monitor's expectation.

**Files changed**: `c/lib/retarget.c`, `c/include/common_macro.h`

---

## Bug 3: UVM config_db path mismatch — monitor can't find virtual interface

**Symptom**: `uvm_fatal` in `axi_monitor.build_phase`: "Failed to get axi_vif from config_db".

**Root Cause**: `soc_env.sv` set the interface at path `"core_master_agent"`, but the monitor is at `"core_master_agent.monitor"`. The `uvm_config_db::set` uses exact string matching by default — the child component at a deeper hierarchy path doesn't see it.

**Fix**: Changed the config_db set paths in `soc_env.sv` to use wildcard matching:
```systemverilog
// Before:
uvm_config_db#(virtual axi_if)::set(this, "core_master_agent", "axi_vif", vif);
// After:
uvm_config_db#(virtual axi_if)::set(this, "core_master_agent.*", "axi_vif", vif);
```
The `.*` wildcard allows all child components to find the interface.

**Files changed**: `tb/env/soc_env.sv`

---

## Bug 4: Missing RTL files in filelist.f — IP file structure mismatch

**Symptom**: VCS compilation errors: `module not found` for various IP modules (`apb_uart`, `axi_slice_dc` cells, RISC-V core sub-modules).

**Root Cause**: The `filelist.f` was generated based on assumptions about IP repository file structure. Actual files in `pulpino/ips/` differ from expected names (e.g., `_wrap.sv` wrappers don't exist in IP repos — they're in `pulpino/rtl/`). Also, `peripherals.sv` selects UART implementation based on `` `ifndef VERILATOR ``: without the define, it tries to use the VHDL `apb_uart` module instead of the SystemVerilog `apb_uart_sv`.

**Fix**:
- Examined `src_files.yml` in each IP repo for correct file lists
- Rewrote `filelist.f` with actual file paths from `Pulpino_v2.1` tag
- Added `+define+VERILATOR` to Makefile to select `apb_uart_sv` (SystemVerilog UART)
- Added all RISC-V core sub-modules (20+ files per core)
- Added `pulpino/ips/axi/axi_slice_dc/` files (dc_token_ring, dc_synchronizer, etc.)

**Files changed**: `sim/filelist.f`, `sim/Makefile`

---

## Bug 5: RISC-V toolchain name mismatch

**Symptom**: `make: riscv32-unknown-elf-gcc: Command not found` when compiling firmware.

**Root Cause**: The Docker container has `riscv64-linux-gnu-gcc` installed (Ubuntu cross-compiler package), not `riscv32-unknown-elf-gcc` (bare-metal toolchain).

**Fix**: Changed `c/Makefile` toolchain prefix from `riscv32-unknown-elf` to `riscv64-linux-gnu`. The `-march=rv32i -mabi=ilp32 -ffreestanding -nostartfiles -nostdlib` flags ensure correct 32-bit bare-metal output regardless of toolchain prefix.

**Files changed**: `c/Makefile`

---

## Bug 6: hex2slm.py byte ordering error

**Symptom**: Firmware loads into memory but instructions are corrupted (swapped bytes).

**Root Cause**: RISC-V is little-endian. `objcopy -O verilog` outputs bytes in memory order (LSB first). The conversion script was reading the first 8 hex characters of each line instead of parsing space-separated bytes and reconstructing the word with correct endianness.

**Fix**: Rewrote `hex2slm.py` to parse space-separated bytes and reconstruct words with little-endian reordering:
```python
bytes_list = line.split()
for i in range(0, len(bytes_list), 4):
    word = bytes_list[i+3] + bytes_list[i+2] + bytes_list[i+1] + bytes_list[i]
```

**Files changed**: `c/hex2slm.py`
