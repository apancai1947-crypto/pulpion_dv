#include "uart.h"

int main() {
    uart_init();
    printf("INFO:UVM_INFO: [FW] PULPino UVM firmware started.\n");
    printf("INFO:UVM_INFO: [FW] Running tc_uart_hello...\n");
    printf("INFO:UVM_INFO: [FW] Hello from PULPino!\n");
    printf("INFO:UVM_INFO: [FW] TEST PASSED: tc_uart_hello\n");
    printf("INFO:UVM_INFO: [FW] Sending EOT.\n");
    end_of_test();
    while(1);
    return 0;
}
