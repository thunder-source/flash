@echo off
REM ============================================
REM IR Compilation Verification (No Linking)
REM ============================================
REM This script just verifies that all IR
REM modules compile correctly to object files
REM without trying to link them.
REM ============================================

echo ========================================
echo IR Compilation Verification
echo ========================================
echo.

pushd "%~dp0.."

REM Create build directory if it doesn't exist
if not exist build mkdir build

echo [1/4] Assembling memory.asm...
nasm -f win64 src\utils\memory.asm -o build\memory.obj
if errorlevel 1 (
    echo [FAIL] memory.asm failed to assemble
    popd
    exit /b 1
)
echo [PASS] memory.asm

echo [2/4] Assembling ir.asm...
nasm -f win64 src\ir\ir.asm -o build\ir.obj
if errorlevel 1 (
    echo [FAIL] ir.asm failed to assemble
    popd
    exit /b 1
)
echo [PASS] ir.asm

echo [3/4] Assembling generate.asm...
nasm -f win64 src\ir\generate.asm -o build\generate.obj
if errorlevel 1 (
    echo [FAIL] generate.asm failed to assemble
    popd
    exit /b 1
)
echo [PASS] generate.asm

echo [4/4] Assembling test_ir.asm...
nasm -f win64 tests\integration\test_ir.asm -o build\test_ir.obj
if errorlevel 1 (
    echo [FAIL] test_ir.asm failed to assemble
    popd
    exit /b 1
)
echo [PASS] test_ir.asm

popd

echo.
echo ========================================
echo Verification Complete: SUCCESS
echo ========================================
echo.
echo All IR modules compiled successfully!
echo.
echo Object files created:
dir /b build\*.obj | find "memory" >nul && echo   [OK] build\memory.obj
dir /b build\*.obj | find "ir" >nul && echo   [OK] build\ir.obj
dir /b build\*.obj | find "generate" >nul && echo   [OK] build\generate.obj
dir /b build\*.obj | find "test_ir" >nul && echo   [OK] build\test_ir.obj
echo.
echo IR Phase 6 implementation verified!
echo No syntax errors or compilation issues.
echo.
echo Note: Use build_ir_test.bat to create executable
echo (requires linker in PATH)
echo.
pause
