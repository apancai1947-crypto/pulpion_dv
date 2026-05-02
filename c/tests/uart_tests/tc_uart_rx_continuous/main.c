/*
 * TF_UART_004 — Continuous RX with FIFO clear (32 bytes, 0x01..0x20)
 * Clears FIFOs, sends 32 bytes, verifies each loops back correctly.
 */

#include "uart.h"
#include "common_macro.h"

extern int printf(const char *fmt, ...);
extern void end_of_test(void);

#define UART_REG_THR ((unsigned char *)0x1A100000)
#define UART_REG_RBR ((unsigned char *)0x1A100000)
#define UART_REG_LSR ((unsigned char *)0x1A100014)
#define UART_REG_FCR ((unsigned char *)0x1A100008)

#define LSR_THRE (1 << 5)
#define LSR_DR   1

#define NUM_BYTES 32

int main(void)
{
  uart_init();
    volatile unsigned char *thr = (volatile unsigned char *)UART_REG_THR;
    volatile unsigned char *rbr = (volatile unsigned char *)UART_REG_RBR;
    volatile unsigned char *lsr = (volatile unsigned char *)UART_REG_LSR;
    volatile unsigned char *fcr = (volatile unsigned char *)UART_REG_FCR;
    int pass_count = 0;

    printf("INFO: TF_UART_004: Clear FIFOs, send 32 bytes (0x01..0x20), verify loopback\n");

    /* Clear both TX and RX FIFOs */
    *fcr = 0x07;

    for (int i = 0; i < NUM_BYTES; i++) {
        unsigned char tx_byte = (unsigned char)(i + 1);
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
            printf("INFO:   FAIL at byte %d: TX 0x%02X, RX 0x%02X\n",
                   i, tx_byte, rx_byte);
        }
    }

    if (pass_count == NUM_BYTES) {
        printf("INFO: PASS: All %d bytes matched after FIFO clear\n", NUM_BYTES);
    } else {
        printf("INFO: FAIL: %d/%d bytes matched\n", pass_count, NUM_BYTES);
    }

    end_of_test();
    return 0;
}
