#include <stdarg.h>
#include "common_macro.h"

/* ---- Memory-Mapped Stdout ---- */

static int stdout_index = 0;
static unsigned int stdout_word = 0;

static void stdout_putc(char c) {
    // Pack character into current word (little-endian)
    stdout_word |= ((unsigned int)(unsigned char)c) << (stdout_index * 8);
    stdout_index++;

    // When 4 characters are packed, write the word
    if (stdout_index >= 4) {
        STDOUT_REG = stdout_word;
        stdout_index = 0;
        stdout_word = 0;
    }
}

static void stdout_flush(void) {
    // Write remaining characters (if any) padded with nulls
    if (stdout_index > 0) {
        STDOUT_REG = stdout_word;
        stdout_index = 0;
        stdout_word = 0;
    }
    // Write null word to indicate end of string
    STDOUT_REG = 0;
}

void tube_putc(char c) {
    stdout_putc(c);
}

void end_of_test(void) {
    stdout_putc(EOT);
    stdout_flush();
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
    while (*s) stdout_putc(*s++);
}

static void print_hex(unsigned int n) {
    for (int i = 7; i >= 0; i--) {
        int nibble = (n >> (i * 4)) & 0xf;
        stdout_putc(nibble < 10 ? '0' + nibble : 'A' + nibble - 10);
    }
}

static void print_dec(int n) {
    if (n < 0) { stdout_putc('-'); n = -n; }
    if (n == 0) { stdout_putc('0'); return; }
    char buf[12];
    int i = 0;
    unsigned int un = (unsigned int)n;
    while (un > 0) {
        buf[i++] = modu(un, 10) + '0';
        un = divu(un, 10);
    }
    while (i > 0) stdout_putc(buf[--i]);
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
                default:  stdout_putc(*p); break;
            }
        } else {
            stdout_putc(*p);
        }
    }
    va_end(ap);
    stdout_flush();
    return 0;
}
