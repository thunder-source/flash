@echo off
echo ========================================
echo Building Flash Compiler - Comprehensive Test
echo ========================================

REM Create build directory if it doesn't exist
if not exist build mkdir build

echo.
echo [1/5] Assembling memory.asm...
nasm -f win64 src\utils\memory.asm -o build\memory.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble memory.asm
    exit /b 1
)

echo [2/5] Assembling lexer.asm...
nasm -f win64 src\lexer\lexer.asm -o build\lexer.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble lexer.asm
    exit /b 1
)

echo [3/5] Assembling parser.asm...
nasm -f win64 src\parser\parser.asm -o build\parser.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble parser.asm
    exit /b 1
)

echo [4/5] Assembling test_comprehensive.asm...
nasm -f win64 tests\integration\test_comprehensive.asm -o build\test_comprehensive.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble test_comprehensive.asm
    exit /b 1
)

echo [5/5] Linking...
link /subsystem:console /entry:main /out:flash_test.exe build\memory.obj build\lexer.obj build\parser.obj build\test_comprehensive.obj kernel32.lib
if errorlevel 1 (
    echo ERROR: Failed to link
    exit /b 1
)

echo.
echo ========================================
echo Build successful!
echo ========================================
echo.
echo Run 'flash_test.exe' to run comprehensive tests
echo.
