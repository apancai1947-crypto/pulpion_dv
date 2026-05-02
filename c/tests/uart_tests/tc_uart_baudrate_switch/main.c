/*
 * TF_UART_005 — Baudrate Divisor Register Access
 */

#include "uart.h"
#include "common_macro.h"

extern int printf(const char *fmt, ...);
extern void end_of_test(void);

int main(void) {
  uart_init();
  printf("INFO: [FW] TF_UART_005: Baudrate Switch (Register Access)\n");

  int pass = 1;

  // DLL/DLM access requires DLAB=1 in LCR
  UART_REG_LCR |= 0x80;

  // Test Case 1: Divisor = 12
  UART_REG_DLL = 12;
  UART_REG_DLM = 0;
  if (UART_REG_DLL != 12 || UART_REG_DLM != 0) pass = 0;
  printf("INFO: [FW] Set Div=12, Read DLL=0x%02X, DLM=0x%02X\n", UART_REG_DLL, UART_REG_DLM);

  // Test Case 2: Divisor = 0x1234
  UART_REG_DLL = 0x34;
  UART_REG_DLM = 0x12;
  if (UART_REG_DLL != 0x34 || UART_REG_DLM != 0x12) pass = 0;
  printf("INFO: [FW] Set Div=0x1234, Read DLL=0x%02X, DLM=0x%02X\n", UART_REG_DLL, UART_REG_DLM);

  // Restore DLAB=0
  UART_REG_LCR &= ~0x80;

  if (pass) {
    printf("INFO: [FW] TEST PASSED: tc_uart_baudrate_switch\n");
  } else {
    printf("INFO: [FW] TEST FAILED: tc_uart_baudrate_switch\n");
  }

  end_of_test();
  return 0;
}
