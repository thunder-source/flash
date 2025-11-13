@echo off
echo ========================================
echo Building Code Generation Test
echo ========================================

set "LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64"

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

echo [2/6] Assembling ir.asm...
nasm -f win64 src\ir\ir.asm -o build\ir.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble ir.asm
    popd
    exit /b 1
)

echo [3/6] Assembling codegen.asm...
nasm -f win64 src\codegen\codegen.asm -o build\codegen.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble codegen.asm
    popd
    exit /b 1
)

echo [4/6] Assembling regalloc.asm...
nasm -f win64 src\codegen\regalloc.asm -o build\regalloc.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble regalloc.asm
    popd
    exit /b 1
)

echo [5/6] Assembling test_codegen.asm...
nasm -f win64 tests\integration\test_codegen.asm -o build\test_codegen.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble test_codegen.asm
    popd
    exit /b 1
)

echo [6/6] Linking...
where link.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo Using link.exe from PATH
    link /subsystem:console /entry:main /LARGEADDRESSAWARE:NO /out:codegen_test.exe build\memory.obj build\ir.obj build\codegen.obj build\regalloc.obj build\test_codegen.obj kernel32.lib
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
    echo Run 'codegen_test.exe' to test code generation
    echo.
    exit /b 0
)

echo.
echo ========================================
echo Build successful!
echo ========================================
echo.
echo Run 'codegen_test.exe' to test code generation
echo.

popd
exit /b 0
