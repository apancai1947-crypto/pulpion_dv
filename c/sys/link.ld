ENTRY(_start)
MEMORY {
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 32K
}

SECTIONS {
    /* 中断向量表 → 强制放在 0x0 开头 */
    .vectors 0x00000000 : {
        KEEP(*(.vectors))
    } > RAM

    /* 代码 → 固定从 0x80（硬件复位地址）开始 */
    .text 0x00000080 : {
        KEEP(*(.text.init))
        *(.text*)
    } > RAM

    .rodata : { *(.rodata*) } > RAM
    .data   : { *(.data*)   } > RAM
    .bss    : { *(.bss*)    } > RAM

    /DISCARD/ : {
        *(.note.gnu.build-id)
    }
}