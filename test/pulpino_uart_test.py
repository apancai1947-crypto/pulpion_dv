import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "sim"))
from case_manager import Build, Test
from case_manager.base import InheritableMeta


# ===== Build 层 =====

class uart_base_build(Build):
    name = "uart_base"
    tag = ["uart"]
    vlog_opt = (
        "+vcs+lic+wait "
        "-timescale=1ns/1ps "
    )
    elab_opt = "-debug_access+pp"
    simulator = "vcs"


class uart_loopback_build(uart_base_build):
    name = "uart_loopback"
    vlog_opt += " +define+LOOPBACK"
    elab_opt += " -xprop=tmerge"


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
    c_defines = {"BAUD_DIVISOR": 1, "PARITY": 0}
    sim_opt += "+UART_DATA_WIDTH=8"


class tc_uart_loopback_test(uart_base_test):
    name = "tc_uart_loopback"
    tag += ["loopback"]
    build = uart_loopback_build
    c_test = "tc_uart_loopback"
    c_defines = {"BAUD_DIVISOR": 1, "PARITY": 0}


# 循环生成
import sys as _sys
for _data in ["all0", "all1", "random"]:
    _name = f"tc_uart_data_{_data}"
    _cls = InheritableMeta(_name, (uart_base_test,), {
        "name": _name,
        "tag": uart_base_test.tag + ["data", _data],
        "c_test": _name,
        "c_defines": {"BAUD_DIVISOR": 1, "PARITY": 0, "DATA_PATTERN": _data},
        "sim_opt": uart_base_test.sim_opt + f"+UART_DATA_PATTERN={_data} ",
    })
    _sys.modules[__name__].__dict__[_name] = _cls
del _sys
