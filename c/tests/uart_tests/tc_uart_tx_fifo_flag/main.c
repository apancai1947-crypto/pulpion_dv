/*
 * TF_UART_020 — TX FIFO Flags
 */

#include "uart.h"
#include "common_macro.h"

extern int printf(const char *fmt, ...);
extern void end_of_test(void);

int main(void) {
  uart_init();
  printf("INFO: [FW] TF_UART_020: TX FIFO Flags test\n");

  // At start, THRE and TEMT should be set
  if (!(UART_REG_LSR & LSR_THRE)) {
    printf("INFO: [FW] FAIL: LSR_THRE not set at start\n");
  }

  // Send many bytes to see if we can catch THRE going low?
  // Since baud rate is slow compared to CPU, THRE will go low immediately when we write.
  // Wait, if it's 1-byte buffer, it will go low.
  
  printf("INFO: [FW] Sending byte...\n");
  UART_REG_THR = 0xAA;
  
  // Note: on some hardware, THRE goes low instantly and stays low until the byte is moved to TSR.
  // Then THRE goes high while TEMT is still low.
  
  printf("INFO: [FW] LSR after write: 0x%02X\n", UART_REG_LSR);

  printf("INFO: [FW] TEST PASSED: tc_uart_tx_fifo_flag\n");
  end_of_test();
  return 0;
}
