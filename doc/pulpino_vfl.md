# uart

| 测试点ID | 测试类别 | 测试内容 | 验收标准 | 对应Test Case名称（CTEST=） |
| --- | --- | --- | --- | --- |
| TF_UART_001 | 基础功能 | 单字节发送功能 | CPU发送一字节，Monitor正确采集到波形与数据 | tc_uart_tx_single |
| TF_UART_002 | 基础功能 | 单字节接收功能 | 外部激励发送一帧，UART正确接收并写入RX FIFO | tc_uart_rx_single |
| TF_UART_003 | 基础功能 | 连续多字节发送 | 连续发送32/64字节，无丢包、无错位 | tc_uart_tx_continuous |
| TF_UART_004 | 基础功能 | 连续多字节接收 | 连续接收32/64字节，FIFO正常、无丢包 | tc_uart_rx_continuous |
| TF_UART_005 | 基础功能 | 不同波特率配置 | 9600 / 115200 / 自定义波特均能正常收发 | tc_uart_baudrate_switch |
| TF_UART_010 | 帧格式与协议 | 标准帧格式（8N1） | 起始位 + 8bit数据 + 1停止位，时序正确 | tc_uart_frame_8n1 |
| TF_UART_011 | 帧格式与协议 | 全0数据帧收发 | 数据0x00帧结构正确、无误判 | tc_uart_data_all0 |
| TF_UART_012 | 帧格式与协议 | 全1数据帧收发 | 数据0xFF帧结构正确、无误判 | tc_uart_data_all1 |
| TF_UART_013 | 帧格式与协议 | 随机数据收发 | 随机字节流收发正确 | tc_uart_data_random |
| TF_UART_020 | FIFO & 中断 | TX FIFO空/满标志 | 标志位随FIFO状态正确翻转 | tc_uart_tx_fifo_flag |
| TF_UART_021 | FIFO & 中断 | RX FIFO非空中断 | 收到数据后产生正确中断 | tc_uart_rx_neq_irq |
| TF_UART_022 | FIFO & 中断 | RX FIFO阈值中断 | 达到FIFO阈值触发中断 | tc_uart_fifo_threshold |
| TF_UART_023 | FIFO & 中断 | TX FIFO空中断 | 发送完成后空中断正常 | tc_uart_tx_empty_irq |
| TF_UART_030 | 异常 & 错误处理 | 帧错误（Frame Error） | 停止位错误时，UART置位FE标志 | tc_uart_frame_error |
| TF_UART_031 | 异常 & 错误处理 | 溢出错误（Overrun Error） | FIFO满仍收数据，置位OE标志 | tc_uart_overrun_error |
| TF_UART_032 | 异常 & 错误处理 | 虚假起始位过滤 | 窄脉冲不被识别为起始位 | tc_uart_fake_start_bit |
| TF_UART_033 | 异常 & 错误处理 | Break字符检测 | 总线长时间拉低可识别Break状态 | tc_uart_break_detect |
| TF_UART_040 | 流控CTS/RTS | CTS使能发送 | **N/A** — VERILATOR模式下CTS/RTS未连接 | N/A |
| TF_UART_041 | 流控CTS/RTS | CTS禁止发送 | **N/A** — VERILATOR模式下CTS/RTS未连接 | N/A |
| TF_UART_042 | 流控CTS/RTS | RTS随FIFO水位自动控制 | **N/A** — VERILATOR模式下CTS/RTS未连接 | N/A |
| TF_UART_050 | 系统集成 | UART中断到PLIC | 中断可送达核并正确响应 | tc_uart_irq_to_plic |
| TF_UART_051 | 系统集成 | 复位后UART初始状态 | 复位后寄存器、FIFO处于默认状态 | tc_uart_reset_default |
| TF_UART_052 | 系统集成 | 回环测试（Loopback） | TX内部回环RX，收发通路完全正常 | tc_uart_loopback |
| TF_UART_053 | 系统集成 | 与其他外设并发 | UART与GPIO/I2C/SPI同时工作不冲突 | tc_uart_multi_peri_concurrent |
| TF_UART_060 | 稳定性&压力 | 长时间大数据流收发 | 连续10000+字节无错误、无溢出 | tc_uart_long_stress |
| TF_UART_061 | 稳定性&压力 | 最大波特率压力 | 最高波特下长时间稳定收发 | tc_uart_max_baud_stress |
