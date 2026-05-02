/*
 * TF_UART_010 — Frame format 8N1 verification
 * Verifies LCR register is 0x03 (8N1) after uart_init(),
 * then sends a byte and verifies loopback.
 */

#include "uart.h"
#include "common_macro.h"

extern int printf(const char *fmt, ...);
extern void end_of_test(void);

#define UART_REG_THR ((unsigned char *)0x1A100000)
#define UART_REG_RBR ((unsigned char *)0x1A100000)
#define UART_REG_LSR ((unsigned char *)0x1A100004)
#define UART_REG_LCR ((unsigned char *)0x1A10000C)

#define LSR_THRE (1 << 5)
#define LSR_DR   1

int main(void)
{
    volatile unsigned char *thr = (volatile unsigned char *)UART_REG_THR;
    volatile unsigned char *rbr = (volatile unsigned char *)UART_REG_RBR;
    volatile unsigned char *lsr = (volatile unsigned char *)UART_REG_LSR;
    volatile unsigned char *lcr = (volatile unsigned char *)UART_REG_LCR;
    unsigned char tx_byte = 0x55;
    unsigned char rx_byte;
    unsigned char lcr_val;
    int lcr_pass;

    printf("INFO: TF_UART_010: Verify 8N1 frame format (LCR=0x03)\n");

    /* Check LCR value */
    lcr_val = *lcr;
    lcr_pass = (lcr_val == 0x03);
    printf("INFO:   LCR = 0x%02X (expected 0x03) — %s\n",
           lcr_val, lcr_pass ? "PASS" : "FAIL");

    /* Wait for TX empty */
    while (!(*lsr & LSR_THRE))
        ;

    /* Send byte */
    *thr = tx_byte;

    /* Wait for RX data ready */
    while (!(*lsr & LSR_DR))
        ;

    /* Read byte */
    rx_byte = *rbr;

    if (rx_byte == tx_byte && lcr_pass) {
        printf("INFO: PASS: 8N1 frame verified, loopback TX 0x%02X RX 0x%02X\n",
               tx_byte, rx_byte);
    } else {
        printf("INFO: FAIL: lcr_pass=%d, loopback %s\n",
               lcr_pass, (rx_byte == tx_byte) ? "OK" : "MISMATCH");
    }

    end_of_test();
    return 0;
}
