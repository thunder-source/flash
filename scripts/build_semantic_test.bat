@echo off
echo ========================================
echo Building Semantic Analyzer Test
echo ========================================

pushd "%~dp0.."

REM Create build directory if it doesn't exist
if not exist build mkdir build

echo.
echo [1/3] Assembling memory.asm...
nasm -f win64 src\utils\memory.asm -o build\memory.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble memory.asm
    popd
    exit /b 1
)

echo [2/3] Assembling symbols.asm...
nasm -f win64 src\core\symbols.asm -o build\symbols.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble symbols.asm
    popd
    exit /b 1
)

echo [3/3] Assembling test_semantic.asm...
nasm -f win64 tests\integration\test_semantic.asm -o build\test_semantic.obj
if errorlevel 1 (
    echo ERROR: Failed to assemble test_semantic.asm
    popd
    exit /b 1
)

echo [4/4] Linking...
link /subsystem:console /entry:main /out:semantic_test.exe build\memory.obj build\symbols.obj build\test_semantic.obj kernel32.lib
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
echo Run 'semantic_test.exe' to test the semantic analyzer
echo.
