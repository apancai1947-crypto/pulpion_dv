#include "common_macro.h"

/**
 * @brief 将数据发送到参考 FIFO，用于仿真环境的自检测
 * @param ptr 数据指针 (int 数组)
 * @param len 数据长度 (字数)
 */
void ref_data_send(const int *ptr, int len) {
    for (int i = 0; i < len; i++) {
        // RAW_DATA_REG 定义在 common_macro.h 中，映射到特定的仿真监控地址
        RAW_DATA_REG = ptr[i];
    }
}
