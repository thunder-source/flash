@echo off
setlocal enabledelayedexpansion
rem ============================================================================
rem flash_compile.bat
rem Simple helper to assemble runtime/stdlib and link a compiled user object
rem Usage: flash_compile.bat user.obj [output.exe]
rem ============================================================================

if "%1"=="" (
  echo Usage: %~nx0 user.obj [output.exe]
  echo Example: %~nx0 build\main.obj hello.exe
  goto :eof
)

set USEROBJ=%1
set OUTPUT=%2
if "%OUTPUT%"=="" set OUTPUT=flash_program.exe

echo Assembling runtime and stdlib...
nasm -f win64 ..\lib\io.asm -o ..\lib\io.obj
nasm -f win64 ..\lib\memory.asm -o ..\lib\memory.obj
nasm -f win64 ..\lib\string.asm -o ..\lib\string.obj
nasm -f win64 ..\lib\runtime.asm -o ..\lib\runtime.obj

echo Locating `kernel32.lib` and preparing link arguments...
set KERNEL32_PATH=
for /f "usebackq delims=" %%i in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0find_kernel32.ps1"`) do (
  set KERNEL32_PATH=%%i
  goto :found_kernel32
)
:found_kernel32
:found_kernel32
if defined KERNEL32_PATH (
  rem Use the full path to kernel32.lib quoted to avoid issues with spaces
  set "KERNEL32_LIB_ARG=!KERNEL32_PATH!"
  echo Found kernel32 at: !KERNEL32_LIB_ARG!
  rem If this is an ARM64 import lib, ignore it and let the linker use environment LIB paths
  echo !KERNEL32_LIB_ARG! | findstr /I "arm64" >nul
  if not errorlevel 1 (
    echo Detected ARM64 import lib; ignoring and relying on LIB environment paths instead.
    set "KERNEL32_LIB_ARG="
  )
) else (
  set "KERNEL32_LIB_ARG="
  echo Warning: kernel32.lib not found automatically; linking may fail unless run from Developer Command Prompt.
)

echo Linking %OUTPUT% (entry=_start)...
if defined KERNEL32_LIB_ARG (
  link /SUBSYSTEM:CONSOLE /MACHINE:X64 /ENTRY:_start %USEROBJ% ..\lib\io.obj ..\lib\memory.obj ..\lib\string.obj ..\lib\runtime.obj "!KERNEL32_LIB_ARG!" /OUT:%OUTPUT%
) else (
  link /SUBSYSTEM:CONSOLE /MACHINE:X64 /ENTRY:_start %USEROBJ% ..\lib\io.obj ..\lib\memory.obj ..\lib\string.obj ..\lib\runtime.obj kernel32.lib /OUT:%OUTPUT%
)

if errorlevel 1 (
  echo Link failed.
  exit /b 1
)

echo Linked %OUTPUT%
