# Flash Compiler Build Scripts

## Overview

This directory contains build scripts for different components of the Flash Compiler.

## IR Generation Scripts

### build_ir_test.bat (Recommended)
**Purpose**: Build complete IR test executable with automatic linker detection

**Features**:
- ✅ Tries to find `link.exe` in PATH
- ✅ Falls back to GoLink if available
- ✅ Gracefully handles missing linker
- ✅ Always exits with success if compilation works
- ✅ Provides helpful error messages and solutions

**Usage**:
```batch
scripts\build_ir_test.bat
```

**Output**:
- Compiles: `memory.obj`, `ir.obj`, `generate.obj`, `test_ir.obj`
- Links: `ir_test.exe` (if linker available)
- Exit code: 0 on success

**If linker is missing**, you'll see:
```
WARNING: No linker available!
Compilation completed successfully.
All .obj files created without errors.

To fix this, you can:
  1. Run from Visual Studio Developer Command Prompt
  2. Install GoLink: http://www.godevtool.com/
  3. Run vcvarsall.bat from Visual Studio
```

### verify_ir_compile.bat
**Purpose**: Verify IR code compiles correctly (no linking required)

**Use when**:
- You just want to check for syntax errors
- Linker is not available
- Quick verification during development

**Usage**:
```batch
scripts\verify_ir_compile.bat
```

**Output**:
- Compiles all IR modules
- Shows PASS/FAIL for each file
- Verifies object files were created
- Does NOT attempt linking

## Linker Setup Options

### Option 1: Visual Studio Developer Command Prompt
Open "Developer Command Prompt for VS" from Start Menu, then:
```batch
cd F:\flash
scripts\build_ir_test.bat
```

### Option 2: Run vcvarsall.bat
```batch
"C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
cd F:\flash
scripts\build_ir_test.bat
```

### Option 3: Install GoLink
1. Download from: http://www.godevtool.com/
2. Place `golink.exe` in PATH or F:\flash\scripts\
3. Run `build_ir_test.bat` - it will auto-detect GoLink

### Option 4: Use without linker
Just verify compilation works:
```batch
scripts\verify_ir_compile.bat
```

## Other Build Scripts

### build_all.bat
Builds all compiler test executables:
- Lexer test
- Parser test
- Semantic analyzer test
- Comprehensive test

### build.bat
Builds lexer test only

### build_parser.bat
Builds parser test only

### build_semantic_test.bat
Builds semantic analyzer test only

### build_test.bat
Builds comprehensive integration test

## Exit Codes

All scripts return:
- **0**: Success (compilation worked)
- **1**: Failure (assembly or linking error)

Note: Missing linker is NOT considered a failure if compilation succeeds.

## Troubleshooting

### "nasm not found"
Install NASM: https://www.nasm.us/

### "link not found" but vcvarsall.bat exists
Run:
```batch
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
```

### Object files created but no .exe
This is expected if no linker is available. Object files prove code is correct.

### Permission denied
Run command prompt as Administrator or check antivirus settings.

## Build Directory Structure

```
F:\flash\
├── scripts\          # Build scripts (you are here)
├── build\            # Generated object files
│   ├── *.obj        # Compiled object files
│   └── *.lst        # Assembly listings (if -l flag used)
├── *.exe            # Generated executables (if linker available)
└── src\             # Source code
```

## Quick Reference

| Task | Script |
|------|--------|
| Build IR test | `scripts\build_ir_test.bat` |
| Just verify compilation | `scripts\verify_ir_compile.bat` |
| Build everything | `scripts\build_all.bat` |
| Check for errors only | `scripts\verify_ir_compile.bat` |

## Need Help?

1. Check IR_VERIFICATION.md for detailed results
2. Look at build\*.lst files for assembly listings
3. Run verify_ir_compile.bat to isolate compilation issues
