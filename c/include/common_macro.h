#ifndef COMMON_MACRO_H
#define COMMON_MACRO_H

// DV 环境特有定义（PULPino 原始头文件未提供）

// ---- UART Baud Rate ----
#ifndef UART_DIVISOR
#define UART_DIVISOR          31   /* baud = CLK_FREQ / (cfg_div + 1), 31 → 781250 */
#endif

// ---- LCR fields (Line Control Register) ----
#ifndef UART_DATA_BITS
#define UART_DATA_BITS        8    /* 5, 6, 7, 8 */
#endif
#ifndef UART_STOP_BITS
#define UART_STOP_BITS        1    /* 1, 2 */
#endif
#ifndef UART_PARITY_EN
#define UART_PARITY_EN        0    /* 0=none, 1=enable */
#endif
#ifndef UART_PARITY_EVEN
#define UART_PARITY_EVEN      0    /* 0=odd, 1=even (when PARITY_EN=1) */
#endif
#ifndef UART_PARITY_STICK
#define UART_PARITY_STICK     0    /* 0=normal, 1=stick (when PARITY_EN=1) */
#endif
#ifndef UART_BREAK_EN
#define UART_BREAK_EN         0    /* 0=normal, 1=break condition */
#endif

// ---- FCR fields (FIFO Control Register) ----
#ifndef UART_FIFO_EN
#define UART_FIFO_EN          1    /* 0=disable, 1=enable */
#endif
#ifndef UART_FIFO_RX_RESET
#define UART_FIFO_RX_RESET    1    /* 0=normal, 1=clear RX FIFO */
#endif
#ifndef UART_FIFO_TX_RESET
#define UART_FIFO_TX_RESET    1    /* 0=normal, 1=clear TX FIFO */
#endif
#ifndef UART_FIFO_TRIGGER
#define UART_FIFO_TRIGGER     1    /* 1, 4, 8, 14 bytes */
#endif

// ---- MCR fields (Modem Control Register) ----
#ifndef UART_MCR_DTR
#define UART_MCR_DTR          0
#endif
#ifndef UART_MCR_RTS
#define UART_MCR_RTS          0
#endif
#ifndef UART_MCR_OUT1
#define UART_MCR_OUT1         0
#endif
#ifndef UART_MCR_OUT2
#define UART_MCR_OUT2         0
#endif
#ifndef UART_MCR_LOOPBACK
#define UART_MCR_LOOPBACK     0
#endif

// End-of-test character
#define EOT 0x04

// ---- Memory-Mapped Stdout and Event Registers ----
// Stdout register: C firmware writes 32-bit packed characters here
#define STDOUT_ADDR           0x1A118000
#define STDOUT_REG            (*(volatile unsigned int *)STDOUT_ADDR)

// TB->C Event status register: C firmware polls this for events
#define EVENT_TB2C_STATUS_ADDR 0x1A118004
#define EVENT_TB2C_STATUS_REG (*(volatile unsigned int *)EVENT_TB2C_STATUS_ADDR)

// TB->C Event codes
#define EVENT_WAIT      1
#define EVENT_CONTINUE  2
#define EVENT_STOP      3

#endif
