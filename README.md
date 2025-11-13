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

Flash is a minimal, high-performance systems programming language with:

- Explicit typing (no type inference)
- Manual memory management
- Zero-cost abstractions
- Inline assembly support
- Minimal runtime overhead

See `language-spec.md` for complete language documentation.

## Architecture

### Lexer (Phase 3) ✓

The lexer is a high-performance tokenizer written entirely in x86-64 assembly:

- **Token Types**: 60+ token types including keywords, operators, and literals
- **Keyword Recognition**: Fast lookup table-based keyword matching
- **Comment Handling**: Single-line (`//`) and multi-line (`/* */`) comments
- **Number Parsing**: Integer and floating-point literals
- **String Parsing**: String literals with escape sequence support
- **Character Literals**: Single character literals
- **Operator Recognition**: All arithmetic, logical, bitwise, and comparison operators
- **Error Handling**: Returns error tokens for invalid input

### Parser (Phase 4) ✓

The parser is a recursive descent parser built in pure assembly:

- **AST Construction**: Builds complete Abstract Syntax Trees
- **Node Types**: 30+ AST node types for all language constructs
- **Function Parsing**: Complete function definition parsing with parameters and return types
- **Statement Parsing**: All statement types (let, if, while, for, return, break, continue)
- **Expression Parsing**: Literals, identifiers, binary/unary operators
- **Type Parsing**: Primitive types, pointers, arrays, named types
- **Memory Management**: Fast arena-based allocator for AST nodes
- **Error Recovery**: Panic mode for error handling

### Memory Allocator ✓

Arena-based memory allocator for maximum performance:

- **Fast Allocation**: O(1) allocation time
- **No Fragmentation**: Linear allocation strategy
- **Bulk Deallocation**: Free entire arena at once
- **Cache Friendly**: Contiguous memory allocation
- **Windows API**: Uses VirtualAlloc for large memory blocks

### Performance Optimizations

1. **Cache-friendly data structures**: Token and Lexer structures designed for CPU cache
2. **Minimal branching**: Optimized control flow for branch prediction
3. **Direct character access**: No function call overhead for simple operations
4. **Inline scanning**: Character classification done inline where possible
5. **Fast keyword lookup**: Linear search optimized for common keywords first

## Token Types

### Keywords
- Control flow: `fn`, `if`, `else`, `while`, `for`, `in`, `break`, `continue`, `return`
- Declarations: `let`, `mut`, `struct`, `enum`, `import`, `export`, `cconst`
- Types: `i8`, `i16`, `i32`, `i64`, `u8`, `u16`, `u32`, `u64`, `f32`, `f64`, `bool`, `char`, `ptr`
- Literals: `true`, `false`
- Special: `inline`, `asm`, `sizeof`, `alloc`, `free`, `from`

### Operators
- Arithmetic: `+`, `-`, `*`, `/`, `%`
- Comparison: `==`, `!=`, `<`, `>`, `<=`, `>=`
- Logical: `&&`, `||`, `!`
- Bitwise: `&`, `|`, `^`, `~`, `<<`, `>>`
- Assignment: `=`, `+=`, `-=`, `*=`, `/=`, `%=`, `&=`, `|=`, `^=`, `<<=`, `>>=`

### Punctuation
- Brackets: `(`, `)`, `{`, `}`, `[`, `]`
- Separators: `;`, `:`, `,`, `.`
- Special: `->`, `..`

## Example Flash Code

```flash
fn fibonacci(n: i32) -> i32 {
    if n <= 1 {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

fn main() {
    let result: i32 = fibonacci(10);
}
```

## Next Steps

- **Phase 4**: Parser implementation (build Abstract Syntax Tree)
- **Phase 5**: Semantic analysis (type checking, symbol tables)
- **Phase 6**: Intermediate representation (IR) design
- **Phase 7**: Optimization passes
- **Phase 8**: x86-64 code generation
- **Phase 9**: Standard library
- **Phase 10**: Benchmarking

## Performance Goals

- **Compilation Speed**: 2-5x faster than GCC/Clang
- **Generated Code**: Within 95-100% of GCC -O3 performance
- **Binary Size**: Smaller than competing compilers
- **Memory Usage**: Lower than mainstream compilers

## Contributing

This is a learning project focused on understanding compiler design and assembly programming. Feel free to explore, learn, and experiment!

## License

Open source - feel free to use and modify.
