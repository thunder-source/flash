# Flash Compiler - Build Guide

## Quick Start

### Build Everything
```bash
build_all.bat
# or
scripts\build_all.bat
```
This builds all test executables in one go.

### Run All Tests
```bash
test_all.bat
# or
scripts\test_all.bat
```
This runs all available test executables.

---

## Individual Build Scripts

All build scripts are located in the `scripts/` folder.

### `scripts\build.bat`
**Builds:** Lexer test executable  
**Output:** `flash_test.exe`  
**Tests:** Basic lexer tokenization

```bash
scripts\build.bat
flash_test.exe
```

### `scripts\build_parser.bat`
**Builds:** Parser test executable  
**Output:** `parser_test.exe`  
**Tests:** Parser and AST construction

```bash
scripts\build_parser.bat
parser_test.exe
```

### `scripts\build_semantic_test.bat`
**Builds:** Semantic analyzer test  
**Output:** `semantic_test.exe`  
**Tests:** Symbol table and basic semantic analysis

```bash
scripts\build_semantic_test.bat
semantic_test.exe
```

### `scripts\build_test.bat`
**Builds:** Comprehensive test suite  
**Output:** `flash_test.exe` (overwrites lexer test)  
**Tests:** Complete compiler pipeline

```bash
scripts\build_test.bat
flash_test.exe
```

---

## Environment Setup

### Option 1: Use Developer Command Prompt (Recommended)
1. Search for "Developer Command Prompt for VS 2022" in Windows Start menu
2. Navigate to project: `cd F:\flash`
3. Run any build script

### Option 2: Manual Environment Setup
If not using Developer Command Prompt, set the LIB environment variable:

```batch
set "LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64"
```

Then run build scripts normally.

---

## Requirements

- **NASM** 2.16+ (Netwide Assembler)
- **Microsoft Linker** (from Visual Studio or Build Tools)
- **Windows SDK** (for kernel32.lib and other system libraries)

### Install NASM
```bash
# Option 1: Direct download from https://www.nasm.us/
# Option 2: Chocolatey
choco install nasm
```

### Install Build Tools
Download "Build Tools for Visual Studio 2022" from:
https://visualstudio.microsoft.com/downloads/

Select "C++ build tools" during installation.

---

## Build Output

All object files go to: `build/`  
All executables go to: project root

### Generated Files
- `build/*.obj` - Compiled object files
- `flash_test.exe` - Test executable
- `parser_test.exe` - Parser test executable
- `semantic_test.exe` - Semantic analyzer test executable

---

## Troubleshooting

### Error: "nasm: command not found"
**Solution:** Add NASM to your PATH or install it

### Error: "link: command not found"
**Solution:** Use Developer Command Prompt or install Visual Studio Build Tools

### Error: "cannot open input file 'kernel32.lib'"
**Solution:** Set the LIB environment variable or use Developer Command Prompt

### Error: "Failed to assemble *.asm"
**Solution:** Check NASM is installed correctly and the source file exists in the new folder structure

---

## Project Structure

```
flash/
├── src/
│   ├── lexer/          # Lexer implementation
│   ├── parser/         # Parser implementation
│   ├── semantic/       # Semantic analyzer
│   ├── core/           # Core (symbol table)
│   ├── utils/          # Utilities (memory management)
│   └── ast.asm         # AST definitions
├── tests/
│   ├── lexer/          # Lexer tests
│   ├── parser/         # Parser tests
│   └── integration/    # Integration tests
├── scripts/            # Build and test scripts
│   ├── build.bat
│   ├── build_parser.bat
│   ├── build_semantic_test.bat
│   ├── build_test.bat
│   ├── build_all.bat   # Master build script
│   └── test_all.bat    # Master test runner
├── build/              # Build artifacts (.obj files)
├── bin/                # Output executables
├── build_all.bat       # Convenience launcher
└── test_all.bat        # Convenience launcher
```

---

## Next Steps

After building and testing:

1. **Phase 6:** Implement Intermediate Representation (IR)
2. **Phase 7:** Add optimization passes
3. **Phase 8:** Implement code generation
4. **Phase 9:** Create standard library
5. **Phase 10:** Benchmark and optimize
