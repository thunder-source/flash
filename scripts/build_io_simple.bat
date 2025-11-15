@echo off
set "LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64"

echo Building simple I/O test...

nasm -f win64 test_io_simple.asm -o build\test_io_simple.obj
if errorlevel 1 exit /b 1

link /subsystem:console /entry:main /out:io_simple.exe build\test_io_simple.obj kernel32.lib >nul 2>&1
if errorlevel 1 exit /b 1

echo Running test...
io_simple.exe
echo Exit code: %errorlevel%
