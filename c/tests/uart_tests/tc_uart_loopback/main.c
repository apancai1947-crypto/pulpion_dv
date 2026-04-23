/*
 * TF_UART_052 — Internal UART loopback
 * Enables internal loopback (MCR bit 4 = 1), sends 0xAB,
 * verifies RX reads 0xAB, then disables loopback.
 */

#include "uart.h"
#include "common_macro.h"

extern int printf(const char *fmt, ...);
extern void end_of_test(void);

#define UART_REG_THR ((unsigned char *)0x1A100000)
#define UART_REG_RBR ((unsigned char *)0x1A100000)
#define UART_REG_LSR ((unsigned char *)0x1A100004)
#define UART_REG_MCR ((unsigned char *)0x1A100010)

#define LSR_THRE (1 << 5)
#define LSR_DR   1
#define MCR_LOOP (1 << 4)

#define TIMEOUT_COUNT 100000

int main(void)
{
    volatile unsigned char *thr = (volatile unsigned char *)UART_REG_THR;
    volatile unsigned char *rbr = (volatile unsigned char *)UART_REG_RBR;
    volatile unsigned char *lsr = (volatile unsigned char *)UART_REG_LSR;
    volatile unsigned char *mcr = (volatile unsigned char *)UART_REG_MCR;
    unsigned char tx_byte = 0xAB;
    unsigned char rx_byte;
    int pass;

    printf("TF_UART_052: Internal loopback mode\n");

    /* Enable internal loopback */
    *mcr = MCR_LOOP;
    printf("  MCR = 0x%02X (loopback enabled)\n", *mcr);

    /* Wait for TX empty */
    while (!(*lsr & LSR_THRE))
        ;

    /* Send byte */
    *thr = tx_byte;

    /* Wait for RX data ready */
    int timeout = TIMEOUT_COUNT;
    while (!(*lsr & LSR_DR) && --timeout)
        ;

    if (!timeout) {
        printf("  FAIL: RX data not ready (timeout)\n");
        pass = 0;
        goto cleanup;
    }

    /* Read byte */
    rx_byte = *rbr;

    pass = (rx_byte == tx_byte);
    if (pass) {
        printf("  PASS: Loopback TX 0x%02X, RX 0x%02X\n", tx_byte, rx_byte);
    } else {
        printf("  FAIL: Loopback TX 0x%02X, RX 0x%02X\n", tx_byte, rx_byte);
    }

cleanup:
    /* Disable loopback */
    *mcr = 0x00;
    printf("  MCR = 0x%02X (loopback disabled)\n", *mcr);

    if (pass) {
        printf("PASS: Internal loopback test passed\n");
    } else {
        printf("FAIL: Internal loopback test failed\n");
    }

    end_of_test();
    return 0;
}
