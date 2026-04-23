/*
 * TF_UART_002 — Multiple distinct single-byte TX/RX
 * Sends 5 different bytes {0x55, 0xAA, 0x01, 0x80, 0xFF} and
 * verifies each loops back correctly.
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
    unsigned char test_data[] = {0x55, 0xAA, 0x01, 0x80, 0xFF};
    int num_tests = sizeof(test_data) / sizeof(test_data[0]);
    int pass_count = 0;

    printf("TF_UART_002: Send 5 distinct bytes, verify loopback\n");

    for (int i = 0; i < num_tests; i++) {
        unsigned char tx_byte = test_data[i];
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
            printf("  PASS: TX 0x%02X, RX 0x%02X\n", tx_byte, rx_byte);
            pass_count++;
        } else {
            printf("  FAIL: TX 0x%02X, RX 0x%02X\n", tx_byte, rx_byte);
        }
    }

    if (pass_count == num_tests) {
        printf("PASS: All %d bytes matched\n", num_tests);
    } else {
        printf("FAIL: %d/%d bytes matched\n", pass_count, num_tests);
    }

    end_of_test();
    return 0;
}
