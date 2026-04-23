@echo off
REM windows_docker_bridge.bat — Run PULPino DV in Docker container
REM Usage: windows_docker_bridge.bat <ctarget> <test> [args...]
REM Example: windows_docker_bridge.bat tc_uart_hello base_test
REM          windows_docker_bridge.bat tc_uart_hello base_test dump

set CTEST=%1
set TEST=%2
set ACTION=%3

if "%CTEST%"=="" set CTEST=tc_uart_hello
if "%TEST%"=="" set TEST=base_test
if "%ACTION%"=="" set ACTION=all

docker exec 828e83272623 bash -c "cd /root/work/dv-flow/pulpino_dv/sim && make CTEST=%CTEST% TEST=%TEST% %ACTION%"
