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


class tc_uart_rx_single_test(uart_base_test):
    name = "tc_uart_rx_single"
    tag += ["rx", "single"]
    c_test = "tc_uart_data_pattern"
    c_defines = {"UART_DIVISOR": 31, "NUM_BYTES": 5, "DATA_MODE": 1}
    sim_opt += "+UART_DATA_WIDTH=8"


class tc_uart_tx_single_test(uart_base_test):
    name = "tc_uart_tx_single"
    tag += ["tx", "single"]
    c_test = "tc_uart_data_pattern"
    c_defines = {"UART_DIVISOR": 31, "TX_DATA": 0xA5}
    sim_opt += "+UART_DATA_WIDTH=8"


class tc_uart_reset_default_test(uart_base_test):
    name = "tc_uart_reset_default"
    tag += ["reset", "config"]
    c_test = "tc_uart_reset_default"


class tc_uart_tx_fifo_flag_test(uart_base_test):
    name = "tc_uart_tx_fifo_flag"
    tag += ["fifo", "tx"]
    c_test = "tc_uart_tx_fifo_flag"


class tc_uart_baudrate_switch_test(uart_base_test):
    name = "tc_uart_baudrate_switch"
    tag += ["baudrate", "config"]
    c_test = "tc_uart_baudrate_switch"


class tc_uart_external_loopback_test(uart_base_test):
    name = "tc_uart_external_loopback"
    tag = ["loopback", "external"]
    build = uart_loopback_build
    c_test = "tc_uart_data_pattern"
    c_defines = {"UART_DIVISOR": 31}


class tc_uart_loopback_test(uart_base_test):
    name = "tc_uart_loopback"
    tag += ["loopback", "internal"]
    build = uart_base_build
    c_test = "tc_uart_data_pattern"
    c_defines = {"UART_DIVISOR": 31, "TX_DATA": 0xAB, "USE_INTERNAL_LOOPBACK": 1}


class tc_uart_tx_continuous_test(uart_base_test):
    name = "tc_uart_tx_continuous"
    tag += ["tx", "continuous"]
    c_test = "tc_uart_data_pattern"
    c_defines = {"UART_DIVISOR": 31, "NUM_BYTES": 32, "DATA_MODE": 1}


# 循环生成（需要回环，继承 tc_uart_external_loopback_test）
import random as _random

for _data in ["all0", "all1", "random"]:
    _name = f"tc_uart_data_{_data}"
    _val = 0x00 if _data == "all0" else 0xFF if _data == "all1" else _random.randint(1, 254)
    _cls = InheritableMeta(_name, (tc_uart_external_loopback_test,), {
        "name": _name,
        "tag": tc_uart_external_loopback_test.tag + ["data", _data],
        "c_defines": {"UART_DIVISOR": 31, "TX_DATA": _val},
        "sim_opt": tc_uart_external_loopback_test.sim_opt + f"+UART_DATA_PATTERN={_data} ",
    })
    sys.modules[__name__].__dict__[_name] = _cls
del _random
