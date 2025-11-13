@echo off
echo ========================================
echo Building Optimization Test
echo ========================================

set "LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64"

pushd "%~dp0.."

REM Create build directory if it doesn't exist
if not exist build mkdir build

echo.
echo [1/5] Assembling memory.asm...
nasm -f win64 src\utils\memory.asm -o build\memory.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble memory.asm
    popd
    exit /b 1
)

echo [2/5] Assembling ir.asm...
nasm -f win64 src\ir\ir.asm -o build\ir.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble ir.asm
    popd
    exit /b 1
)

echo [3/5] Assembling optimize.asm...
nasm -f win64 src\ir\optimize.asm -o build\optimize.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble optimize.asm
    popd
    exit /b 1
)

echo [4/5] Assembling test_optimize.asm...
nasm -f win64 tests\integration\test_optimize.asm -o build\test_optimize.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble test_optimize.asm
    popd
    exit /b 1
)

echo [5/5] Linking...

REM Try to find link.exe
where link.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo Using link.exe from PATH
    link /subsystem:console /entry:main /LARGEADDRESSAWARE:NO /out:optimize_test.exe build\memory.obj build\ir.obj build\optimize.obj build\test_optimize.obj kernel32.lib
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
    echo Run 'optimize_test.exe' to test optimizations
    echo.
    exit /b 0
)

REM Check for GoLink
where golink.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo Using GoLink as alternative linker
    golink /console /entry _main optimize_test.exe build\memory.obj build\ir.obj build\optimize.obj build\test_optimize.obj kernel32.dll
    if errorlevel 1 (
        echo ERROR: Failed to link with GoLink
        popd
        exit /b 1
    )
    popd
    echo.
    echo ========================================
    echo Build successful!
    echo ========================================
    echo.
    echo Run 'optimize_test.exe' to test optimizations
    echo.
    exit /b 0
)

REM No linker available
echo.
echo ========================================
echo WARNING: No linker available!
echo ========================================
echo.
echo Compilation completed successfully.
echo All .obj files created without errors.
echo.
echo Cannot create optimize_test.exe without a linker.
echo.
echo Object files are valid and ready:
echo   - build\memory.obj
echo   - build\ir.obj
echo   - build\optimize.obj
echo   - build\test_optimize.obj
echo.

popd
exit /b 0
