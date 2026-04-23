/*
 * TF_UART_005 — Baud rate divisor switching
 * Changes baud rate by setting DLAB=1, writing DLM/DLL,
 * setting DLAB=0, then sends byte and verifies loopback.
 * Tests at divisor 31 (781250 baud) and divisor 124 (195312 baud).
 */

#include "uart.h"
#include "common_macro.h"

extern int printf(const char *fmt, ...);
extern void end_of_test(void);

#define UART_REG_THR ((unsigned char *)0x1A100000)
#define UART_REG_RBR ((unsigned char *)0x1A100000)
#define UART_REG_LSR ((unsigned char *)0x1A100004)
#define UART_REG_LCR ((unsigned char *)0x1A10000C)
#define UART_REG_DLL ((unsigned char *)0x1A100000)
#define UART_REG_DLM ((unsigned char *)0x1A100004)

#define LSR_THRE (1 << 5)
#define LSR_DR   1
#define LCR_DLAB (1 << 7)

static int test_baudrate(unsigned short divisor, unsigned char dll, unsigned char dlm,
                         const char *desc)
{
    volatile unsigned char *thr  = (volatile unsigned char *)UART_REG_THR;
    volatile unsigned char *rbr  = (volatile unsigned char *)UART_REG_RBR;
    volatile unsigned char *lsr  = (volatile unsigned char *)UART_REG_LSR;
    volatile unsigned char *lcr  = (volatile unsigned char *)UART_REG_LCR;
    volatile unsigned char *dll_reg = (volatile unsigned char *)UART_REG_DLL;
    volatile unsigned char *dlm_reg = (volatile unsigned char *)UART_REG_DLM;
    unsigned char tx_byte = 0xA5;
    unsigned char rx_byte;
    int timeout;
    int pass;

    printf("  Testing %s (divisor=%d)\n", desc, divisor);

    /* Set DLAB=1 to access divisor registers */
    *lcr = *lcr | LCR_DLAB;

    /* Write divisor */
    *dlm_reg = dlm;
    *dll_reg = dll;

    /* Set DLAB=0, restore 8N1 */
    *lcr = 0x03;

    /* Wait for TX empty */
    timeout = 100000;
    while (!(*lsr & LSR_THRE) && --timeout)
        ;
    if (!timeout) {
        printf("    FAIL: TX empty timeout\n");
        return 0;
    }

    /* Send byte */
    *thr = tx_byte;

    /* Wait for RX data ready with timeout */
    timeout = 100000;
    while (!(*lsr & LSR_DR) && --timeout)
        ;
    if (!timeout) {
        printf("    FAIL: RX ready timeout\n");
        return 0;
    }

    /* Read byte */
    rx_byte = *rbr;

    pass = (rx_byte == tx_byte);
    if (pass) {
        printf("    PASS: TX 0x%02X, RX 0x%02X\n", tx_byte, rx_byte);
    } else {
        printf("    FAIL: TX 0x%02X, RX 0x%02X\n", tx_byte, rx_byte);
    }
    return pass;
}

int main(void)
{
    int all_pass = 1;

    printf("TF_UART_005: Baud rate divisor switching\n");

    /* Divisor 31 = 0x001F => DLM=0x00, DLL=0x1F */
    all_pass &= test_baudrate(31, 0x1F, 0x00, "781250 baud (divisor=31)");

    /* Divisor 124 = 0x007C => DLM=0x00, DLL=0x7C */
    all_pass &= test_baudrate(124, 0x7C, 0x00, "195312 baud (divisor=124)");

    if (all_pass) {
        printf("PASS: All baud rate tests passed\n");
    } else {
        printf("FAIL: Some baud rate tests failed\n");
    }

    end_of_test();
    return 0;
}
