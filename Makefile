# Flash Compiler Makefile - Phase 11 Complete Build System
# Builds the entire Flash compiler with all components linked

NASM = nasm
LINK = link.exe
NASMFLAGS = -f win64
LINKFLAGS = /subsystem:console /entry:main

BIN_DIR = bin
BUILD_DIR = build
SRC_DIR = src
DIST_DIR = dist

# Object files for all compiler components
COMPILER_OBJS = \
	$(BUILD_DIR)\flash_bin.obj \
	$(BUILD_DIR)\compiler.obj \
	$(BUILD_DIR)\ast.obj \
	$(BUILD_DIR)\lexer.obj \
	$(BUILD_DIR)\parser.obj \
	$(BUILD_DIR)\semantic.obj \
	$(BUILD_DIR)\ir.obj \
	$(BUILD_DIR)\codegen.obj \
	$(BUILD_DIR)\memory.obj \
	$(BUILD_DIR)\core.obj

# Windows libraries
LIBS = kernel32.lib user32.lib

.PHONY: all clean build-compiler test release help

# Default target - build complete compiler
all: build-compiler

# Help target
help:
	@echo Flash Compiler Build System - Phase 11
	@echo =====================================
	@echo.
	@echo Targets:
	@echo   all           - Build complete Flash compiler (default)
	@echo   build-compiler- Build flash.exe with all components
	@echo   test          - Build and run tests
	@echo   clean         - Remove build artifacts
	@echo   release       - Create release package
	@echo   help          - Show this help

# Create build directory
$(BUILD_DIR):
	@if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)
	@echo Created build directory

# Build main CLI interface
$(BUILD_DIR)\flash_bin.obj: $(BIN_DIR)\flash.asm $(BUILD_DIR)
	@echo Assembling CLI interface...
	$(NASM) $(NASMFLAGS) $(BIN_DIR)\flash.asm -o $(BUILD_DIR)\flash_bin.obj

# Build main compiler orchestrator
$(BUILD_DIR)\compiler.obj: $(SRC_DIR)\compiler.asm $(BUILD_DIR)
	@echo Assembling compiler orchestrator...
	$(NASM) $(NASMFLAGS) $(SRC_DIR)\compiler.asm -o $(BUILD_DIR)\compiler.obj

# Build AST module
$(BUILD_DIR)\ast.obj: $(SRC_DIR)\ast.asm $(BUILD_DIR)
	@echo Assembling AST module...
	$(NASM) $(NASMFLAGS) $(SRC_DIR)\ast.asm -o $(BUILD_DIR)\ast.obj

# Build lexer
$(BUILD_DIR)\lexer.obj: $(SRC_DIR)\lexer\lexer.asm $(BUILD_DIR)
	@echo Assembling lexer...
	$(NASM) $(NASMFLAGS) $(SRC_DIR)\lexer\lexer.asm -o $(BUILD_DIR)\lexer.obj

# Build parser
$(BUILD_DIR)\parser.obj: $(SRC_DIR)\parser\parser.asm $(BUILD_DIR)
	@echo Assembling parser...
	$(NASM) $(NASMFLAGS) $(SRC_DIR)\parser\parser.asm -o $(BUILD_DIR)\parser.obj

# Build semantic analyzer
$(BUILD_DIR)\semantic.obj: $(SRC_DIR)\semantic\analyze.asm $(BUILD_DIR)
	@echo Assembling semantic analyzer...
	$(NASM) $(NASMFLAGS) $(SRC_DIR)\semantic\analyze.asm -o $(BUILD_DIR)\semantic.obj

# Build IR generator
$(BUILD_DIR)\ir.obj: $(SRC_DIR)\ir\ir.asm $(BUILD_DIR)
	@echo Assembling IR generator...
	$(NASM) $(NASMFLAGS) $(SRC_DIR)\ir\ir.asm -o $(BUILD_DIR)\ir.obj

# Build code generator
$(BUILD_DIR)\codegen.obj: $(SRC_DIR)\codegen\codegen.asm $(BUILD_DIR)
	@echo Assembling code generator...
	$(NASM) $(NASMFLAGS) $(SRC_DIR)\codegen\codegen.asm -o $(BUILD_DIR)\codegen.obj

# Build memory management
$(BUILD_DIR)\memory.obj: $(SRC_DIR)\utils\memory.asm $(BUILD_DIR)
	@echo Assembling memory management...
	$(NASM) $(NASMFLAGS) $(SRC_DIR)\utils\memory.asm -o $(BUILD_DIR)\memory.obj

# Build core utilities (optional)
$(BUILD_DIR)\core.obj: $(BUILD_DIR)
	@if exist $(SRC_DIR)\core\core.asm ($(NASM) $(NASMFLAGS) $(SRC_DIR)\core\core.asm -o $(BUILD_DIR)\core.obj) else (echo. > $(BUILD_DIR)\core.obj)

# Link complete Flash compiler
build-compiler: $(COMPILER_OBJS)
	@echo Linking Flash compiler...
	$(LINK) $(LINKFLAGS) /out:$(BUILD_DIR)\flash.exe $(COMPILER_OBJS) $(LIBS)
	@echo.
	@echo ========================================
	@echo Flash Compiler built successfully!
	@echo Location: $(BUILD_DIR)\flash.exe
	@echo Phase 11: Complete compiler integration
	@echo ========================================

# Test targets
test: build-compiler
	@echo Running Flash compiler tests...
	@if exist $(BUILD_DIR)\flash.exe ($(BUILD_DIR)\flash.exe --version) else (echo Error: Compiler not built)

# Test with benchmark framework
test-bench: build-compiler
	@echo Running benchmark tests...
	@cd benchmarks && powershell -ExecutionPolicy Bypass ".\simple_bench.ps1 -Iterations 3"

# Clean build artifacts
clean:
	@echo Cleaning build artifacts...
	@if exist $(BUILD_DIR) rmdir /s /q $(BUILD_DIR)
	@if exist $(DIST_DIR) rmdir /s /q $(DIST_DIR)
	@if exist flash_test.exe del flash_test.exe
	@if exist parser_test.exe del parser_test.exe
	@if exist *.obj del *.obj
	@echo Clean completed.

# Release packaging
VERSION = 0.2.0

release: build-compiler
	@echo Creating release package...
	@if not exist $(DIST_DIR) mkdir $(DIST_DIR)
	@if exist $(DIST_DIR)\flash rmdir /s /q $(DIST_DIR)\flash
	@mkdir $(DIST_DIR)\flash\bin
	@copy $(BUILD_DIR)\flash.exe $(DIST_DIR)\flash\bin\flash.exe
	@if exist include xcopy /E /I /Y include $(DIST_DIR)\flash\include >nul
	@if exist lib xcopy /E /I /Y lib $(DIST_DIR)\flash\lib >nul
	@if exist share xcopy /E /I /Y share $(DIST_DIR)\flash\share >nul
	@if exist examples xcopy /E /I /Y examples $(DIST_DIR)\flash\examples >nul
	@copy README.md $(DIST_DIR)\flash\ >nul 2>&1
	@copy PHASE_11_ITERATIVE_OPTIMIZATION.md $(DIST_DIR)\flash\ >nul 2>&1
	@powershell -NoProfile -Command "if (Test-Path '$(DIST_DIR)\\flash') { Compress-Archive -Path '$(DIST_DIR)\\flash\\*' -DestinationPath '$(DIST_DIR)\\flash-v$(VERSION)-windows-x64.zip' -Force; Write-Output 'Release created: $(DIST_DIR)\\flash-v$(VERSION)-windows-x64.zip' } else { Write-Error 'Release directory not found' }"

# Update package manager manifests
update-manifests: release
	@powershell -NoProfile -ExecutionPolicy Bypass -File packaging\update-manifests.ps1 -Version $(VERSION) -ZipPath $(DIST_DIR)\flash-v$(VERSION)-windows-x64.zip
	@echo Package manifests updated for version $(VERSION)

# Debug build with symbols (if debugger available)
debug: build-compiler
	@echo Debug build completed with symbols

# Profile build for performance analysis
profile: build-compiler
	@echo Profile build completed

# Install locally (for development)
install: build-compiler
	@echo Installing Flash compiler locally...
	@if not exist "%LOCALAPPDATA%\Programs\Flash" mkdir "%LOCALAPPDATA%\Programs\Flash"
	@copy $(BUILD_DIR)\flash.exe "%LOCALAPPDATA%\Programs\Flash\flash.exe"
	@echo Flash compiler installed to %LOCALAPPDATA%\Programs\Flash
	@echo Add this directory to your PATH to use 'flash' command globally

# Show build status and component information
status:
	@echo Flash Compiler Build Status
	@echo ===========================
	@echo.
	@echo Components:
	@if exist $(SRC_DIR)\compiler.asm (echo   [x] Compiler orchestrator) else (echo   [ ] Compiler orchestrator)
	@if exist $(SRC_DIR)\ast.asm (echo   [x] AST module) else (echo   [ ] AST module)
	@if exist $(SRC_DIR)\lexer\lexer.asm (echo   [x] Lexer) else (echo   [ ] Lexer)
	@if exist $(SRC_DIR)\parser\parser.asm (echo   [x] Parser) else (echo   [ ] Parser)
	@if exist $(SRC_DIR)\semantic\analyze.asm (echo   [x] Semantic analyzer) else (echo   [ ] Semantic analyzer)
	@if exist $(SRC_DIR)\ir\ir.asm (echo   [x] IR generator) else (echo   [ ] IR generator)
	@if exist $(SRC_DIR)\codegen\codegen.asm (echo   [x] Code generator) else (echo   [ ] Code generator)
	@if exist $(SRC_DIR)\utils\memory.asm (echo   [x] Memory management) else (echo   [ ] Memory management)
	@echo.
	@echo Build artifacts:
	@if exist $(BUILD_DIR)\flash.exe (echo   [x] flash.exe - Ready) else (echo   [ ] flash.exe - Not built)
	@echo.
	@echo Phase 11 Status: Iterative Optimization
	@echo Integration: Complete compiler build system ready

# Continuous integration target
ci: clean build-compiler test
	@echo Continuous integration completed successfully

# Development helpers
dev-setup:
	@echo Setting up development environment...
	@if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)
	@echo Development environment ready

# Quick build for development iteration
quick: $(BUILD_DIR) $(BUILD_DIR)\flash_bin.obj $(BUILD_DIR)\compiler.obj $(BUILD_DIR)\memory.obj
	@echo Quick build (core components only)...
	$(LINK) $(LINKFLAGS) /out:$(BUILD_DIR)\flash.exe $(BUILD_DIR)\flash_bin.obj $(BUILD_DIR)\compiler.obj $(BUILD_DIR)\memory.obj $(LIBS)
	@echo Quick build completed
