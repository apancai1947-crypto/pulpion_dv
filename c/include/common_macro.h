#ifndef COMMON_MACRO_H
#define COMMON_MACRO_H

// DV 环境特有定义（PULPino 原始头文件未提供）

// UART divisor: baud = CLK_FREQ / (cfg_div + 1)
// cfg_div = 31 → 25MHz / 32 = 781250 baud (matches uart_monitor default)
#define UART_DIVISOR  31

// End-of-test character
#define EOT 0x04

#endif
