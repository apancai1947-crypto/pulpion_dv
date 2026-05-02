/*
 * TF_UART_020 — TX FIFO THRE flag verification
 * Checks that LSR THRE bit is set after init (TX empty).
 * Writes a byte, waits for TX complete, verifies THRE is set again.
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

#define TIMEOUT_COUNT 100000

int main(void)
{
    volatile unsigned char *thr = (volatile unsigned char *)UART_REG_THR;
    volatile unsigned char *rbr = (volatile unsigned char *)UART_REG_RBR;
    volatile unsigned char *lsr = (volatile unsigned char *)UART_REG_LSR;
    unsigned char lsr_val;
    int pass = 1;

    printf("INFO: TF_UART_020: TX FIFO THRE flag verification\n");

    /* Step 1: Check THRE is set after init */
    lsr_val = *lsr;
    if (lsr_val & LSR_THRE) {
        printf("INFO:   THRE set after init (LSR=0x%02X) — PASS\n", lsr_val);
    } else {
        printf("INFO:   THRE NOT set after init (LSR=0x%02X) — FAIL\n", lsr_val);
        pass = 0;
    }

    /* Step 2: Write a byte */
    *thr = 0x42;

    /* Step 3: Wait for TX to complete (THRE set again) */
    int timeout = TIMEOUT_COUNT;
    while (!(*lsr & LSR_THRE) && --timeout)
        ;

    if (!timeout) {
        printf("INFO:   FAIL: THRE not set after TX (timeout)\n");
        pass = 0;
    } else {
        lsr_val = *lsr;
        if (lsr_val & LSR_THRE) {
            printf("INFO:   THRE set after TX (LSR=0x%02X) — PASS\n", lsr_val);
        } else {
            printf("INFO:   THRE NOT set after TX (LSR=0x%02X) — FAIL\n", lsr_val);
            pass = 0;
        }
    }

    /* Consume the loopback byte to avoid leaving data in FIFO */
    timeout = TIMEOUT_COUNT;
    while (!(*lsr & LSR_DR) && --timeout)
        ;
    if (timeout) {
        (void)*rbr;
    }

    if (pass) {
        printf("INFO: PASS: TX FIFO THRE flag behaves correctly\n");
    } else {
        printf("INFO: FAIL: TX FIFO THRE flag issues detected\n");
    }

    end_of_test();
    return 0;
}
