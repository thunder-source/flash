@echo off
REM Flash Compiler - Simple Build Script for Original Stub
REM Uses working stub without external dependencies to validate build system

echo ============================================
echo Flash Compiler - Simple Build Test
echo ============================================

pushd "%~dp0"

REM Create build directory
if not exist build mkdir build

echo.
echo Building simple Flash compiler stub...

REM Clean previous builds
if exist build\flash.exe del build\flash.exe
if exist build\flash_simple.obj del build\flash_simple.obj

echo [1/2] Creating simple stub assembly...
echo ; Simple Flash Compiler Stub > build\flash_simple.asm
echo ; Tests build system without dependencies >> build\flash_simple.asm
echo. >> build\flash_simple.asm
echo bits 64 >> build\flash_simple.asm
echo default rel >> build\flash_simple.asm
echo. >> build\flash_simple.asm
echo extern ExitProcess >> build\flash_simple.asm
echo extern GetStdHandle >> build\flash_simple.asm
echo extern WriteConsoleA >> build\flash_simple.asm
echo. >> build\flash_simple.asm
echo section .data >> build\flash_simple.asm
echo     msg db 'Flash Compiler v0.2.0 - Build System Working!', 0dh, 0ah, 0 >> build\flash_simple.asm
echo     msg_len equ $ - msg >> build\flash_simple.asm
echo. >> build\flash_simple.asm
echo section .bss >> build\flash_simple.asm
echo     bytes_written resq 1 >> build\flash_simple.asm
echo. >> build\flash_simple.asm
echo section .text >> build\flash_simple.asm
echo global main >> build\flash_simple.asm
echo. >> build\flash_simple.asm
echo main: >> build\flash_simple.asm
echo     push rbp >> build\flash_simple.asm
echo     mov rbp, rsp >> build\flash_simple.asm
echo     sub rsp, 32 >> build\flash_simple.asm
echo. >> build\flash_simple.asm
echo     ; Get stdout handle >> build\flash_simple.asm
echo     mov rcx, -11 >> build\flash_simple.asm
echo     call GetStdHandle >> build\flash_simple.asm
echo. >> build\flash_simple.asm
echo     ; Print message >> build\flash_simple.asm
echo     mov rcx, rax >> build\flash_simple.asm
echo     lea rdx, [msg] >> build\flash_simple.asm
echo     mov r8, msg_len >> build\flash_simple.asm
echo     lea r9, [bytes_written] >> build\flash_simple.asm
echo     push 0 >> build\flash_simple.asm
echo     sub rsp, 32 >> build\flash_simple.asm
echo     call WriteConsoleA >> build\flash_simple.asm
echo     add rsp, 40 >> build\flash_simple.asm
echo. >> build\flash_simple.asm
echo     ; Exit >> build\flash_simple.asm
echo     mov rsp, rbp >> build\flash_simple.asm
echo     pop rbp >> build\flash_simple.asm
echo     xor rcx, rcx >> build\flash_simple.asm
echo     call ExitProcess >> build\flash_simple.asm

echo [2/2] Assembling...
nasm -f win64 build\flash_simple.asm -o build\flash_simple.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble
    goto error_exit
)

echo [3/3] Linking with Visual Studio linker...

REM Set up paths
set VS_LINKER="C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64\link.exe"
set SDK_LIB="C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64"
set SDK_UCRT="C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64"

%VS_LINKER% /subsystem:console /entry:main /out:build\flash.exe build\flash_simple.obj /LIBPATH:%SDK_LIB% /LIBPATH:%SDK_UCRT% kernel32.lib

if errorlevel 1 (
    echo ERROR: Failed to link
    goto error_exit
)

if not exist build\flash.exe (
    echo ERROR: flash.exe was not created
    goto error_exit
)

popd

echo.
echo ============================================
echo SUCCESS! Build System Working!
echo ============================================
echo.
echo Flash Compiler: build\flash.exe
echo Build System: Visual Studio + Windows SDK
echo Status: Ready for Phase 11 integration
echo.
echo Test the compiler:
echo   build\flash.exe
echo.
echo Run benchmarks:
echo   cd benchmarks ^&^& .\simple_bench.ps1
echo.
echo ============================================
goto end

:error_exit
popd
echo.
echo ============================================
echo Build Failed!
echo ============================================
exit /b 1

:end
exit /b 0
