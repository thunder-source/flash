@echo off
setlocal
rem ============================================================================
rem flash_compile_mingw.bat
rem Assemble stdlib and link using MinGW-w64 `gcc` if available
rem Usage: flash_compile_mingw.bat user.obj [output.exe]
rem ============================================================================

if "%1"=="" (
  echo Usage: %~nx0 user.obj [output.exe]
  goto :eof
)

set USEROBJ=%1
set OUTPUT=%2
if "%OUTPUT%"=="" set OUTPUT=flash_program.exe

rem Check for gcc
gcc --version >nul 2>&1
if errorlevel 1 (
  echo GCC not found on PATH.
  echo Install MSYS2 + mingw-w64 toolchain and add the MinGW64 `bin` directory to PATH.
  echo See https://www.msys2.org/ for instructions.
  exit /b 1
)

echo Assembling runtime and stdlib (NASM)...
nasm -f win64 ..\lib\io.asm -o ..\lib\io.obj
nasm -f win64 ..\lib\memory.asm -o ..\lib\memory.obj
nasm -f win64 ..\lib\string.asm -o ..\lib\string.obj
nasm -f win64 ..\lib\runtime.asm -o ..\lib\runtime.obj

echo Linking with gcc (MinGW-w64)...
gcc -m64 -o %OUTPUT% %USEROBJ% ..\lib\io.obj ..\lib\memory.obj ..\lib\string.obj ..\lib\runtime.obj -Wl,--subsystem,console

if errorlevel 1 (
  echo Link failed.
  exit /b 1
)

echo Linked %OUTPUT%
endlocal
