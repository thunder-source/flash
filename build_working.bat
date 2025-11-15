@echo off
REM Flash Compiler - Working Build Script with Correct VS Linker
REM Uses explicit path to Visual Studio linker to avoid Git link conflict

echo ============================================
echo Flash Compiler - Working Build (Phase 11)
echo ============================================

pushd "%~dp0"

REM Create build directory
if not exist build mkdir build

echo.
echo Building Flash Compiler with Visual Studio linker...

REM Clean previous builds
if exist build\flash.exe del build\flash.exe
if exist build\flash.obj del build\flash.obj

echo [1/2] Assembling Flash compiler...
nasm -f win64 bin\flash.asm -o build\flash.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble flash.asm
    echo Make sure NASM is installed and in PATH
    goto error_exit
)

echo [2/2] Linking with Visual Studio linker...

REM Set up Visual Studio and Windows SDK paths
set VS_LINKER="C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64\link.exe"
set SDK_LIB="C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64"
set SDK_UCRT="C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64"

if not exist %VS_LINKER% (
    echo ERROR: Visual Studio linker not found at expected location
    echo Expected: %VS_LINKER%
    echo.
    echo Trying to find linker automatically...

    REM Try to find any available linker
    for /f "delims=" %%i in ('dir "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\*\bin\Hostx64\x64\link.exe" /s /b 2^>nul') do (
        set VS_LINKER="%%i"
        goto found_linker
    )

    echo ERROR: Could not find Visual Studio linker
    goto error_exit
)

:found_linker
echo Using linker: %VS_LINKER%
echo Using SDK libraries: %SDK_LIB%

%VS_LINKER% /subsystem:console /entry:main /out:build\flash.exe build\flash.obj /LIBPATH:%SDK_LIB% /LIBPATH:%SDK_UCRT% kernel32.lib user32.lib

if errorlevel 1 (
    echo ERROR: Failed to link Flash compiler
    goto error_exit
)

if not exist build\flash.exe (
    echo ERROR: flash.exe was not created
    goto error_exit
)

popd

echo.
echo ============================================
echo SUCCESS! Flash Compiler Built Successfully
echo ============================================
echo.
echo Location: build\flash.exe
echo Version: Phase 11 - Iterative Optimization
echo.
echo Test the compiler:
echo   build\flash.exe --version
echo.
echo Run benchmarks:
echo   cd benchmarks
echo   .\simple_bench.ps1 -Iterations 3
echo.
echo ============================================
goto end

:error_exit
popd
echo.
echo ============================================
echo Build Failed!
echo ============================================
echo.
echo Troubleshooting steps:
echo 1. Ensure NASM is installed: nasm --version
echo 2. Check Visual Studio Build Tools are installed
echo 3. Try running from "Developer Command Prompt for VS"
echo.
echo If issues persist, the problem may be:
echo - Missing Windows SDK
echo - Incomplete Visual Studio installation
echo - PATH conflicts
echo ============================================
exit /b 1

:end
exit /b 0
