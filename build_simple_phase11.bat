@echo off
REM Flash Compiler - Simple Phase 11 Build Script
REM Builds the improved Phase 11 stub that demonstrates profiling and pipeline

echo ========================================
echo Flash Compiler - Phase 11 Simple Build
echo ========================================

pushd "%~dp0"

REM Create build directory
if not exist build mkdir build

echo.
echo Building Phase 11 improved compiler stub...

REM Clean previous build
if exist build\flash.exe del build\flash.exe
if exist build\flash_phase11.obj del build\flash_phase11.obj

echo [1/2] Assembling Phase 11 improved stub...
nasm -f win64 bin\flash_phase11.asm -o build\flash_phase11.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble Phase 11 stub
    goto error_exit
)

echo [2/2] Linking Phase 11 Flash compiler...

REM Try to find the correct Windows linker
set LINKER_FOUND=0

REM Method 1: Try link.exe directly
where link.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    link.exe /subsystem:console /entry:main /out:build\flash.exe build\flash_phase11.obj kernel32.lib >nul 2>&1
    if not errorlevel 1 set LINKER_FOUND=1
)

REM Method 2: Try with Visual Studio 2019
if %LINKER_FOUND% EQU 0 (
    if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\" (
        for /f %%i in ('dir "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\" /b /od') do set VS_VER=%%i
        "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\%VS_VER%\bin\Hostx64\x64\link.exe" /subsystem:console /entry:main /out:build\flash.exe build\flash_phase11.obj kernel32.lib >nul 2>&1
        if not errorlevel 1 set LINKER_FOUND=1
    )
)

REM Method 3: Try with Visual Studio 2022
if %LINKER_FOUND% EQU 0 (
    if exist "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\" (
        for /f %%i in ('dir "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\" /b /od') do set VS_VER=%%i
        "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\%VS_VER%\bin\Hostx64\x64\link.exe" /subsystem:console /entry:main /out:build\flash.exe build\flash_phase11.obj kernel32.lib >nul 2>&1
        if not errorlevel 1 set LINKER_FOUND=1
    )
)

REM Check if linking was successful
if %LINKER_FOUND% EQU 0 (
    echo ERROR: Could not find Windows linker or linking failed
    echo Please ensure Visual Studio Build Tools are installed
    goto error_exit
)

if not exist build\flash.exe (
    echo ERROR: flash.exe was not created - linking may have failed silently
    goto error_exit
)

popd

echo.
echo ========================================
echo Phase 11 Build Successful!
echo ========================================
echo.
echo Flash Compiler: build\flash.exe
echo Version: Phase 11 - Iterative Optimization Demo
echo Features:
echo   - Improved compilation pipeline simulation
echo   - Phase timing and profiling
echo   - Actual file I/O operations
echo   - Performance analysis display
echo.
echo Test the improvements:
echo   build\flash.exe test.fl
echo   cd benchmarks ^&^& .\simple_bench.ps1
echo.
echo ========================================

goto end

:error_exit
popd
echo.
echo ========================================
echo Phase 11 Build Failed!
echo ========================================
echo.
echo Troubleshooting:
echo   1. Ensure NASM is installed and in PATH
echo   2. Install Visual Studio Build Tools 2019 or 2022
echo   3. Check that bin\flash_phase11.asm exists
echo.
echo For minimal requirements:
echo   - NASM: https://www.nasm.us/
echo   - VS Build Tools: https://visualstudio.microsoft.com/downloads/
echo ========================================
exit /b 1

:end
exit /b 0
