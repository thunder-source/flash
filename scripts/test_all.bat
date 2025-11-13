@echo off
REM Run all tests

echo ========================================
echo Flash Compiler - Test Suite
echo ========================================
echo.

REM Counter for test results
set PASSED=0
set FAILED=0

echo [1/3] Running Lexer Tests...
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
echo [2/3] Running Parser Tests...
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
echo [3/3] Running Semantic Analyzer Tests...
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
echo ========================================
echo Test Summary
echo ========================================
echo Passed: %PASSED%
echo Failed: %FAILED%
echo.
pause
