/*
 * tc_uart_data_pattern — Generic UART loopback test
 * 
 * Supports:
 * - Single byte or multiple bytes (NUM_BYTES)
 * - Fixed data or incrementing sequence (DATA_MODE)
 * - Internal or external loopback (USE_INTERNAL_LOOPBACK)
 */

#include "common_macro.h"
#include "uart.h"

extern int printf(const char *fmt, ...);
extern void end_of_test(void);

#ifndef TX_DATA
#define TX_DATA 0x00
#endif

#ifndef NUM_BYTES
#define NUM_BYTES 1
#endif

#ifndef DATA_MODE
#define DATA_MODE 0  // 0: Fixed TX_DATA, 1: Incrementing (0, 1, 2...)
#endif

#ifndef USE_INTERNAL_LOOPBACK
#define USE_INTERNAL_LOOPBACK 0
#endif

int main(void) {
  uart_init();

  if (USE_INTERNAL_LOOPBACK) {
      UART_REG_MCR |= (1 << 4);
      printf("INFO: [FW] Internal loopback enabled\n");
  }

  int pass_count = 0;
  printf("INFO: [FW] UART Test: %d bytes, Mode %d\n", (int)NUM_BYTES, (int)DATA_MODE);

  for (int i = 0; i < NUM_BYTES; i++) {
    unsigned char tx_byte = (DATA_MODE == 1) ? (unsigned char)i : (unsigned char)TX_DATA;
    unsigned char rx_byte;

    // Send
    uart_sendchar(tx_byte);

    // Receive
    rx_byte = uart_getchar();

    if (rx_byte == tx_byte) {
      pass_count++;
    } else {
      printf("INFO: [FW] FAIL at byte %d: TX 0x%02X, RX 0x%02X\n", i, tx_byte, rx_byte);
    }
  }

  if (pass_count == NUM_BYTES) {
    printf("INFO: [FW] PASS: All %d bytes matched\n", (int)NUM_BYTES);
  } else {
    printf("INFO: [FW] FAIL: %d/%d bytes matched\n", pass_count, (int)NUM_BYTES);
  }

  end_of_test();
  return 0;
}
