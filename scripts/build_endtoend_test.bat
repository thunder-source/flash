@echo off
setlocal enabledelayedexpansion

rem ============================================================================
rem build_endtoend_test.bat
rem Builds the comprehensive end-to-end integration test
rem Assembles all compiler modules + stdlib and links into executable
rem ============================================================================

echo Assembling compiler modules...
nasm -f win64 ..\src\utils\memory.asm -o ..\build\memory.obj
nasm -f win64 ..\src\lexer\lexer.asm -o ..\build\lexer.obj
nasm -f win64 ..\src\ast.asm -o ..\build\ast.obj
nasm -f win64 ..\src\parser\parser.asm -o ..\build\parser.obj
nasm -f win64 ..\src\core\symbols.asm -o ..\build\symbols.obj
nasm -f win64 ..\src\semantic\analyze.asm -o ..\build\semantic.obj
nasm -f win64 ..\src\ir\ir.asm -o ..\build\ir.obj
nasm -f win64 ..\src\ir\generate.asm -o ..\build\ir_gen.obj
nasm -f win64 ..\src\ir\optimize.asm -o ..\build\ir_opt.obj
nasm -f win64 ..\src\codegen\codegen.asm -o ..\build\codegen.obj
nasm -f win64 ..\src\codegen\regalloc.asm -o ..\build\regalloc.obj

echo Assembling stdlib...
nasm -f win64 ..\lib\io.asm -o ..\build\io.obj
nasm -f win64 ..\lib\memory.asm -o ..\build\stdlib_mem.obj
nasm -f win64 ..\lib\string.asm -o ..\build\stdlib_str.obj
nasm -f win64 ..\lib\runtime.asm -o ..\build\runtime.obj

echo Assembling integration test...
nasm -f win64 ..\tests\integration\test_endtoend.asm -o ..\build\test_endtoend.obj

echo Linking executable...
gcc -m64 -o ..\build\test_endtoend.exe ^
  ..\build\test_endtoend.obj ^
  ..\build\memory.obj ^
  ..\build\lexer.obj ^
  ..\build\ast.obj ^
  ..\build\parser.obj ^
  ..\build\symbols.obj ^
  ..\build\semantic.obj ^
  ..\build\ir.obj ^
  ..\build\ir_gen.obj ^
  ..\build\ir_opt.obj ^
  ..\build\codegen.obj ^
  ..\build\regalloc.obj ^
  ..\build\io.obj ^
  ..\build\stdlib_mem.obj ^
  ..\build\stdlib_str.obj ^
  ..\build\runtime.obj ^
  -Wl,--subsystem,console

if errorlevel 1 (
  echo Build failed.
  exit /b 1
)

echo Build successful! Run with: ..\build\test_endtoend.exe
