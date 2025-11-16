@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Building Flash Compiler - Production Build
echo ========================================

:: Configuration
set BUILD_TYPE=Release
if "%1"=="debug" set BUILD_TYPE=Debug

:: Directories
set ROOT_DIR=%~dp0..
set BUILD_DIR=%ROOT_DIR%\build\%BUILD_TYPE%
set BIN_DIR=%BUILD_DIR%\bin
set OBJ_DIR=%BUILD_DIR%\obj
set SRC_DIR=%ROOT_DIR%\src
set TEST_DIR=%ROOT_DIR%\tests

:: Create build directories
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%OBJ_DIR%" mkdir "%OBJ_DIR%"

:: Compiler and Linker flags
set NASM_FLAGS=-f win64
if "%BUILD_TYPE%"=="Debug" set NASM_FLAGS=!NASM_FLAGS! -g

set LINK_FLAGS=/subsystem:console /entry:main /machine:x64
if "%BUILD_TYPE%"=="Debug" (
    set LINK_FLAGS=!LINK_FLAGS! /DEBUG
) else (
    set LINK_FLAGS=!LINK_FLAGS! /RELEASE
)

echo.
echo Building %BUILD_TYPE% configuration...
echo.

:: Build core components
set "OBJECTS="
for %%c in (
    utils\memory.asm
    lexer\lexer.asm
    parser\parser.asm
    main.asm
) do (
    echo [ASM] %%c
    set "src_file=%SRC_DIR%\%%c"
    set "obj_file=%OBJ_DIR%\%%~nc.obj"
    
    if not exist "!src_file!" (
        echo ERROR: Source file not found: !src_file!
        exit /b 1
    )
    
    nasm %NASM_FLAGS% -o "!obj_file!" "!src_file!"
    if errorlevel 1 (
        echo ERROR: Failed to assemble %%c
        exit /b 1
    )
    set "OBJECTS=!OBJECTS! "!obj_file!""
)

:: Link the compiler executable
echo.
echo [LINK] Building flash_compiler.exe...
link %LINK_FLAGS% /out:"%BIN_DIR%\flash_compiler.exe" ^
    %OBJECTS% ^
    /LIBPATH:"%WindowsSdkDir%Lib\%WindowsSDKVersion%um\x64" ^
    /LIBPATH:"%VCToolsInstallDir%lib\x64" ^
    kernel32.lib user32.lib msvcrt.lib

if errorlevel 1 (
    echo ERROR: Failed to link flash_compiler.exe
    exit /b 1
)

echo.
echo ========================================
echo Build successful!
echo Compiler executable: %BIN_DIR%\flash_compiler.exe
echo ========================================

endlocal