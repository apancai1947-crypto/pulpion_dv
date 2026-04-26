#include <stdarg.h>
#include "common_macro.h"
#include "uart.h"

static int uart_initialized = 0;

/* ---- Register assembly macros ---- */

/* LCR value without DLAB bit (DLAB managed by uart_init internally) */
#define _UART_LCR_VAL() ( \
    (((UART_DATA_BITS - 5) & 0x3))                          | \
    ((UART_STOP_BITS == 2 ? 1 : 0)          << 2)           | \
    (UART_PARITY_EN                         << 3)           | \
    (UART_PARITY_EVEN                       << 4)           | \
    (UART_PARITY_STICK                      << 5)           | \
    (UART_BREAK_EN                          << 6)             \
)

/* FCR trigger level encoding: 1→00, 4→01, 8→10, 14→11 */
#define _UART_FIFO_TRIGGER_BITS() \
    (UART_FIFO_TRIGGER >= 14 ? 3 : UART_FIFO_TRIGGER >= 8 ? 2 : \
     UART_FIFO_TRIGGER >= 4  ? 1 : 0)

#define _UART_FCR_VAL() ( \
    (UART_FIFO_EN                   << 0) | \
    (UART_FIFO_RX_RESET             << 1) | \
    (UART_FIFO_TX_RESET             << 2) | \
    (_UART_FIFO_TRIGGER_BITS()      << 4)   \
)

/* MCR value */
#define _UART_MCR_VAL() ( \
    (UART_MCR_DTR       << 0) | \
    (UART_MCR_RTS       << 1) | \
    (UART_MCR_OUT1      << 2) | \
    (UART_MCR_OUT2      << 3) | \
    (UART_MCR_LOOPBACK  << 4)   \
)

static void uart_init(void) {
    /* DLAB=1: set baud rate divisor */
    *LCR_UART = _UART_LCR_VAL() | (1 << 7);
    *DLM_UART = (UART_DIVISOR >> 8) & 0xFF;
    *DLL_UART =  UART_DIVISOR       & 0xFF;
    /* DLAB=0: frame format */
    *LCR_UART = _UART_LCR_VAL();
    /* FIFO control */
    *FCR_UART = _UART_FCR_VAL();
    /* Modem control */
    *MCR_UART = _UART_MCR_VAL();

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
