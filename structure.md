my-compiler/
├── src/
│ ├── main.asm # Entry point
│ ├── lexer/
│ │ ├── lexer.asm # Main lexer logic
│ │ └── token.asm # Token handling
│ ├── parser/
│ │ ├── parser.asm # Main parser
│ │ ├── expr.asm # Expression parsing
│ │ └── stmt.asm # Statement parsing
│ ├── semantic/
│ │ ├── analyze.asm # Semantic analysis
│ │ └── types.asm # Type checking
│ ├── codegen/
│ │ ├── codegen.asm # Code generation
│ │ └── emit.asm # Emit instructions
│ ├── utils/
│ │ ├── string.asm # String operations
│ │ ├── memory.asm # Memory management
│ │ └── buffer.asm # I/O buffering
│ └── core/
│ ├── error.asm # Error handling
│ └── symbols.asm # Symbol table
├── include/
│ ├── constants.inc # Global constants
│ ├── macros.inc # Common macros
│ ├── structs.inc # Data structure definitions
│ └── extern.inc # External declarations
├── lib/
│ └── runtime.asm # Runtime library (if needed)
├── tests/
│ ├── lexer/
│ ├── parser/
│ └── integration/
├── examples/
│ ├── hello.src # Sample source files
│ └── fibonacci.src
├── docs/
│ ├── architecture.md
│ ├── grammar.txt # Language grammar
│ └── opcodes.txt # Generated code reference
├── build/
│ └── .gitkeep # Keep empty build directory
├── bin/
│ └── .gitkeep # Compiled compiler goes here
├── Makefile # Or build.sh
└── README.md

implement this folder structure in this code base
