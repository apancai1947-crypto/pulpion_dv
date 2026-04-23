# Exception/interrupt vector table (MUST locate at 0x00000000)
.section .vectors, "a", %progbits

.org 0x5C
    j irq_dispatch   /* I2C      */
.org 0x60
    j irq_dispatch   /* UART     */
.org 0x64
    j irq_dispatch   /* GPIO     */
.org 0x68
    j irq_dispatch   /* SPI0     */
.org 0x6C
    j irq_dispatch   /* SPI1     */
.org 0x70
    j irq_dispatch   /* TimerA OVF */
.org 0x74
    j irq_dispatch   /* TimerA CMP */
.org 0x78
    j irq_dispatch   /* TimerB OVF */
.org 0x7C
    j irq_dispatch   /* TimerB CMP */

# ============================================================
# CPU startup code — placed at 0x80 (硬件复位地址)
# ============================================================
.section .text.init
.global _start
_start:
    /* Clear all general-purpose registers */
    li x1, 0
    li x2, 0
    li x3, 0
    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 0
    li x8, 0
    li x9, 0
    li x10, 0
    li x11, 0
    li x12, 0
    li x13, 0
    li x14, 0
    li x15, 0
    li x16, 0
    li x17, 0
    li x18, 0
    li x19, 0
    li x20, 0
    li x21, 0
    li x22, 0
    li x23, 0
    li x24, 0
    li x25, 0
    li x26, 0
    li x27, 0
    li x28, 0
    li x29, 0
    li x30, 0
    li x31, 0

    /* Set stack pointer to 0x00002000 (8KB) */
    li sp, 0x00002000

    /* Enable global interrupt (MIE) */
    csrrsi x0, mstatus, 0x8

    /* Jump to C main() */
    call main

_end:
    j _end

# ============================================================
# Common interrupt dispatcher
# FULL context save: ALL working registers
# ============================================================
.global irq_dispatch
irq_dispatch:
    # 申请栈空间：保存全部通用寄存器
    addi  sp, sp, -128

    # 保存全部需要保护的寄存器
    sw    ra,   0(sp)
    sw    a0,   4(sp)
    sw    a1,   8(sp)
    sw    a2,  12(sp)
    sw    a3,  16(sp)
    sw    a4,  20(sp)
    sw    a5,  24(sp)
    sw    a6,  28(sp)
    sw    a7,  32(sp)

    sw    t0,  36(sp)
    sw    t1,  40(sp)
    sw    t2,  44(sp)
    sw    t3,  48(sp)
    sw    t4,  52(sp)
    sw    t5,  56(sp)
    sw    t6,  60(sp)

    sw    s0,  64(sp)
    sw    s1,  68(sp)
    sw    s2,  72(sp)
    sw    s3,  76(sp)
    sw    s4,  80(sp)
    sw    s5,  84(sp)
    sw    s6,  88(sp)
    sw    s7,  92(sp)
    sw    s8,  96(sp)
    sw    s9, 100(sp)
    sw   s10, 104(sp)
    sw   s11, 108(sp)

    sw    x8,  112(sp)
    sw    gp,  116(sp)
    sw    tp,  120(sp)

    # 调用C语言中断分发函数
    call  irq_handler_table_dispatch

    # 恢复全部寄存器
    lw    ra,   0(sp)
    lw    a0,   4(sp)
    lw    a1,   8(sp)
    lw    a2,  12(sp)
    lw    a3,  16(sp)
    lw    a4,  20(sp)
    lw    a5,  24(sp)
    lw    a6,  28(sp)
    lw    a7,  32(sp)

    lw    t0,  36(sp)
    lw    t1,  40(sp)
    lw    t2,  44(sp)
    lw    t3,  48(sp)
    lw    t4,  52(sp)
    lw    t5,  56(sp)
    lw    t6,  60(sp)

    lw    s0,  64(sp)
    lw    s1,  68(sp)
    lw    s2,  72(sp)
    lw    s3,  76(sp)
    lw    s4,  80(sp)
    lw    s5,  84(sp)
    lw    s6,  88(sp)
    lw    s7,  92(sp)
    lw    s8,  96(sp)
    lw    s9, 100(sp)
    lw   s10, 104(sp)
    lw   s11, 108(sp)

    lw    x8,  112(sp)
    lw    gp,  116(sp)
    lw    tp,  120(sp)

    # 恢复栈
    addi  sp, sp, 128

    # 中断返回
    mret