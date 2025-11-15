@echo off
REM Flash Compiler - Phase 11 Working Build Script
REM Successfully builds complete compiler with all real components

echo ========================================
echo Flash Compiler - Phase 11 Working Build
echo Complete Real Compiler Integration
echo ========================================

pushd "%~dp0"

REM Create build directory
if not exist build mkdir build

echo.
echo [Phase 11] Building complete Flash compiler with real components...

REM Clean previous builds
if exist build\*.obj del build\*.obj
if exist build\flash.exe del build\flash.exe

echo [1/10] Assembling CLI interface...
nasm -f win64 bin\flash.asm -o build\flash_bin.obj
if errorlevel 1 goto error_exit

echo [2/10] Assembling memory management...
nasm -f win64 src\utils\memory.asm -o build\memory.obj
if errorlevel 1 goto error_exit

echo [3/10] Assembling AST module...
nasm -f win64 src\ast.asm -o build\ast.obj
if errorlevel 1 goto error_exit

echo [4/10] Assembling lexer...
nasm -f win64 src\lexer\lexer.asm -o build\lexer.obj
if errorlevel 1 goto error_exit

echo [5/10] Assembling parser...
nasm -f win64 src\parser\parser.asm -o build\parser.obj
if errorlevel 1 goto error_exit

echo [6/10] Assembling semantic analyzer...
nasm -f win64 src\semantic\analyze.asm -o build\semantic.obj
if errorlevel 1 goto error_exit

echo [7/10] Assembling IR generator...
nasm -f win64 src\ir\ir.asm -o build\ir.obj
if errorlevel 1 goto error_exit

echo [8/10] Assembling code generator...
nasm -f win64 src\codegen\codegen.asm -o build\codegen.obj
if errorlevel 1 goto error_exit

echo [9/10] Assembling symbol table...
nasm -f win64 src\core\symbols.asm -o build\symbols.obj
if errorlevel 1 goto error_exit

echo [10/10] Assembling register allocator...
nasm -f win64 src\codegen\regalloc.asm -o build\regalloc.obj
if errorlevel 1 goto error_exit

echo.
echo Linking complete Flash compiler...

REM Use the correct Visual Studio linker with full path
"C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64\link.exe" /subsystem:console /entry:main /LARGEADDRESSAWARE:NO /out:build\flash.exe build\flash_bin.obj build\memory.obj build\ast.obj build\lexer.obj build\parser.obj build\semantic.obj build\ir.obj build\codegen.obj build\symbols.obj build\regalloc.obj "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64\kernel32.lib" "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64\user32.lib"

if errorlevel 1 goto error_exit

popd

echo.
echo ========================================
echo Phase 11 Build SUCCESS!
echo ========================================
echo.
echo Flash Compiler: build\flash.exe
echo.
echo Real Compiler Components Integrated:
echo   * CLI Interface ^(bin\flash.asm^)
echo   * Memory Management ^(arena allocator^)
echo   * Lexer ^(tokenization^)
echo   * Parser ^(AST generation^)
echo   * Semantic Analysis ^(symbol tables^)
echo   * IR Generation ^(three-address code^)
echo   * Code Generation ^(x86-64 assembly^)
echo   * Register Allocation
echo.
echo Status: Complete compiler integration achieved
echo Next Steps:
echo   1. Debug runtime integration issues
echo   2. Add error handling and validation
echo   3. Test with simple Flash programs
echo   4. Run benchmark performance tests
echo.
echo ========================================
echo Phase 11 COMPLETE: Real compiler components connected!
echo ========================================

goto end

:error_exit
popd
echo.
echo ========================================
echo Phase 11 Build FAILED!
echo ========================================
echo.
echo Please check the error messages above.
echo Make sure you have:
echo   - NASM installed and in PATH
echo   - Visual Studio Build Tools installed
echo   - Windows 10 SDK installed
echo   - All source files present
echo ========================================
exit /b 1

:end
exit /b 0
