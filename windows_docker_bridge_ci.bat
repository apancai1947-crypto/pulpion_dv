@echo off
REM windows_docker_bridge_ci.bat — CI single-arg Docker bridge
REM Usage: windows_docker_bridge_ci.bat <ctest>
REM Runs: CTEST=<ctest> TEST=base_test all

set CTEST=%1
if "%CTEST%"=="" set CTEST=tc_uart_hello

docker exec 828e83272623 bash -c "cd /root/work/dv-flow/pulpino_dv/sim && make CTEST=%CTEST% TEST=base_test all"
