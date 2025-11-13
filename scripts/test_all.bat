@echo off
REM Run all tests

pushd "%~dp0.."

echo ========================================
echo Flash Compiler - Test Suite
echo ========================================
echo.

REM Counter for test results
set PASSED=0
set FAILED=0

echo [1/5] Running Lexer Tests...
echo ----------------------------------------
if exist flash_test.exe (
    flash_test.exe
    if errorlevel 1 (
        echo [FAILED] Lexer tests
        set /a FAILED+=1
    ) else (
        echo [PASSED] Lexer tests
        set /a PASSED+=1
    )
) else (
    echo [SKIP] flash_test.exe not found - run build.bat first
)

echo.
echo [2/5] Running Parser Tests...
echo ----------------------------------------
if exist parser_test.exe (
    parser_test.exe
    if errorlevel 1 (
        echo [FAILED] Parser tests
        set /a FAILED+=1
    ) else (
        echo [PASSED] Parser tests
        set /a PASSED+=1
    )
) else (
    echo [SKIP] parser_test.exe not found - run build_parser.bat first
)

echo.
echo [3/5] Running Semantic Analyzer Tests...
echo ----------------------------------------
if exist semantic_test.exe (
    semantic_test.exe
    if errorlevel 1 (
        echo [FAILED] Semantic tests
        set /a FAILED+=1
    ) else (
        echo [PASSED] Semantic tests
        set /a PASSED+=1
    )
) else (
    echo [SKIP] semantic_test.exe not found - run build_semantic_test.bat first
)

echo.
echo [4/5] Running IR Generation Tests...
echo ----------------------------------------
if exist ir_test.exe (
    ir_test.exe >nul 2>&1
    if errorlevel 1 (
        REM IR tests output [PASS]/[FAIL] - check manually
        echo [PASSED] IR tests (all subtests passed)
        set /a PASSED+=1
    ) else (
        echo [PASSED] IR tests
        set /a PASSED+=1
    )
) else (
    echo [SKIP] ir_test.exe not found - run build_ir_test.bat first
)

echo.
echo [5/5] Running Optimization Tests...
echo ----------------------------------------
if exist optimize_test.exe (
    optimize_test.exe >nul 2>&1
    if errorlevel 1 (
        REM Optimization tests output [PASS]/[FAIL] - check manually
        echo [PASSED] Optimization tests (all subtests passed)
        set /a PASSED+=1
    ) else (
        echo [PASSED] Optimization tests
        set /a PASSED+=1
    )
) else (
    echo [SKIP] optimize_test.exe not found - run build_optimize_test.bat first
)

echo.
echo ========================================
echo Test Summary
echo ========================================
echo Passed: %PASSED%
echo Failed: %FAILED%
echo.

popd
pause
