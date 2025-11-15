@echo off
set "LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64"

echo Building full code generation test...
echo.

nasm -f win64 test_full_codegen.asm -o build\test_full.obj
if errorlevel 1 (
    echo FAILED: test_full_codegen.asm
    exit /b 1
)

link /subsystem:console /entry:main /LARGEADDRESSAWARE:NO /out:full_test.exe build\test_full.obj build\memory.obj build\ir.obj build\codegen.obj build\regalloc.obj kernel32.lib >nul 2>&1
if errorlevel 1 (
    echo FAILED: Linking
    exit /b 1
)

echo Build successful!
echo.
echo Running test...
echo.
full_test.exe
