@echo off
REM Flash Compiler - Phase 11 Build Script
REM Simple build that integrates real compiler components

echo ========================================
echo Building Flash Compiler - Phase 11
echo ========================================

pushd "%~dp0"

REM Create build directory
if not exist build mkdir build

echo.
echo [Phase 11] Building complete Flash compiler...

REM Clean previous builds
if exist build\*.obj del build\*.obj
if exist build\flash.exe del build\flash.exe

echo [1/9] Assembling CLI interface...
nasm -f win64 bin\flash.asm -o build\flash_bin.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble CLI interface
    goto error_exit
)

echo [2/9] Assembling memory management...
nasm -f win64 src\utils\memory.asm -o build\memory.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble memory management
    goto error_exit
)

echo [3/9] Assembling AST module...
nasm -f win64 src\ast.asm -o build\ast.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble AST module
    goto error_exit
)

echo [4/9] Assembling lexer...
nasm -f win64 src\lexer\lexer.asm -o build\lexer.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble lexer
    goto error_exit
)

echo [5/9] Assembling parser...
nasm -f win64 src\parser\parser.asm -o build\parser.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble parser
    goto error_exit
)

echo [6/9] Assembling semantic analyzer...
nasm -f win64 src\semantic\analyze.asm -o build\semantic.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble semantic analyzer
    goto error_exit
)

echo [7/9] Assembling IR generator...
nasm -f win64 src\ir\ir.asm -o build\ir.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble IR generator
    goto error_exit
)

echo [8/9] Assembling code generator...
nasm -f win64 src\codegen\codegen.asm -o build\codegen.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble code generator
    goto error_exit
)

echo [9/9] Linking complete Flash compiler...

REM Find the correct linker
set LINKER_CMD=""
where link.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set LINKER_CMD=link.exe
) else (
    REM Try Visual Studio paths
    if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\" (
        for /f %%i in ('dir "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\" /b /od') do set VS_VER=%%i
        set LINKER_CMD="%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\%VS_VER%\bin\Hostx64\x64\link.exe"
    ) else if exist "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\" (
        for /f %%i in ('dir "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\" /b /od') do set VS_VER=%%i
        set LINKER_CMD="%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\%VS_VER%\bin\Hostx64\x64\link.exe"
    )
)

if %LINKER_CMD%=="" (
    echo ERROR: Could not find Windows linker. Please install Visual Studio Build Tools.
    goto error_exit
)

REM Link with all components
%LINKER_CMD% /subsystem:console /entry:main /out:build\flash.exe build\flash_bin.obj build\memory.obj build\ast.obj build\lexer.obj build\parser.obj build\semantic.obj build\ir.obj build\codegen.obj kernel32.lib user32.lib

if errorlevel 1 (
    echo ERROR: Failed to link Flash compiler
    goto error_exit
)

popd

echo.
echo ========================================
echo Phase 11 Build Successful!
echo ========================================
echo.
echo Flash Compiler: build\flash.exe
echo Status: Complete compiler integration
echo Next: Run benchmark tests to validate
echo.
echo Test with: cd benchmarks ^&^& .\simple_bench.ps1
echo ========================================

goto end

:error_exit
popd
echo.
echo ========================================
echo Phase 11 Build Failed!
echo ========================================
echo.
echo Please check the error messages above.
echo Make sure you have:
echo   - NASM installed and in PATH
echo   - Visual Studio Build Tools installed
echo   - All source files present
echo ========================================
exit /b 1

:end
exit /b 0
