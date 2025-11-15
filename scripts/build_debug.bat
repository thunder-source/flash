@echo off
set "LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64"

nasm -f win64 test_debug_codegen.asm -o build\test_debug.obj
if errorlevel 1 exit /b 1

link /subsystem:console /entry:main /LARGEADDRESSAWARE:NO /out:debug_test.exe build\test_debug.obj build\memory.obj build\ir.obj build\codegen.obj build\regalloc.obj kernel32.lib >nul 2>&1
if errorlevel 1 exit /b 1

echo Running debug test...
echo.
debug_test.exe
