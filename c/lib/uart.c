#include "uart.h"
#include "common_macro.h"

void uart_init(void) {
    // Set DLAB to 1 to access divisor latches
    UART_REG_LCR = LCR_DLAB;

    // Set divisor (Baud Rate)
    // baud = CLK_FREQ / (cfg_div + 1)
    UART_REG_DLL = (UART_DIVISOR & 0xFF);
    UART_REG_DLM = (UART_DIVISOR >> 8) & 0xFF;

    // Set LCR: 8 data bits, 1 stop bit, no parity, DLAB = 0
    UART_REG_LCR = 0x03;

    // Enable FIFO, reset RX/TX FIFO
    UART_REG_FCR = 0x07;

    // Disable interrupts
    UART_REG_IER = 0x00;
}

void uart_sendchar(char c) {
    // Wait for TX FIFO empty (THRE)
    while (!(UART_REG_LSR & LSR_THRE));
    UART_REG_THR = c;
}

char uart_getchar(void) {
    // Wait for RX Data Ready (DR)
    while (!(UART_REG_LSR & LSR_DR));
    return UART_REG_RBR;
}

void uart_wait_tx_done(void) {
    // Wait for Transmitter Empty (TEMT) - both FIFO and Shift Register empty
    while (!(UART_REG_LSR & LSR_TEMT));
}
