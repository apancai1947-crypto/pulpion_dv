# Synopsys SVT SPI/QSPI VIP 通用集成与踩坑避北指南

## 1. 简介
Synopsys SVT (SystemVerilog Testbench) SPI VIP 是一款功能强大的验证组件，支持标准 SPI、Dual SPI、Quad SPI (QSPI) 以及各种 Flash 协议。
本文档总结了在 PULPino 等自定义 SoC 验证环境中集成 SPI VIP 时的**通用路径**和**深度踩坑经验**，适用于任何基于 UVM 的验证环境。

---

## 2. 预集成准备与宏配置

### 2.1 编译宏配置 (`vlog_opt`)
在编译脚本中，必须通过宏定义控制 VIP 的硬件特性及内部数据结构上限：
- `SVT_SPI_IO_WIDTH`：定义物理数据线数量（1=STD, 2=Dual, 4=QSPI）。
- `SVT_SPI_MAX_NUM_SLAVES`：定义支持的最大 Slave 数量。
- **`SVT_SPI_DATA_WIDTH`**：定义事务级 `data[]` 数组的位宽。**注意：配置类中的 `data_frame_width` 绝对不能超过此宏的值！**（例如若设为 40，宏也必须 >= 40）。

```bash
# 示例：VCS 编译选项
+define+SVT_SPI_IO_WIDTH=4 \
+define+SVT_SPI_DATA_WIDTH=32
```

---

## 3. VIP 相关查询的正确流程（SOP）

Synopsys VIP 的 `.svp` 源码经过加密，无法直接通过源码或 `grep` 查询属性。遇到找不到属性或配置不生效时，**请严格遵循以下 SOP**：

1. **【首选】查 Docker 内 HTML 文档（最权威）：**
   路径：`/usr/Synopsys/vip_2018_09/vip/svt/spi_svt/latest/doc/spi_svt_uvm_class_reference/html/`
   核心入口：`index.html`。关键文件：
   - `class_svt_spi_agent_configuration.html` — Agent 专属属性
   - `class_svt_spi_configuration.html` — **父类！绝大多数关键属性都在这里**
   - `class_svt_spi_transaction.html` — 事务字段（如 `data`, `transfer_mode`）
   
   *提示：若在终端无法查看，可通过 Python 脚本提取文本：*
   ```python
   # 在 Docker 内执行
   import re
   DOC = '/usr/Synopsys/vip_2018_09/vip/svt/spi_svt/latest/doc/spi_svt_uvm_class_reference/html/'
   with open(DOC + 'class_svt_spi_configuration.html', encoding='latin-1') as f:
       text = re.sub(r'<[^>]+>', ' ', f.read())
       # 进一步处理即可看到完整 public attributes
   ```

2. **查 `.svi` 文件**：`sverilog/include/` 下的 `.svi` 文件是明文，包含接口端口和枚举宏定义。

3. **利用编译报错反查**：直接把猜测的属性写进代码并编译，VCS `compile.log` 中的 `Error-[MFNF]` 会准确告诉你该类下是否存在此属性。

---

## 4. UVM 环境配置避坑指南 (`soc_env.sv`)

### 4.1 类继承关系与属性误区
很多你以为应该有的配置，其实在父类，或者名字不一样：
- **错误**：`item_operation_mode` -> **正确**：`operation_mode`
- **错误**：`data_width` -> **正确**：`data_frame_width`
- **注意**：`is_master` 等属性在基类 `svt_spi_configuration`，Agent 会继承。

### 4.2 Standard SPI 的关键配置
如果要用 VIP 监控标准 SPI 协议（而非默认的 Flash 协议），**必须集齐以下配置**，缺一不可：

```systemverilog
spi_cfg = svt_spi_agent_configuration::type_id::create("spi_cfg");

// 1. 角色配置
spi_cfg.is_active = 0; // 0=Passive Monitor (只听不说), 1=Active
spi_cfg.is_master = 0; // 0=Slave 角色 (监控 Master 发出的数据), 1=Master 角色

// 2. 协议与模式
spi_cfg.frame_format   = svt_spi_types::SPI_STD;    // 必须显式指定！否则可能被当作 Flash 解析
spi_cfg.operation_mode = svt_spi_types::SPI_MODE_0; // CPOL=0, CPHA=0

// 3. 数据帧宽 (极其容易踩坑)
spi_cfg.enable_configurable_data_frame_width = 1; // 必须设为1！否则下面那行配置无效！
spi_cfg.data_frame_width = 32;                    // 设置实际的帧长

// 4. 字节序 (决定解析结果)
// VIP 默认按 LSB-first 将线上的 bit 填入 data[0]。
// 如果你的 RTL 是 MSB-first，必须设置为 BIG_ENDIAN，否则读出的数据会高低位倒序！
spi_cfg.bit_endianness = svt_spi_types::BIG_ENDIAN;

// 5. 关闭 Flash 特有检查
spi_cfg.enable_txrx_chk = 0;
```

---

## 5. 数据流监控与自我比对

### 5.1 Passive Slave 的数据获取路径
当 VIP 被配置为 **Passive Slave**（监控 Master 时），它的内部监视器（`txrx_mon`）对方向的定义如下：
- **RX 方向 (`rx_xact_observed_port`)**：对应从 **MOSI** 线上采样到的数据（Master 发给 Slave 的真实有效负载）。
- **TX 方向 (`tx_xact_observed_port`)**：对应从 **MISO** 线上采样到的数据（Slave 返回给 Master 的数据，如果没有驱动则全 0）。

**避坑**：在 UVM Scoreboard 中，如果你想比对 Master 发出的命令或数据，**必须监听 RX 端口**。如果监听 `item_observed_port`（混合端口），有极高概率抓到无用的 TX(MISO) 侧空数据。

### 5.2 提取数据的实现代码
```systemverilog
svt_spi_transaction vip_tr;
// 确保只拿 rx_vip_fifo 里的事务
rx_vip_fifo.get(vip_item);
$cast(vip_tr, vip_item);

if (vip_tr.data.size() > 0) begin
    // 获取第一个 word 的数据（受 SVT_SPI_DATA_WIDTH 宏影响）
    logic [31:0] vip_data = vip_tr.data[0]; 
    
    // 如果配置了正确的 BIG_ENDIAN，vip_data 就可以直接跟预期值比对
    if (vip_data == expected_data) begin
        `uvm_info("CHECK", "Data matched!", UVM_LOW)
    end
end
```

---

## 6. 常见错误速查

| 现象 / 报错 | 可能原因 & 解决办法 |
| :--- | :--- |
| **`Error-[MFNF] Member not found`** | 属性名写错。使用 SOP 1 查阅 HTML 文档确认正确属性名。 |
| **VIP 报告 `Read Mode` 且 `DFS=0`** | 1. 它是 Flash 模式，遇到了不认识的 CMD。<br>2. 忘记设置 `frame_format = SPI_STD`。<br>3. `is_master` 配置和物理连线角色相反。 |
| **设置了 `data_frame_width` 但不生效** | 漏了配置 `enable_configurable_data_frame_width = 1`。 |
| **数据位宽报错 `must be less than or equal to Macro`** | 编译时的 `+define+SVT_SPI_DATA_WIDTH` 过小，调大宏定义。 |
| **收到的数据值按位完全翻转** (`0x00000001` 变 `0x80000000`) | 字节序问题。在 config 中添加 `spi_cfg.bit_endianness = svt_spi_types::BIG_ENDIAN`。 |
| **Scoreboard / FIFO 收到全 `0` 数据** | 监听了错误的端口。Slave 角色应只听 `rx_xact_observed_port` (MOSI)。 |
