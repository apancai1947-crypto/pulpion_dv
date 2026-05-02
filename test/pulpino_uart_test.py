import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "sim"))
from case_manager import Build, Test
from case_manager.base import InheritableMeta

# ===== Build 层 =====

class uart_base_build(Build):
    name = "uart_base"
    tag = ["uart"]
    vlog_opt = (
        "+vcs+lic+wait "
        "-full64 -sverilog -ntb_opts uvm-1.2 "
        "-timescale=1ns/1ps "
    )
    elab_opt = "-debug_access+pp"
    simulator = "vcs"


class uart_loopback_build(uart_base_build):
    name = "uart_loopback"
    vlog_opt += " +define+LOOPBACK"
    # -xprop=tmerge removed: use --xprop CLI flag when license supports it


# ===== Test 层 =====

class uart_base_test(Test):
    name = "uart_base"
    tag = ["uart"]
    build = uart_base_build
    uvm_test = "pulpino_uart_test"
    c_test = "tc_uart_hello"
    sim_opt = (
        "+UART_DATA_WIDTH=8 "
        "+UART_PARITY_TYPE=0 "
        "+UART_STOP_BIT=0 "
        "+UART_DISABLE_HW_HANDSHAKE "
        "+TIMEOUT_NS=10000000 "
    )


class tc_uart_tx_single_test(uart_base_test):
    name = "tc_uart_tx_single"
    tag += ["tx", "single"]
    c_test = "tc_uart_tx_single"
    c_defines = {"UART_DIVISOR": 31, "UART_PARITY_EN": 0}
    sim_opt += "+UART_DATA_WIDTH=8"


class tc_uart_loopback_test(uart_base_test):
    name = "tc_uart_loopback"
    tag += ["loopback"]
    build = uart_loopback_build
    c_test = "tc_uart_loopback"
    c_defines = {"UART_DIVISOR": 31, "UART_PARITY_EN": 0}


# 循环生成（需要回环，继承 tc_uart_loopback_test）
import sys as _sys

for _data in ["all0", "all1", "random"]:
    _name = f"tc_uart_data_{_data}"
    _cls = InheritableMeta(_name, (tc_uart_loopback_test,), {
        "name": _name,
        "tag": tc_uart_loopback_test.tag + ["data", _data],
        "c_test": _name,
        "c_defines": {"UART_DIVISOR": 31, "UART_PARITY_EN": 0, "DATA_PATTERN": _data},
        "sim_opt": tc_uart_loopback_test.sim_opt + f"+UART_DATA_PATTERN={_data} ",
    })
    _sys.modules[__name__].__dict__[_name] = _cls
del _sys
