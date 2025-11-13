@echo off
set "LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64"

echo Building simple codegen test...
nasm -f win64 test_simple_codegen.asm -o build\test_simple.obj
if errorlevel 1 goto :error

nasm -f win64 src\utils\memory.asm -o build\memory.obj
if errorlevel 1 goto :error

nasm -f win64 src\ir\ir.asm -o build\ir.obj
if errorlevel 1 goto :error

nasm -f win64 src\codegen\codegen.asm -o build\codegen.obj
if errorlevel 1 goto :error

nasm -f win64 src\codegen\regalloc.asm -o build\regalloc.obj
if errorlevel 1 goto :error

link /subsystem:console /entry:main /LARGEADDRESSAWARE:NO /out:simple_test.exe build\test_simple.obj build\memory.obj build\ir.obj build\codegen.obj build\regalloc.obj kernel32.lib
if errorlevel 1 goto :error

echo Build successful!
echo.
echo Running test...
echo.
simple_test.exe
set EXITCODE=%errorlevel%
echo.
echo Exit code: %EXITCODE%
goto :end

:error
echo Build failed!
exit /b 1

:end
