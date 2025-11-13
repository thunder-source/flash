# Flash Compiler - Testing Guide

## Prerequisites

### Required Software

1. **NASM (Netwide Assembler)**
   - Download from: https://www.nasm.us/
   - Version: 2.15 or higher
   - Installation:
     ```
     Download nasm-X.XX-installer-x64.exe
     Run installer
     Add NASM to PATH: C:\Program Files\NASM
     ```

2. **Microsoft Visual Studio** (for the linker)
   - Visual Studio 2019 or later (Community Edition is free)
   - OR Windows SDK (for standalone link.exe)
   - Ensure `link.exe` is in your PATH

3. **Windows 10/11 x64**
   - Required for Windows x64 calling conventions

### Verify Installation

Open Command Prompt or PowerShell and run:

```batch
nasm -v
link /?
```

Both commands should execute successfully.

## Building the Tests

### Option 1: Comprehensive Test Suite (Recommended)

This runs 8 different test programs through the parser:

```batch
build_test.bat
```

This will:
- Compile all compiler components
- Build the comprehensive test executable
- Create `flash_test.exe`

### Option 2: Simple Parser Test

Tests basic parser functionality:

```batch
build_parser.bat
```

Creates `parser_test.exe`

### Option 3: Lexer Only Test

Tests just the lexer/tokenizer:

```batch
build.bat
```

Creates `flash_test.exe` (lexer version)

## Running the Tests

### Comprehensive Test Suite

```batch
flash_test.exe
```

**Expected Output:**
```
========================================
Flash Compiler - Comprehensive Parser Test
========================================

Initializing...
Testing: Test 1: Simple Function
Parsing... [PASS] Test 1: Simple Function

Testing: Test 2: Function with Variable
Parsing... [PASS] Test 2: Function with Variable

Testing: Test 3: If Statement
Parsing... [PASS] Test 3: If Statement

Testing: Test 4: While Loop
Parsing... [PASS] Test 4: While Loop

Testing: Test 5: For Loop
Parsing... [PASS] Test 5: For Loop

Testing: Test 6: Multiple Statements
Parsing... [PASS] Test 6: Multiple Statements

Testing: Test 7: Nested Blocks
Parsing... [PASS] Test 7: Nested Blocks

Testing: Test 8: Multiple Functions
Parsing... [PASS] Test 8: Multiple Functions

========================================
Test Summary:
Total Tests: 8
Passed: 8
Failed: 0
========================================
Testing complete!
```

### Simple Parser Test

```batch
parser_test.exe
```

**Expected Output:**
```
Initializing compiler...
Initializing lexer...
Initializing parser...
Parsing program...
Parse successful!
AST Root: Program node
Test complete.
```

## Sample Flash Programs

Sample programs are located in the `examples/` directory:

### 1. hello.fl - Simple Function
```flash
fn main() -> i32 {
    return 0;
}
```

### 2. fibonacci.fl - Recursive Function
```flash
fn fibonacci(n: i32) -> i32 {
    if n <= 1 {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

fn main() -> i32 {
    let result: i32 = fibonacci(10);
    return result;
}
```

### 3. variables.fl - Variable Declarations
```flash
fn main() -> i32 {
    let x: i32 = 10;
    let mut y: i32 = 20;
    y = y + x;
    let z: i32 = x + y;
    return z;
}
```

### 4. control_flow.fl - If/While/For
```flash
fn test_if(x: i32) -> i32 {
    if x > 0 {
        return 1;
    } else if x < 0 {
        return -1;
    } else {
        return 0;
    }
}

fn test_while() -> i32 {
    let mut sum: i32 = 0;
    let mut i: i32 = 0;
    while i < 10 {
        sum = sum + i;
        i = i + 1;
    }
    return sum;
}

fn test_for() -> i32 {
    let mut sum: i32 = 0;
    for i in 0..10 {
        sum = sum + i;
    }
    return sum;
}
```

### 5. pointers.fl - Pointer Operations
```flash
fn swap(a: *i32, b: *i32) {
    let temp: i32 = *a;
    *a = *b;
    *b = temp;
}

fn main() -> i32 {
    let mut x: i32 = 10;
    let mut y: i32 = 20;
    swap(&x, &y);
    return x + y;
}
```

### 6. nested.fl - Nested Control Structures
```flash
fn complex_logic(n: i32) -> i32 {
    let mut result: i32 = 0;
    for i in 0..n {
        if i % 2 == 0 {
            let mut j: i32 = 0;
            while j < i {
                result = result + 1;
                j = j + 1;
            }
        } else {
            result = result + i;
        }
    }
    return result;
}
```

### 7. types.fl - All Type Declarations
```flash
fn test_types() -> i32 {
    let a: i8 = 10;
    let b: i16 = 100;
    let c: i32 = 1000;
    let d: i64 = 10000;
    
    let e: u8 = 10;
    let f: u16 = 100;
    let g: u32 = 1000;
    let h: u64 = 10000;
    
    let x: f32 = 3.14;
    let y: f64 = 2.718;
    
    let flag: bool = true;
    let ch: char = 65;
    
    return 0;
}
```

## Test Coverage

### What's Being Tested

#### Lexer Tests
- ✅ Keyword recognition (fn, let, mut, if, else, while, for, return, etc.)
- ✅ Type keywords (i8, i16, i32, i64, u8, u16, u32, u64, f32, f64, bool, char, ptr)
- ✅ Operators (+, -, *, /, %, ==, !=, <, >, <=, >=, &&, ||, !, &, |, ^, ~, <<, >>)
- ✅ Compound assignments (+=, -=, *=, /=, %=, &=, |=, ^=, <<=, >>=)
- ✅ Punctuation ((), {}, [], ;, :, ,, ., ->, ..)
- ✅ Number literals (integers and floats)
- ✅ String literals
- ✅ Character literals
- ✅ Identifiers
- ✅ Comments (// and /* */)
- ✅ Whitespace handling

#### Parser Tests
- ✅ Function declarations
- ✅ Function parameters
- ✅ Return types
- ✅ Block statements
- ✅ Let statements (immutable and mutable)
- ✅ Assignment statements
- ✅ If/else statements
- ✅ Else-if chains
- ✅ While loops
- ✅ For loops (range-based)
- ✅ Return statements
- ✅ Break statements
- ✅ Continue statements
- ✅ Expression statements
- ✅ Literal expressions
- ✅ Identifier expressions
- ✅ Type parsing (primitive, pointer)
- ✅ Nested blocks
- ✅ Multiple functions

#### Memory Allocator Tests
- ✅ Arena initialization
- ✅ Fast allocation
- ✅ Arena reset
- ✅ 16-byte alignment
- ✅ Large allocations (1MB+ arenas)

### What's NOT Yet Tested (Future Phases)

- ❌ Binary expressions (a + b, a * b, etc.)
- ❌ Unary expressions (!, -, *, &)
- ❌ Function calls
- ❌ Array indexing
- ❌ Field access
- ❌ Struct definitions
- ❌ Enum definitions
- ❌ Import statements
- ❌ Const definitions
- ❌ Array literals
- ❌ Struct literals
- ❌ Type checking (semantic analysis)
- ❌ Symbol tables
- ❌ Scope resolution
- ❌ Code generation

## Troubleshooting

### Build Errors

**Error: "nasm is not recognized"**
- Solution: Install NASM and add to PATH
- Verify: Run `nasm -v` in command prompt

**Error: "link is not recognized"**
- Solution: Install Visual Studio or Windows SDK
- Add to PATH: `C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\XX.XX.XXXXX\bin\Hostx64\x64`

**Error: "Failed to assemble"**
- Check NASM version (must be 2.15+)
- Check file paths (use absolute paths if relative fails)
- Review error message for syntax errors

**Error: "Failed to link"**
- Ensure all .obj files were created in build/ directory
- Check that kernel32.lib is accessible
- Try running from Visual Studio Developer Command Prompt

### Runtime Errors

**Program crashes immediately**
- Likely memory allocation issue
- Check that VirtualAlloc succeeded
- Increase arena size if needed

**Parse fails on valid input**
- Check for unimplemented features
- Verify source code matches Flash syntax
- Add debug output to parser

**All tests fail**
- Check lexer initialization
- Verify parser initialization
- Test lexer separately with `build.bat`

## Performance Testing

### Compilation Speed Test

Time the compilation:

```batch
time build_test.bat
```

**Expected Time:**
- Phase 1 (Memory): < 0.5s
- Phase 2 (Lexer): < 1s
- Phase 3 (Parser): < 1.5s
- Phase 4 (Test): < 0.5s
- Phase 5 (Link): < 1s
- **Total: < 5 seconds**

### Parser Speed Test

Add timing to test programs to measure parse speed:
- Small programs (< 100 lines): < 1ms
- Medium programs (100-1000 lines): < 10ms
- Large programs (1000-10000 lines): < 100ms

### Memory Usage Test

Monitor memory usage during tests:
- Default arena: 1MB
- Typical AST for small program: < 10KB
- Can handle 100+ functions in default arena

## Manual Testing

### Custom Test Programs

Create your own `.fl` files in `examples/` directory:

1. Write Flash source code
2. Modify test program to include your source
3. Rebuild with `build_test.bat`
4. Run `flash_test.exe`

### Interactive Testing

To test individual components:

**Test Lexer Only:**
```batch
build.bat
flash_test.exe
```

**Test Parser Only:**
```batch
build_parser.bat
parser_test.exe
```

**Test Specific Features:**
- Modify test source code in test programs
- Rebuild and run
- Check output for pass/fail

## Debugging

### Adding Debug Output

To add debug prints, modify test programs:

```asm
; Add after lexer init
lea rcx, [debug_msg]
call print_cstring

; Add after parser result
mov rcx, rax  ; AST root pointer
call print_hex  ; Print pointer value
```

### Common Issues

1. **Token not recognized**
   - Check lexer keyword table
   - Verify token type constants match

2. **Parse error on valid syntax**
   - Check parser grammar matches spec
   - Verify all statement types implemented

3. **Memory allocation fails**
   - Increase arena size in memory.asm
   - Check VirtualAlloc return value

4. **Segmentation fault**
   - Check pointer initialization
   - Verify null checks before dereferencing
   - Ensure proper stack alignment

## Next Steps

After successful testing:

1. **Add More Tests**: Create additional `.fl` examples
2. **Benchmark**: Compare parse speed with other compilers
3. **Profile**: Use profiler to find hot spots
4. **Optimize**: Improve slow paths in lexer/parser
5. **Phase 5**: Implement semantic analysis

## Test Results Log

Document your test results:

```
Date: ___________
NASM Version: ___________
Link Version: ___________
Windows Version: ___________

Build Time: ___________
Test 1: [ ] PASS [ ] FAIL
Test 2: [ ] PASS [ ] FAIL
Test 3: [ ] PASS [ ] FAIL
Test 4: [ ] PASS [ ] FAIL
Test 5: [ ] PASS [ ] FAIL
Test 6: [ ] PASS [ ] FAIL
Test 7: [ ] PASS [ ] FAIL
Test 8: [ ] PASS [ ] FAIL

Total Passed: ___ / 8
Notes: ___________
```

## Continuous Integration

For automated testing:

```batch
@echo off
call build_test.bat
if errorlevel 1 exit /b 1

flash_test.exe > test_results.txt
if errorlevel 1 (
    echo Tests failed!
    type test_results.txt
    exit /b 1
)

echo All tests passed!
exit /b 0
```

Save as `run_tests.bat` and run regularly during development.
