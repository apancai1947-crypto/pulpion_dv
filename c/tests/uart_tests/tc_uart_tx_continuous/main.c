/*
 * TF_UART_003 — Continuous TX of 32 bytes (0x00..0x1F)
 * Sends 32 consecutive bytes and verifies each loops back correctly.
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

#define NUM_BYTES 32

int main(void)
{
    volatile unsigned char *thr = (volatile unsigned char *)UART_REG_THR;
    volatile unsigned char *rbr = (volatile unsigned char *)UART_REG_RBR;
    volatile unsigned char *lsr = (volatile unsigned char *)UART_REG_LSR;
    int pass_count = 0;

    printf("TF_UART_003: Send 32 bytes (0x00..0x1F), verify loopback\n");

    for (int i = 0; i < NUM_BYTES; i++) {
        unsigned char tx_byte = (unsigned char)i;
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

    if (pass_count == NUM_BYTES) {
        printf("PASS: All %d bytes matched\n", NUM_BYTES);
    } else {
        printf("FAIL: %d/%d bytes matched\n", pass_count, NUM_BYTES);
    }

    end_of_test();
    return 0;
}
