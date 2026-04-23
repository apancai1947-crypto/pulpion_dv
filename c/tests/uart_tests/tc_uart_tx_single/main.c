/*
 * TF_UART_001 — Single TX byte with loopback verification
 * Sends 0xA5 via UART TX, verifies that loopback returns 0xA5.
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

int main(void)
{
    volatile unsigned char *thr = (volatile unsigned char *)UART_REG_THR;
    volatile unsigned char *rbr = (volatile unsigned char *)UART_REG_RBR;
    volatile unsigned char *lsr = (volatile unsigned char *)UART_REG_LSR;
    unsigned char tx_byte = 0xA5;
    unsigned char rx_byte;

    printf("TF_UART_001: Single TX byte 0xA5 loopback\n");

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
        printf("PASS: TX 0x%02X, RX 0x%02X\n", tx_byte, rx_byte);
    } else {
        printf("FAIL: TX 0x%02X, RX 0x%02X (expected 0x%02X)\n",
               tx_byte, rx_byte, tx_byte);
    }

    end_of_test();
    return 0;
}
