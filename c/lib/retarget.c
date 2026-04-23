#include <stdarg.h>
#include "common_macro.h"
#include "uart.h"

static int uart_initialized = 0;

static void uart_init(void) {
    // 8N1, DLAB=1
    *LCR_UART = 0x83;
    // Set baud rate divisor
    *DLM_UART = (UART_DIVISOR >> 8) & 0xFF;
    *DLL_UART =  UART_DIVISOR       & 0xFF;
    // 8N1, DLAB=0
    *LCR_UART = 0x03;
    // Enable and clear FIFOs
    *FCR_UART = 0x07;
    uart_initialized = 1;
}

static void uart_putc_raw(char c) {
    if (!uart_initialized) uart_init();
    // Wait for TX holding register empty
    while ((*LSR_UART & THRE) == 0);
    *THR_UART = (unsigned char)c;
}

void tube_putc(char c) {
    uart_putc_raw(c);
}

void end_of_test(void) {
    uart_putc_raw(EOT);
}

/* Software div/mod for rv32i without libgcc */
static unsigned int divu(unsigned int n, unsigned int d) {
    if (d == 0) return 0;
    unsigned int q = 0, r = 0;
    for (int i = 31; i >= 0; i--) {
        r <<= 1; r |= (n >> i) & 1;
        if (r >= d) { r -= d; q |= (1U << i); }
    }
    return q;
}

static unsigned int modu(unsigned int n, unsigned int d) {
    if (d == 0) return 0;
    unsigned int r = 0;
    for (int i = 31; i >= 0; i--) {
        r <<= 1; r |= (n >> i) & 1;
        if (r >= d) r -= d;
    }
    return r;
}

static void print_str(const char *s) {
    while (*s) uart_putc_raw(*s++);
}

static void print_hex(unsigned int n) {
    for (int i = 7; i >= 0; i--) {
        int nibble = (n >> (i * 4)) & 0xf;
        uart_putc_raw(nibble < 10 ? '0' + nibble : 'A' + nibble - 10);
    }
}

static void print_dec(int n) {
    if (n < 0) { uart_putc_raw('-'); n = -n; }
    if (n == 0) { uart_putc_raw('0'); return; }
    char buf[12];
    int i = 0;
    unsigned int un = (unsigned int)n;
    while (un > 0) {
        buf[i++] = modu(un, 10) + '0';
        un = divu(un, 10);
    }
    while (i > 0) uart_putc_raw(buf[--i]);
}

int printf(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    for (const char *p = fmt; *p; p++) {
        if (*p == '%') {
            p++;
            switch (*p) {
                case 's': print_str(va_arg(ap, char *)); break;
                case 'd': print_dec(va_arg(ap, int)); break;
                case 'x': print_hex(va_arg(ap, unsigned int)); break;
                default:  uart_putc_raw(*p); break;
            }
        } else {
            uart_putc_raw(*p);
        }
    }
    va_end(ap);
    return 0;
}
