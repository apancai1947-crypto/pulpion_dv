@echo off
REM ============================================================================
REM [ANTIGRAVITY_CONTEXT]
REM Container_ID  : 828e83272623
REM Remote_Root   : /root/work/dv-flow/pulpino_dv
REM Verified_Date : 2026-05-01
REM Status        : SUCCESS
REM ----------------------------------------------------------------------------
REM Usage:
REM   .\windows_docker_bridge.bat <ctest> <test> [action]
REM   .\windows_docker_bridge.bat python <test_spec> [args...]
REM
REM Examples:
REM   .\windows_docker_bridge.bat tc_uart_hello pulpino_uart_test all
REM   .\windows_docker_bridge.bat python tc_uart_tx_single --dry-run
REM ============================================================================

set CONTAINER_ID=828e83272623
set REMOTE_SIM_DIR=/root/work/dv-flow/pulpino_dv/sim

if "%1"=="python" (
    setlocal enabledelayedexpansion
    set "RAW_ARGS=%*"
    set "PY_ARGS=!RAW_ARGS:*python =!"
    echo [DOCKER] Running Python Case Manager...
    docker exec %CONTAINER_ID% bash -c "cd %REMOTE_SIM_DIR% && python3 run_case.py !PY_ARGS!"
    endlocal
    goto :eof
)


set CTEST=%1
set TEST=%2
set ACTION=%3

if "%CTEST%"=="" set CTEST=tc_uart_hello
if "%TEST%"=="" set TEST=pulpino_uart_test
if "%ACTION%"=="" set ACTION=all

echo [DOCKER] Running Make Flow (CTEST=%CTEST% TEST=%TEST% ACTION=%ACTION%)...
docker exec %CONTAINER_ID% bash -c "cd %REMOTE_SIM_DIR% && make CTEST=%CTEST% TEST=%TEST% %ACTION%"

:eof
