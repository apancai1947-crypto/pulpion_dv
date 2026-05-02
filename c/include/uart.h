#ifndef UART_H
#define UART_H

#include <stdint.h>

#define UART_BASE 0x1A100000

#define UART_REG_RBR (*(volatile unsigned char *)(UART_BASE + 0x00))
#define UART_REG_THR (*(volatile unsigned char *)(UART_BASE + 0x00))
#define UART_REG_IER (*(volatile unsigned char *)(UART_BASE + 0x04))
#define UART_REG_IIR (*(volatile unsigned char *)(UART_BASE + 0x08))
#define UART_REG_FCR (*(volatile unsigned char *)(UART_BASE + 0x08))
#define UART_REG_LCR (*(volatile unsigned char *)(UART_BASE + 0x0C))
#define UART_REG_MCR (*(volatile unsigned char *)(UART_BASE + 0x10))
#define UART_REG_LSR (*(volatile unsigned char *)(UART_BASE + 0x14))
#define UART_REG_MSR (*(volatile unsigned char *)(UART_BASE + 0x18))
#define UART_REG_SCR (*(volatile unsigned char *)(UART_BASE + 0x1C))
#define UART_REG_DLL (*(volatile unsigned char *)(UART_BASE + 0x00))
#define UART_REG_DLM (*(volatile unsigned char *)(UART_BASE + 0x04))

// LCR bits
#define LCR_DLAB (1 << 7)

// LSR bits
#define LSR_DR   (1 << 0)
#define LSR_THRE (1 << 5)
#define LSR_TEMT (1 << 6)

void uart_init(void);
void uart_sendchar(char c);
char uart_getchar(void);
void uart_wait_tx_done(void);

#endif
