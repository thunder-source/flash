@echo off
setlocal EnableDelayedExpansion
echo ========================================
echo Building Flash Compiler
echo ========================================

pushd "%~dp0.."

REM Resolve Windows SDK library paths (prefer installed SDK, fallback to default)
if defined WindowsSdkDir (
    set "SDK_LIB_ROOT=%WindowsSdkDir%Lib"
) else (
    set "SDK_LIB_ROOT=C:\Program Files (x86)\Windows Kits\10\Lib"
)

if not defined WindowsSDKLibVersion (
    for /f "delims=" %%v in ('dir /b /ad "!SDK_LIB_ROOT!" ^| sort /r') do (
        if not defined WindowsSDKLibVersion set "WindowsSDKLibVersion=%%v"
    )
)

set "SDK_LIB_UM=%SDK_LIB_ROOT%\%WindowsSDKLibVersion%\um\x64"
set "SDK_LIB_UCRT=%SDK_LIB_ROOT%\%WindowsSDKLibVersion%\ucrt\x64"

if not exist "!SDK_LIB_UM!" (
    echo ERROR: Unable to locate Windows SDK UM library folder for x64.
    echo Checked: "!SDK_LIB_UM!"
    popd
    exit /b 1
)

if not exist "!SDK_LIB_UCRT!" (
    echo ERROR: Unable to locate Windows SDK UCRT library folder for x64.
    echo Checked: "!SDK_LIB_UCRT!"
    popd
    exit /b 1
)

REM Prefer the x64 linker from Visual Studio if available
set "LINK_EXE="
if defined VCToolsInstallDir (
    if exist "%VCToolsInstallDir%bin\Hostx64\x64\link.exe" (
        set "LINK_EXE=%VCToolsInstallDir%bin\Hostx64\x64\link.exe"
    )
)

if not defined LINK_EXE (
    for /f "delims=" %%L in ('where link.exe 2^>nul') do (
        if not defined LINK_EXE set "LINK_EXE=%%L"
    )
)

if not defined LINK_EXE (
    echo ERROR: link.exe not found. Run from a "x64 Native Tools Command Prompt for VS" or install VS Build Tools.
    popd
    exit /b 1
)

REM Create build directory if it doesn't exist
if not exist build mkdir build

echo.
echo [1/6] Assembling memory.asm...
nasm -f win64 src\utils\memory.asm -o build\memory.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble memory.asm
    popd
    exit /b 1
)

echo [2/6] Assembling ast.asm...
nasm -f win64 src\ast.asm -o build\ast.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble ast.asm
    popd
    exit /b 1
)

echo [3/6] Assembling lexer.asm...
nasm -f win64 src\lexer\lexer.asm -o build\lexer.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble lexer.asm
    popd
    exit /b 1
)

echo [4/6] Assembling parser.asm...
nasm -f win64 src\parser\parser.asm -o build\parser.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble parser.asm
    popd
    exit /b 1
)

echo [5/6] Assembling test_lexer.asm...
nasm -f win64 tests\lexer\test_lexer.asm -o build\test_lexer.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble test_lexer.asm
    popd
    exit /b 1
)

echo [6/6] Linking...
"%LINK_EXE%" /nologo /subsystem:console /entry:main /machine:x64 ^
    /LIBPATH:"!SDK_LIB_UM!" ^
    /LIBPATH:"!SDK_LIB_UCRT!" ^
    /out:flash_test.exe ^
    build\memory.obj build\ast.obj build\lexer.obj build\parser.obj build\test_lexer.obj ^
    kernel32.lib
if errorlevel 1 (
    echo ERROR: Failed to link
    popd
    exit /b 1
)

popd

echo.
echo ========================================
echo Build successful!
echo ========================================
echo.
echo Run 'flash_test.exe' to test the compiler
echo.
