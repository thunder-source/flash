@echo off
set "LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64"

echo Building runtime library test...
echo.

REM Assemble runtime library
nasm -f win64 lib\runtime.asm -o build\runtime.obj
if errorlevel 1 (
    echo FAILED: runtime.asm
    exit /b 1
)

REM Assemble I/O library
nasm -f win64 lib\io.asm -o build\io.obj
if errorlevel 1 (
    echo FAILED: io.asm
    exit /b 1
)

REM Assemble test program
nasm -f win64 test_runtime.asm -o build\test_runtime.obj
if errorlevel 1 (
    echo FAILED: test_runtime.asm
    exit /b 1
)

REM Link everything
link /subsystem:console /entry:_start /out:runtime_test.exe build\runtime.obj build\io.obj build\test_runtime.obj kernel32.lib
if errorlevel 1 (
    echo FAILED: Linking
    exit /b 1
)

echo Build successful!
echo.
echo Running test...
echo.
runtime_test.exe
set EXITCODE=%errorlevel%
echo.
echo Program exited with code: %EXITCODE%
