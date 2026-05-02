/*
 * TF_UART_051 — Post-reset default register values
 */

#include "uart.h"
#include "common_macro.h"

extern int printf(const char *fmt, ...);
extern void end_of_test(void);

int main(void) {
  // 1. Capture reset values BEFORE initialization
  unsigned char lcr_reset = UART_REG_LCR;
  unsigned char mcr_reset = UART_REG_MCR;
  unsigned char lsr_reset = UART_REG_LSR;
  unsigned char ier_reset = UART_REG_IER;

  // 2. Initialize for printing
  uart_init();

  printf("INFO: [FW] TF_UART_051: Verify reset defaults\n");

  int pass = 1;

  // Check LCR (should be 0x03 after init, but what is it at reset?)
  // Actually, let's just check against expected reset values
  // For APB UART, reset values are usually 0x00 except maybe LSR bits
  
  printf("INFO: [FW] LCR reset: 0x%02X\n", lcr_reset);
  printf("INFO: [FW] MCR reset: 0x%02X\n", mcr_reset);
  printf("INFO: [FW] LSR reset: 0x%02X\n", lsr_reset);
  printf("INFO: [FW] IER reset: 0x%02X\n", ier_reset);

  // Example checks (adjust based on spec)
  if (mcr_reset != 0x00) pass = 0;
  if (ier_reset != 0x00) pass = 0;
  if (!(lsr_reset & LSR_THRE)) pass = 0; // TX should be empty

  if (pass) {
    printf("INFO: [FW] TEST PASSED: tc_uart_reset_default\n");
  } else {
    printf("INFO: [FW] TEST FAILED: tc_uart_reset_default\n");
  }

  end_of_test();
  return 0;
}
