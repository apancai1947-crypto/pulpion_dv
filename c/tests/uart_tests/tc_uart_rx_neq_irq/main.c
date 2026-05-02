/*
 * TF_UART_021 — RX data available interrupt verification
 * Enables ERBFI interrupt (IER=1), sends a byte, checks IIR
 * for RX data available interrupt (IIR[3:0]==0x04),
 * consumes the byte, then disables the interrupt.
 */

#include "uart.h"
#include "common_macro.h"

extern int printf(const char *fmt, ...);
extern void end_of_test(void);

#define UART_REG_THR ((unsigned char *)0x1A100000)
#define UART_REG_RBR ((unsigned char *)0x1A100000)
#define UART_REG_LSR ((unsigned char *)0x1A100004)
#define UART_REG_IER ((unsigned char *)0x1A100004)
#define UART_REG_IIR ((unsigned char *)0x1A100008)

#define LSR_THRE (1 << 5)
#define LSR_DR   1
#define IER_ERBFI (1 << 0)
#define IIR_RX_AVAIL 0x04

#define TIMEOUT_COUNT 100000

int main(void)
{
    volatile unsigned char *thr = (volatile unsigned char *)UART_REG_THR;
    volatile unsigned char *rbr = (volatile unsigned char *)UART_REG_RBR;
    volatile unsigned char *lsr = (volatile unsigned char *)UART_REG_LSR;
    volatile unsigned char *ier = (volatile unsigned char *)UART_REG_IER;
    volatile unsigned char *iir = (volatile unsigned char *)UART_REG_IIR;
    unsigned char iir_val;
    int pass = 1;

    printf("INFO: TF_UART_021: RX data available interrupt check\n");

    /* Enable RX data available interrupt (ERBFI) */
    *ier = IER_ERBFI;
    printf("INFO:   IER set to 0x%02X\n", *ier);

    /* Wait for TX empty */
    while (!(*lsr & LSR_THRE))
        ;

    /* Send a byte to trigger RX */
    *thr = 0x37;

    /* Wait for RX data ready */
    int timeout = TIMEOUT_COUNT;
    while (!(*lsr & LSR_DR) && --timeout)
        ;

    if (!timeout) {
        printf("INFO:   FAIL: RX data not ready (timeout)\n");
        pass = 0;
        goto cleanup;
    }

    /* Read IIR — check for RX data available interrupt */
    iir_val = *iir;
    printf("INFO:   IIR = 0x%02X\n", iir_val);

    if ((iir_val & 0x0F) == IIR_RX_AVAIL) {
        printf("INFO:   RX data available interrupt detected — PASS\n");
    } else {
        printf("INFO:   IIR[3:0] = 0x%02X (expected 0x%02X) — FAIL\n",
               iir_val & 0x0F, IIR_RX_AVAIL);
        pass = 0;
    }

    /* Consume the received byte */
    (void)*rbr;

cleanup:
    /* Disable interrupt */
    *ier = 0x00;
    printf("INFO:   IER cleared to 0x%02X\n", *ier);

    if (pass) {
        printf("INFO: PASS: RX interrupt verification passed\n");
    } else {
        printf("INFO: FAIL: RX interrupt verification failed\n");
    }

    end_of_test();
    return 0;
}
