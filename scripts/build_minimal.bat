@echo off
set "LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64"
nasm -f win64 test_minimal.asm -o test_minimal.obj
link /subsystem:console /entry:main /LARGEADDRESSAWARE:NO /out:test_minimal.exe test_minimal.obj kernel32.lib
