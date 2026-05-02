/*
 * Generic UART Test
 * Supports single byte loopback or pattern-based loopback.
 * Configured via defines: TX_BYTE, DATA_PATTERN (0=all0, 1=all1, 2=random)
 */

#include "uart.h"
#include "common_macro.h"

extern int printf(const char *fmt, ...);
extern void end_of_test(void);

#define UART_REG_THR ((unsigned char *)0x1A100000)
#define UART_REG_RBR ((unsigned char *)0x1A100000)
#define UART_REG_LSR ((unsigned char *)0x1A100014)

#define LSR_THRE (1 << 5)
#define LSR_DR   1

#ifndef NUM_BYTES
#define NUM_BYTES 1
#endif

/* 8-bit LFSR for random data */
static unsigned char lfsr_step(unsigned char lfsr) {
    unsigned char feedback = ((lfsr >> 7) ^ (lfsr >> 5) ^ (lfsr >> 4) ^ (lfsr >> 3)) & 1;
    return (lfsr << 1) | feedback;
}

int main(void) {
  uart_init();
    volatile unsigned char *thr = (volatile unsigned char *)UART_REG_THR;
    volatile unsigned char *rbr = (volatile unsigned char *)UART_REG_RBR;
    volatile unsigned char *lsr = (volatile unsigned char *)UART_REG_LSR;
    
    unsigned char tx_byte;
    unsigned char rx_byte;
    unsigned char lfsr = 0xCE;
    int pass_count = 0;

    /* Initialize UART and flush the single space echo */
    printf(" ");
    
    int timeout = 1000;
    while (timeout--) {
        if (*lsr & LSR_DR) {
            volatile unsigned char dummy = *rbr;
            (void)dummy;
        }
    }

    for (int i = 0; i < NUM_BYTES; i++) {
#ifdef DATA_PATTERN
        if (DATA_PATTERN == 0) tx_byte = 0x00;
        else if (DATA_PATTERN == 1) tx_byte = 0xFF;
        else { // random
            lfsr = lfsr_step(lfsr);
            if (lfsr == 0) lfsr = lfsr_step(lfsr);
            tx_byte = lfsr;
        }
#elif defined(TX_BYTE)
        tx_byte = TX_BYTE;
#else
        tx_byte = 0xA5; // default
#endif

        /* Wait for TX empty */
        while (!(*lsr & LSR_THRE));
        *thr = tx_byte;

        /* Wait for RX data ready */
        while (!(*lsr & LSR_DR));
        rx_byte = *rbr;

        if (rx_byte == tx_byte) {
            pass_count++;
        } else {
            printf("UVM_ERROR: [FW] Mismatch at byte %d: TX=0x%02X, RX=0x%02X\n", i, tx_byte, rx_byte);
        }
    }

    if (pass_count == NUM_BYTES) {
        printf("UVM_INFO: [FW] TEST PASSED\n");
    } else {
        printf("UVM_ERROR: [FW] TEST FAILED (%d/%d passed)\n", pass_count, NUM_BYTES);
    }

    end_of_test();
    return 0;
}
