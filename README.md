# Flash Compiler

A high-performance compiler written in pure x86-64 assembly, designed to beat C/C++ in compilation speed and generated code performance.

## Project Status

**Phase 3: Lexer Implementation** ✓ Complete
**Phase 4: Parser Implementation** ✓ Complete

The compiler now includes:
- **Lexer**: Fast keyword recognition, efficient tokenization, full token support
- **Parser**: Recursive descent parser building Abstract Syntax Trees
- **Memory**: Arena-based allocator for fast AST node allocation
- **AST**: Complete node definitions for all language constructs

## Requirements

- **NASM** (Netwide Assembler) - Download from https://www.nasm.us/
- **Microsoft Visual Studio** (for the linker) or **Windows SDK**
- **Windows x64**

## Building

### Build parser test (recommended):

```batch
build_parser.bat
```

This builds the parser test which includes the lexer, parser, and memory allocator.

### Build lexer test only:

```batch
build.bat
```

## Testing

### Test the parser:

```batch
parser_test.exe
```

This will parse a sample Flash program and build an AST.

### Test the lexer only:

```batch
flash_test.exe
```

This will tokenize a sample Flash program and print all tokens.

## Project Structure

```
flash/
├── src/
│   ├── lexer.asm          # Lexer (tokenizer) implementation
│   ├── parser.asm         # Parser (syntax analyzer) implementation
│   ├── ast.asm            # AST node definitions
│   ├── memory.asm         # Arena-based memory allocator
│   ├── test_lexer.asm     # Lexer test program
│   └── test_parser.asm    # Parser test program
├── build/                 # Compiled object files (generated)
├── plan.md               # Development roadmap
├── language-spec.md      # Flash language specification
├── Makefile              # Build configuration
├── build.bat             # Lexer build script
├── build_parser.bat      # Parser build script
└── README.md             # This file
```

## Flash Language Features

````markdown
# Flash Compiler

Flash is a small, high-performance compiler toolchain implemented primarily in x86-64 assembly. The project focuses on compact, fast tooling for a systems-style language called Flash and includes components from lexing through code generation and packaging for Windows.

## Quick status

- Active: lexer, parser, AST, IR, optimizations, and codegen components present in `src/`
- Packaging: release automation and package manifests for Chocolatey, Scoop and WinGet under `packaging/`

## Prerequisites

- `nasm` (Netwide Assembler) — https://www.nasm.us/
- Visual Studio (linker `link.exe`) / Windows SDK or MinGW (alternative) for linking
- Windows x64 for official builds and packaging; many build scripts are Windows-oriented

## Build (quick)

The repository includes several build helpers. From a PowerShell prompt in the repository root you can run (recommended):

```powershell
.\scripts\build.bat        # builds core components and tests (Windows .bat)
.\scripts\build_all.bat    # full build including codegen and examples
```

If you prefer to use the Makefile (requires GNU make or Microsoft `nmake` configured for your toolchain):

```powershell
nmake release                # builds a release binary and prepares dist/zip
nmake clean                  # clean build artifacts
```

For MinGW-based linking, use the included helper:

```powershell
.\scripts\flash_compile_mingw.bat
```

Build artifacts are placed under `build/` and release packaging (zip) is created under `dist/`. The project binary is expected at `bin/flash.exe` for packaging and installers.

## Run examples & tests

- Examples are in `examples/` — assemble/run compiled `flash.exe` against example sources.
- Integration and unit tests live in `tests/` and `tests/*/` subfolders. The repository contains batch scripts such as `test_all.bat` and various `build_*_test.bat` scripts under `scripts/`.

Typical test-run (PowerShell):

```powershell
.\scripts\build_test.bat
.\test_all.bat
```

## Packaging & Installation

The project ships packaging manifests and helpers for Windows package managers:

- Chocolatey: `packaging/chocolatey/` (contains `.nuspec` and installer scripts)
- Scoop: `packaging/scoop/flash.json`
- WinGet: `packaging/winget/thunder-source.flash.yaml`

You can install a packaged release locally using the `scripts/install.ps1` script after extracting a release zip produced in `dist/`:

```powershell
Expand-Archive -Path .\dist\flash-vX.Y.Z-windows-x64.zip -DestinationPath .\tmp
.\scripts\install.ps1 -SourceDir .\tmp
```

## Project layout (high level)

```
`/`                    - repository root
├─ `bin/`               - CLI entry assembly and packaging target (`bin/flash.asm`)
├─ `build/`             - build output (object files, executables)
├─ `src/`               - compiler sources (lexer, parser, ir, codegen, core, utils)
├─ `lib/`, `include/`   - runtime code and headers
├─ `scripts/`           - build/test/install helper scripts
├─ `packaging/`         - manifests for Chocolatey, Scoop, WinGet
├─ `examples/`          - sample Flash programs
└─ `tests/`             - unit/integration tests and test harnesses
```

## Contributing

- Read `RELEASE.md` and `INSTALLATION.md` for release and packaging guidelines.
- Open issues and PRs are welcome; small, focused reviews / patches are easiest to merge.

## Where to start for development

1. Build the project with `.\scripts\build.bat`.
2. Run a small example from `examples/` to exercise the front-end.
3. Use files under `src/ir/`, `src/codegen/` and `src/core/` to explore backend work.

## License

This project is open source; see repository for license details.

````
- **Phase 7**: Optimization passes
