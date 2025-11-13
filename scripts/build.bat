@echo off
echo ========================================
echo Building Flash Compiler
echo ========================================

pushd "%~dp0.."

REM Create build directory if it doesn't exist
if not exist build mkdir build

echo.
echo [1/6] Assembling memory.asm...
nasm -f win64 src\utils\memory.asm -o build\memory.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble memory.asm
    popd
    exit /b 1
)

echo [2/6] Assembling ast.asm...
nasm -f win64 src\ast.asm -o build\ast.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble ast.asm
    popd
    exit /b 1
)

echo [3/6] Assembling lexer.asm...
nasm -f win64 src\lexer\lexer.asm -o build\lexer.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble lexer.asm
    popd
    exit /b 1
)

echo [4/6] Assembling parser.asm...
nasm -f win64 src\parser\parser.asm -o build\parser.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble parser.asm
    popd
    exit /b 1
)

echo [5/6] Assembling test_lexer.asm...
nasm -f win64 tests\lexer\test_lexer.asm -o build\test_lexer.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble test_lexer.asm
    popd
    exit /b 1
)

echo [6/6] Linking...
link /subsystem:console /entry:main /out:flash_test.exe build\memory.obj build\ast.obj build\lexer.obj build\parser.obj build\test_lexer.obj kernel32.lib
if errorlevel 1 (
    echo ERROR: Failed to link
    popd
    exit /b 1
)

popd

echo.
echo ========================================
echo Build successful!
echo ========================================
echo.
echo Run 'flash_test.exe' to test the compiler
echo.
