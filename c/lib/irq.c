// ==============================
// 中断分发与注册
// ==============================
#include "event.h"

#define IRQ_I2C       23
#define IRQ_UART      24
#define IRQ_GPIO      25
#define IRQ_SPIM0     26
#define IRQ_SPIM1     27
#define IRQ_TIMA_OVF  28
#define IRQ_TIMA_CMP  29
#define IRQ_TIMB_OVF  30
#define IRQ_TIMB_CMP  31

typedef void (*irq_handler_t)(void);

static irq_handler_t irq_table[32] = {0};

void irq_register(unsigned int line, irq_handler_t handler)
{
    if (line < 32)
        irq_table[line] = handler;
}

// 读 Event Unit IPR，返回最低置位的中断线号
static unsigned int get_irq_source(void)
{
    unsigned int pending = IPR;
    for (unsigned int i = 0; i < 32; i++) {
        if (pending & (1u << i))
            return i;
    }
    return 32;
}

// 中断分发：由 startup.S 的 irq_dispatch 调用
void irq_handler_table_dispatch(void)
{
    unsigned int line = get_irq_source();
    if (line < 32 && irq_table[line] != 0) {
        irq_table[line]();
        // 清除挂起位，防止中断风暴（Timer 等脉冲型中断必须清除）
        ICP = (1u << line);
    }
}
