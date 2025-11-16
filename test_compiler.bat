@echo off
setlocal enabledelayedexpansion

set "COMPILER_PATH=C:\Program Files (x86)\Flash Compiler\flash_compiler.exe"
set "EXAMPLES_DIR=C:\Program Files (x86)\Flash Compiler\examples"
set "LOG_FILE=compiler_test_results.txt"

echo Testing Flash Compiler with example files > "%LOG_FILE%"
echo =================================== >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

for /r "%EXAMPLES_DIR%" %%f in (*.fl) do (
    echo Testing: %%~nxf >> "%LOG_FILE%"
    echo ---------------------------- >> "%LOG_FILE%"
    echo File content: >> "%LOG_FILE%"
    echo ---------------------------- >> "%LOG_FILE%"
    type "%%f" >> "%LOG_FILE%"
    echo. >> "%LOG_FILE%"
    echo Compiler output: >> "%LOG_FILE%"
    echo ---------------------------- >> "%LOG_FILE%"
    "%COMPILER_PATH%" "%%f" >> "%LOG_FILE%" 2>&1
    if !errorlevel! equ 0 (
        echo [SUCCESS] Compiled successfully >> "%LOG_FILE%"
    ) else (
        echo [ERROR] Failed to compile >> "%LOG_FILE%"
    )
    echo. >> "%LOG_FILE%"
    echo. >> "%LOG_FILE%"
)

echo. >> "%LOG_FILE%"
echo Test completed. Results saved to %LOG_FILE%

notepad "%LOG_FILE%"
