/*
 * TF_UART_051 — Post-reset default register values
 * After uart_init(), verifies:
 *   LCR  = 0x03 (8N1)
 *   MCR  = 0x00 (no loopback, no modem control)
 *   LSR  THRE bit is set (TX empty)
 */

#include "uart.h"
#include "common_macro.h"

extern int printf(const char *fmt, ...);
extern void end_of_test(void);

#define UART_REG_LSR ((unsigned char *)0x1A100004)
#define UART_REG_LCR ((unsigned char *)0x1A10000C)
#define UART_REG_MCR ((unsigned char *)0x1A100010)

#define LSR_THRE (1 << 5)

int main(void)
{
    volatile unsigned char *lsr = (volatile unsigned char *)UART_REG_LSR;
    volatile unsigned char *lcr = (volatile unsigned char *)UART_REG_LCR;
    volatile unsigned char *mcr = (volatile unsigned char *)UART_REG_MCR;
    unsigned char lcr_val, mcr_val, lsr_val;
    int pass = 1;

    printf("INFO: TF_UART_051: Verify post-reset default register values\n");

    /* Check LCR = 0x03 (8N1) */
    lcr_val = *lcr;
    if (lcr_val == 0x03) {
        printf("INFO:   LCR = 0x%02X (expected 0x03) — PASS\n", lcr_val);
    } else {
        printf("INFO:   LCR = 0x%02X (expected 0x03) — FAIL\n", lcr_val);
        pass = 0;
    }

    /* Check MCR = 0x00 (no loopback, no modem control) */
    mcr_val = *mcr;
    if (mcr_val == 0x00) {
        printf("INFO:   MCR = 0x%02X (expected 0x00) — PASS\n", mcr_val);
    } else {
        printf("INFO:   MCR = 0x%02X (expected 0x00) — FAIL\n", mcr_val);
        pass = 0;
    }

    /* Check LSR THRE bit is set (TX empty after init) */
    lsr_val = *lsr;
    if (lsr_val & LSR_THRE) {
        printf("INFO:   LSR = 0x%02X, THRE set — PASS\n", lsr_val);
    } else {
        printf("INFO:   LSR = 0x%02X, THRE NOT set — FAIL\n", lsr_val);
        pass = 0;
    }

    if (pass) {
        printf("INFO: PASS: All reset default values correct\n");
    } else {
        printf("INFO: FAIL: Some reset default values incorrect\n");
    }

    end_of_test();
    return 0;
}
