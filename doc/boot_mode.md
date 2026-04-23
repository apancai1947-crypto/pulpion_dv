当前启动方式：Backdoor Preload（强制模式）

当前 tb\_top.sv 的启动流程完全绕过了 PULPino 的正常启动机制：

tb\_top.sv 启动流程:

1. force boot\_adr\_q = 0x0000\_0000   ← 直接 force 内部寄存器
2. 等待 reset 释放
3. $readmemh 直接写入 DUT 内部 RAM    ← 绕过总线，直接写存储器
4. fetch\_enable = 1                   ← CPU 开始取指
5. PC = {0x00\[31:8], 0x80} = 0x80    ← 从指令 RAM 0x80 开始执行

这等价于原始 TB (pulpino/tb/tb.sv) 的 +MEMLOAD=PRELOAD 模式，但没有走 JTAG
通道。

\---

PULPino 两种标准启动方式

方式 1：JTAG + Backdoor Preload（原始 PRELOAD 模式）

原始 TB 的流程（pulpino/tb/tb.sv:237-258）：

1. 复位释放
2. JTAG 初始化 (adv\_dbg\_if.init)
3. 通过 JTAG→AXI 写 SoC Control 寄存器设置 boot 地址:
adv\_dbg\_if.axi4\_write32(32'h1A10\_7008, 1, 32'h0000\_0000)
↑ 地址 0x1A10\_7008 = SoC Control 基址 0x1A10\_7000 + REG\_BOOT\_ADR 偏移 0x08
4. $readmemh 预加载固件到 RAM
5. fetch\_enable = 1 → CPU 启动

关键区别：boot 地址是通过 JTAG Debug 接口 → AXI master → APB bridge →
apb\_pulpino 模块的 REG\_BOOT\_ADR 寄存器来设置的，而不是直接 force。

当前环境要改成这种方式需要：

1. 引入 JTAG DPI 模块（已在 filelist.f 中有 pulpino/tb/jtag\_dpi.sv）
2. 引入 tb\_jtag\_pkg.sv（JTAG 操作类 + adv\_dbg\_if\_t 类）
3. 在 tb\_top.sv 中：
- 实例化 jtag\_i 接口 + adv\_dbg\_if\_t 对象
- 替换 force boot\_adr\_q 为 JTAG 写操作：
// 替换: force dut.peripherals\_i.apb\_pulpino\_i.boot\_adr\_q = 32'h0;
adv\_dbg\_if.jtag\_reset();
adv\_dbg\_if.jtag\_softreset();
adv\_dbg\_if.init();
// 通过 JTAG 写 boot\_addr 寄存器 (0x1A10\_7008)
adv\_dbg\_if.axi4\_write32(32'h1A10\_7008, 1, 32'h0000\_0000);
4. firmware 链接地址需改回 0x00000000，因为 boot\_addr 寄存器值 =
0x00000000，CPU reset vector = {boot\_addr\[31:8], 0x80} =
0x00000080，和现在一样

方式 2：SPI Boot（从 Flash 启动）

这是 PULPino 的标准独立启动方式。流程如下：

1. 复位释放，fetch\_enable = 1
2. boot\_addr 默认值 = BOOT\_ADDR 参数 (0x8000)
3. CPU reset vector = {0x0000\[31:8], 0x80} = 0x80
4. 地址 0x80 → addr\_i\[15]=0 → 指令 RAM → 如果没预加载就是空的

等等，这里有个关键问题。看 apb\_pulpino.sv:39：

parameter BOOT\_ADDR = 32'h8000

默认 boot 地址是 0x8000，所以 reset vector = {0x00008000\[31:8], 0x80} =
0x00008080。

但 instr\_ram\_wrap 的地址解码是 is\_boot = addr\_i\[15]。对于 0x8080：

* 字节地址 0x8080 → AXI 地址 → axi\_mem\_if → 转换后的 addr\_i
* 关键：instr\_ram\_wrap 的 ADDR\_WIDTH=16，addr\_i\[15] 判断是否为 boot ROM

原始 TB 中 MEMLOAD=SPI 时：

1. 先让 CPU 从 boot ROM 启动（boot\_addr = 0x8000 使得地址落到 boot ROM 区域）
2. Boot ROM 包含一个小 loader，通过 SPI 从外部 flash 复制代码到指令 RAM
3. loader 完成后跳转到指令 RAM 的代码入口

当前环境要支持 SPI boot 需要：

1. 实例化 SPI flash 模型（spi\_slave + spi\_master 接口）
2. 将固件转换为 SPI flash 格式，通过 SPI flash model 提供
3. 不要 force boot\_addr，使用默认 BOOT\_ADDR = 0x8000
4. 不要 $readmemh 预加载指令 RAM，让 boot ROM 的 loader 从 SPI 搬运
5. 需要正确驱动 SPI 信号（spi\_clk, spi\_cs, spi\_sdo/sdi）

\---

总结对比

┌──────────────────┬────────────────┬────────────────────┬─────────────────┐
│                  │  当前 (Force)  │      方式 1        │  方式 2 (SPI    │
│                  │                │   (JTAG+Preload)   │      Boot)      │
├──────────────────┼────────────────┼────────────────────┼─────────────────┤
│ boot\_addr 设置   │ force          │ JTAG AXI 写 APB    │ 使用默认值      │
│                  │ 内部寄存器     │ 寄存器             │ 0x8000          │
├──────────────────┼────────────────┼────────────────────┼─────────────────┤
│ 固件加载         │ $readmemh      │ $readmemh 后门加载 │ Boot ROM → SPI  │
│                  │ 后门加载       │                    │ → RAM           │
├──────────────────┼────────────────┼────────────────────┼─────────────────┤
│ JTAG 需要        │ 否             │ 是                 │ 否              │
├──────────────────┼────────────────┼────────────────────┼─────────────────┤
│ SPI 需要         │ 否             │ 否                 │ 是              │
├──────────────────┼────────────────┼────────────────────┼─────────────────┤
│ 复杂度           │ 最低           │ 中等               │ 最高            │
├──────────────────┼────────────────┼────────────────────┼─────────────────┤
│ 与真实芯片一致性 │ 最低           │ 中等               │ 最高            │
└──────────────────┴────────────────┴────────────────────┴─────────────────┘

如果目标是做 DV 验证，方式 1（JTAG + Preload） 是最实用的折衷 —
它使用了芯片的真实启动路径（JTAG 配置），同时保留了 $readmemh
的快速加载能力。需要我实现其中一种方式吗？

✻ Baked for 1m 11s

