@echo off
REM windows_docker_bridge_ci.bat -- CI Docker bridge (run_case.py)
REM Usage: windows_docker_bridge_ci.bat [test_spec] [extra args...]
REM Examples:
REM   windows_docker_bridge_ci.bat tc_uart_hello_test
REM   windows_docker_bridge_ci.bat tc_uart_tx_single_test +TIMEOUT_NS=20000000
REM   windows_docker_bridge_ci.bat --tag uart
REM   windows_docker_bridge_ci.bat --list
REM   windows_docker_bridge_ci.bat tc_uart_hello_test -d

set SPEC=%1
if "%SPEC%"=="" set SPEC=tc_uart_hello_test

REM Collect remaining args after the first
shift
set EXTRA_ARGS=
:loop
if "%~1"=="" goto :run
set EXTRA_ARGS=%EXTRA_ARGS% %1
shift
goto :loop

:run
docker exec 828e83272623 bash -c "cd /root/work/dv-flow/pulpino_dv && python3 sim/run_case.py %SPEC% %EXTRA_ARGS%"
