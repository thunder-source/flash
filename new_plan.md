# Flash Compiler Roadmap

## Phase 0 – Stabilize Front End
- DONE - Fix remaining lexer warnings, align token structures, add unit tests.
- Restore the full recursive-descent parser so it builds ASTs again.
- DONE - Add regression tests that feed sample Flash programs through lexer + parser.

## Phase 1 – Semantic Analysis & IR
- Implement symbol tables, scopes, name resolution, and type checking.
- Finish intermediate representation (IR) builders for expressions/statements.
- Add semantic regression tests covering errors and valid programs.

## Phase 2 – Code Generation & Runtime
- Choose the initial backend target (Windows x64 PE) and emit machine code/assembly from IR.
- Flesh out the runtime library (memory, IO, math) and ABI glue.
- Integrate with the Windows linker (`link.exe`/`lld`) to produce runnable executables.

## Phase 3 – CLI Compiler (`flash.exe`)
- Build the command-line driver handling input files, include paths, output selection, diagnostics.
- Wire lexer → parser → semantic → codegen → link into `flash.exe`.
- Provide diagnostics formatting and file/diagnostic pipeline support.

## Phase 4 – Packaging & Installation
- Standardize artifact layout (`bin/flash.exe`, runtime libs) for release builds.
- Finish packaging scripts for Chocolatey, Scoop, WinGet, plus installer/zip creation.
- Update documentation with install instructions and CLI usage.

## Phase 5 – Ecosystem Polish
- Expand examples/tests, add CI/regression automation, re-enable benchmarking suite.
- Improve tooling support (editor integrations, diagnostics UX).
- Iterate on performance and add optional developer tools (language server, etc.).

