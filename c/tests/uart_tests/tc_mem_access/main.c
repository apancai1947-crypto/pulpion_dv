#include "uart.h"
extern int printf(const char *fmt, ...);
extern void end_of_test(void);

int main() {
  uart_init();
    volatile unsigned int *data = (volatile unsigned int *)0x00100000;

    printf("UVM_INFO: [FW] Running tc_mem_access...\n");

    /* Write pattern to data RAM */
    data[0] = 0xDEADBEEF;
    data[1] = 0x12345678;
    data[2] = 0xCAFEBABE;
    data[3] = 0x00000000;
    data[4] = 0xFFFFFFFF;

    /* Read back and verify */
    int pass = 1;
    if (data[0] != 0xDEADBEEF) { printf("UVM_ERROR: [FW] data[0] mismatch: %x\n", data[0]); pass = 0; }
    if (data[1] != 0x12345678) { printf("UVM_ERROR: [FW] data[1] mismatch: %x\n", data[1]); pass = 0; }
    if (data[2] != 0xCAFEBABE) { printf("UVM_ERROR: [FW] data[2] mismatch: %x\n", data[2]); pass = 0; }
    if (data[3] != 0x00000000) { printf("UVM_ERROR: [FW] data[3] mismatch: %x\n", data[3]); pass = 0; }
    if (data[4] != 0xFFFFFFFF) { printf("UVM_ERROR: [FW] data[4] mismatch: %x\n", data[4]); pass = 0; }

    if (pass)
        printf("UVM_INFO: [FW] TEST PASSED: tc_mem_access\n");
    else
        printf("UVM_ERROR: [FW] TEST FAILED: tc_mem_access\n");

    end_of_test();
    while(1);
    return 0;
}
