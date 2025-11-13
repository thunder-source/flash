@echo off
REM Master build script for Flash Compiler
REM Builds all test executables

set "LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64"

echo ========================================
echo Flash Compiler - Build All
echo ========================================
echo.

echo [1/4] Building Lexer Test...
call "%~dp0build.bat"
if errorlevel 1 (
    echo ERROR: Lexer test build failed
    pause
    exit /b 1
)

echo.
echo [2/4] Building Parser Test...
call "%~dp0build_parser.bat"
if errorlevel 1 (
    echo ERROR: Parser test build failed
    pause
    exit /b 1
)

echo.
echo [3/4] Building Semantic Analyzer Test...
call "%~dp0build_semantic_test.bat"
if errorlevel 1 (
    echo ERROR: Semantic test build failed
    pause
    exit /b 1
)

echo.
echo [4/4] Building Comprehensive Test...
call "%~dp0build_test.bat"
if errorlevel 1 (
    echo ERROR: Comprehensive test build failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo All builds completed successfully!
echo ========================================
echo.
echo Available executables:
echo   - flash_test.exe       (Lexer + comprehensive tests)
echo   - parser_test.exe      (Parser tests)
echo   - semantic_test.exe    (Semantic analyzer tests)
echo.
pause
