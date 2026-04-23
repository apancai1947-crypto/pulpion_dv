/*
 * TF_UART_013 — Pseudo-random data bytes via LFSR
 * Generates 16 pseudo-random bytes using an LFSR,
 * sends each, and verifies loopback.
 */

#include "uart.h"
#include "common_macro.h"

extern int printf(const char *fmt, ...);
extern void end_of_test(void);

#define UART_REG_THR ((unsigned char *)0x1A100000)
#define UART_REG_RBR ((unsigned char *)0x1A100000)
#define UART_REG_LSR ((unsigned char *)0x1A100004)

#define LSR_THRE (1 << 5)
#define LSR_DR   1

#define NUM_RANDOM_BYTES 16

/* 8-bit LFSR with taps at bits 7, 5, 4, 3 (x^8 + x^6 + x^5 + x^4 + 1) */
static unsigned char lfsr_step(unsigned char lfsr)
{
    unsigned char feedback = ((lfsr >> 7) ^ (lfsr >> 5) ^ (lfsr >> 4) ^ (lfsr >> 3)) & 1;
    return (lfsr << 1) | feedback;
}

int main(void)
{
    volatile unsigned char *thr = (volatile unsigned char *)UART_REG_THR;
    volatile unsigned char *rbr = (volatile unsigned char *)UART_REG_RBR;
    volatile unsigned char *lsr = (volatile unsigned char *)UART_REG_LSR;
    unsigned char lfsr = 0xCE;  /* Non-zero seed */
    int pass_count = 0;

    printf("TF_UART_013: Send 16 pseudo-random bytes (LFSR), verify loopback\n");

    for (int i = 0; i < NUM_RANDOM_BYTES; i++) {
        lfsr = lfsr_step(lfsr);
        /* Skip zero values from LFSR */
        if (lfsr == 0) {
            lfsr = lfsr_step(lfsr);
        }

        unsigned char tx_byte = lfsr;
        unsigned char rx_byte;

        /* Wait for TX hold register empty */
        while (!(*lsr & LSR_THRE))
            ;

        /* Send byte */
        *thr = tx_byte;

        /* Wait for RX data ready */
        while (!(*lsr & LSR_DR))
            ;

        /* Read byte */
        rx_byte = *rbr;

        if (rx_byte == tx_byte) {
            pass_count++;
        } else {
            printf("  FAIL at byte %d: TX 0x%02X, RX 0x%02X\n",
                   i, tx_byte, rx_byte);
        }
    }

    if (pass_count == NUM_RANDOM_BYTES) {
        printf("PASS: All %d pseudo-random bytes matched\n", NUM_RANDOM_BYTES);
    } else {
        printf("FAIL: %d/%d pseudo-random bytes matched\n",
               pass_count, NUM_RANDOM_BYTES);
    }

    end_of_test();
    return 0;
}
