@echo off
setlocal enableextensions

set "SDK_VERSION=10.0.26100.0"
set "SDK_LIB_ROOT=%ProgramFiles(x86)%\Windows Kits\10\Lib\%SDK_VERSION%"
if exist "%SDK_LIB_ROOT%\um\x64\kernel32.lib" (
    set "LIB=%SDK_LIB_ROOT%\um\x64;%SDK_LIB_ROOT%\ucrt\x64;%LIB%"
)

echo ========================================
echo Building Flash Compiler - Comprehensive Test
echo ========================================

pushd "%~dp0.."

REM Create build directory if it doesn't exist
if not exist build mkdir build

echo.
echo [1/5] Assembling memory.asm...
nasm -f win64 src\utils\memory.asm -o build\memory.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble memory.asm
    popd
    exit /b 1
)

echo [2/5] Assembling lexer.asm...
nasm -f win64 src\lexer\lexer.asm -o build\lexer.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble lexer.asm
    popd
    exit /b 1
)

echo [3/5] Assembling parser.asm...
nasm -f win64 src\parser\parser.asm -o build\parser.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble parser.asm
    popd
    exit /b 1
)

echo [4/5] Assembling test_comprehensive.asm...
nasm -f win64 tests\integration\test_comprehensive.asm -o build\test_comprehensive.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble test_comprehensive.asm
    popd
    exit /b 1
)

echo [5/5] Linking...
link /subsystem:console /entry:main /machine:x64 /out:flash_test.exe build\memory.obj build\lexer.obj build\parser.obj build\test_comprehensive.obj kernel32.lib
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
echo Run 'flash_test.exe' to run comprehensive tests
echo.
