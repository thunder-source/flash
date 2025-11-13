# Language Specification - Flash Compiler

## Language Name: Flash

A minimal, high-performance systems programming language designed for maximum speed.

## Design Philosophy

1. **Zero-cost abstractions**: Only pay for what you use
2. **Explicit over implicit**: No hidden costs or magic
3. **Minimal runtime**: No garbage collection, minimal standard library
4. **Speed-first**: Every feature evaluated for performance impact
5. **Simple syntax**: Easy to parse, fast to compile

## Type System

### Primitive Types

```
// Integers (signed)
i8      // 8-bit signed integer
i16     // 16-bit signed integer
i32     // 32-bit signed integer
i64     // 64-bit signed integer

// Integers (unsigned)
u8      // 8-bit unsigned integer
u16     // 16-bit unsigned integer
u32     // 32-bit unsigned integer
u64     // 64-bit unsigned integer

// Floating point
f32     // 32-bit IEEE 754 float
f64     // 64-bit IEEE 754 double

// Boolean
bool    // true or false (1 byte)

// Character
char    // 8-bit ASCII character

// Pointer
ptr     // Raw pointer type
```

### Composite Types

```
// Arrays (fixed size)
[type; size]        // Example: [i32; 10]

// Pointers
*type               // Example: *i32

// Structures
struct Name {
    field1: type,
    field2: type,
}

// Enums
enum Status {
    Ok = 0,
    Error = 1,
}
```

## Syntax

### Variable Declaration

```
// Immutable by default (explicitly typed)
let x: i32 = 10;

// Mutable variables (must use mut keyword)
let mut y: i32 = 20;
y = 30;  // Valid because y is mutable

// Immutable cannot be reassigned
let z: i32 = 15;
// z = 25;  // ERROR: cannot assign to immutable variable
```

### Functions

```
// Basic function
fn add(a: i32, b: i32) -> i32 {
    return a + b;
}

// No return value (void)
fn print_number(n: i32) {
    // implementation
}

// Inline hint for performance
inline fn fast_add(a: i32, b: i32) -> i32 {
    return a + b;
}
```

### Control Flow

```
// If statement (no parentheses required around condition)
if x > 0 {
    // code
} else if x < 0 {
    // code
} else {
    // code
}

// While loop
while x < 10 {
    x = x + 1;
}

// For loop (range-based)
for i in 0..10 {
    // code
}

// Break and continue
while true {
    if condition {
        break;
    }
    if other_condition {
        continue;
    }
}
```

### Operators

```
// Arithmetic
+  -  *  /  %

// Comparison
==  !=  <  >  <=  >=

// Logical
&&  ||  !

// Bitwise
&  |  ^  ~  <<  >>

// Assignment
=  +=  -=  *=  /=  %=  &=  |=  ^=  <<=  >>=

// Address-of (reference)
&   // Gets memory address of variable
```

### Pointers and References

```
// Get address of variable
let mut x: i32 = 42;
let ptr: *i32 = &x;

// Dereference pointer to get/set value
let value: i32 = *ptr;
*ptr = 100;  // x is now 100

// Pointer arithmetic
ptr = ptr + 1;
```

### Structures

```
// Definition
struct Point {
    x: i32,
    y: i32,
}

// Instantiation
let p: Point = Point { x: 10, y: 20 };

// Field access
let x_val: i32 = p.x;

// Mutable struct
let mut p2: Point = Point { x: 0, y: 0 };
p2.x = 15;
```

### Arrays

```
// Fixed-size arrays
let arr: [i32; 5] = [1, 2, 3, 4, 5];

// Array indexing
let first: i32 = arr[0];

// Array length (compile-time constant)
let size: i32 = 5;  // Must track manually or use sizeof
```

### Memory Management

```
// Explicit allocation (calls system allocator)
let ptr: *i32 = alloc(sizeof(i32));

// Use the allocated memory
*ptr = 42;

// Explicit deallocation (required)
free(ptr);

// Stack allocation (automatic)
let x: i32 = 10;  // Freed when out of scope
```

### Inline Assembly

```
// Direct assembly for maximum control
asm {
    mov rax, 1
    mov rdi, 1
    syscall
}

// Assembly with operands
asm {
    mov rax, $0
} : "=r"(result) : "r"(input);
```

## Keywords

```
fn          // Function definition
let         // Variable declaration
mut         // Mutable modifier
if          // Conditional
else        // Alternative condition
while       // Loop
for         // Range-based loop
in          // Iterator keyword
break       // Exit loop
continue    // Skip iteration
return      // Return from function
struct      // Structure definition
enum        // Enumeration definition
true        // Boolean literal
false       // Boolean literal
inline      // Inline hint
asm         // Inline assembly block
sizeof      // Size of type
alloc       // Allocate memory
free        // Free memory
import      // Import module
export      // Export symbol
cconst      // Compile-time constant
```

## Comments

```
// Single line comment

/*
   Multi-line comment
   spanning multiple lines
*/
```

## Module System

```
// Import entire module
import io;

// Import specific symbol from module
import { print } from io;

// Import with alias
import io as input_output;

// Import from path
import math from "std/math";

// Use imported functions
io.print("Hello");
print("Hello");  // If imported with {}
```

### Export Symbols

```
// Export function for other modules
export fn public_function() {
    // code
}

// Export struct
export struct PublicStruct {
    field: i32,
}

// Export constant
export cconst PUBLIC_CONST: i32 = 100;
```

## Compile-Time Constants

```
cconst MAX_SIZE: i32 = 1024;
cconst PI: f64 = 3.14159265359;

// Used in array sizes and other compile-time contexts
let buffer: [u8; MAX_SIZE];

// Compile-time evaluation
cconst BUFFER_SIZE: i32 = MAX_SIZE * 2;
```

## Example Programs

### Hello World

```
import io;

fn main() {
    io.print("Hello, World!\n");
}
```

### Fibonacci

```
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

### Array Sum

```
fn sum_array(arr: *i32, len: i32) -> i32 {
    let mut total: i32 = 0;
    let mut i: i32 = 0;

    while i < len {
        total = total + arr[i];
        i = i + 1;
    }

    return total;
}

fn main() {
    let numbers: [i32; 5] = [1, 2, 3, 4, 5];
    let sum: i32 = sum_array(&numbers[0], 5);
}
```

### Pointer Example

```
fn swap(a: *i32, b: *i32) {
    let temp: i32 = *a;
    *a = *b;
    *b = temp;
}

fn main() {
    let mut x: i32 = 10;
    let mut y: i32 = 20;

    swap(&x, &y);
    // x is now 20, y is now 10
}
```

## Features NOT Included (for Speed)

- No garbage collection
- No exceptions (use error codes)
- No classes/inheritance (use structs and function pointers)
- No operator overloading
- No templates/generics (initially)
- No automatic type coercion
- No dynamic dispatch (initially)
- No runtime type information (RTTI)
- No type inference (all types must be explicit)

## Calling Conventions

### x86-64 (System V AMD64 ABI)

- First 6 integer args: RDI, RSI, RDX, RCX, R8, R9
- First 8 float args: XMM0-XMM7
- Return value: RAX (integer), XMM0 (float)
- Stack aligned to 16 bytes
- Caller-saved: RAX, RCX, RDX, RSI, RDI, R8-R11
- Callee-saved: RBX, RBP, R12-R15

### Windows x64

- First 4 args: RCX, RDX, R8, R9
- Float args: XMM0-XMM3
- Return value: RAX (integer), XMM0 (float)
- Stack aligned to 16 bytes
- Shadow space: 32 bytes reserved by caller
- Callee-saved: RBX, RBP, RDI, RSI, RSP, R12-R15

## Memory Model

- Stack grows downward
- Heap managed by explicit alloc/free
- No automatic memory management
- Programmer responsible for all memory
- No double-free protection (undefined behavior)
- No null pointer checking (undefined behavior)

## Standard Library (Minimal)

```
// io module
io.print(str: *char)           // Print string
io.println(str: *char)         // Print string with newline
io.read_line() -> *char        // Read line from stdin
io.open(path: *char) -> i32    // Open file, returns fd
io.close(fd: i32)              // Close file
io.read(fd: i32, buf: *u8, len: i32) -> i32   // Read from file
io.write(fd: i32, buf: *u8, len: i32) -> i32  // Write to file

// math module
math.sqrt(x: f64) -> f64       // Square root
math.pow(x: f64, y: f64) -> f64 // Power
math.abs(x: i32) -> i32        // Absolute value
math.fabs(x: f64) -> f64       // Floating point absolute value
math.floor(x: f64) -> f64      // Floor
math.ceil(x: f64) -> f64       // Ceiling

// memory module
mem.copy(dest: *u8, src: *u8, size: i32)    // Memory copy
mem.set(dest: *u8, val: u8, size: i32)      // Memory set
mem.cmp(a: *u8, b: *u8, size: i32) -> i32   // Memory compare
mem.zero(dest: *u8, size: i32)              // Zero memory

// string module
str.len(s: *char) -> i32       // String length
str.cmp(a: *char, b: *char) -> i32  // String compare
str.copy(dest: *char, src: *char)   // String copy
str.cat(dest: *char, src: *char)    // String concatenate
```

## Grammar (EBNF-like)

```
program         = { import_stmt | function_def | struct_def | enum_def | cconst_def }

import_stmt     = "import" ( simple_import | named_import | aliased_import ) ";"
simple_import   = identifier
named_import    = "{" identifier { "," identifier } "}" "from" identifier
aliased_import  = identifier "from" string_literal

cconst_def      = [ "export" ] "cconst" identifier ":" type "=" expression ";"

function_def    = [ "export" ] [ "inline" ] "fn" identifier "(" params ")" [ "->" type ] block

params          = [ param { "," param } ]
param           = identifier ":" type

struct_def      = [ "export" ] "struct" identifier "{" { field_def } "}"
field_def       = identifier ":" type ","

enum_def        = [ "export" ] "enum" identifier "{" { enum_variant } "}"
enum_variant    = identifier "=" number ","

block           = "{" { statement } "}"

statement       = let_stmt | assignment | if_stmt | while_stmt | for_stmt
                | return_stmt | break_stmt | continue_stmt | expr_stmt | asm_block

let_stmt        = "let" [ "mut" ] identifier ":" type "=" expression ";"
assignment      = lvalue assign_op expression ";"
lvalue          = identifier | "*" expression | expression "[" expression "]" | expression "." identifier
assign_op       = "=" | "+=" | "-=" | "*=" | "/=" | "%=" | "&=" | "|=" | "^=" | "<<=" | ">>="

if_stmt         = "if" expression block [ "else" ( if_stmt | block ) ]
while_stmt      = "while" expression block
for_stmt        = "for" identifier "in" expression ".." expression block
return_stmt     = "return" [ expression ] ";"
break_stmt      = "break" ";"
continue_stmt   = "continue" ";"
expr_stmt       = expression ";"

asm_block       = "asm" "{" asm_instructions "}"

expression      = logical_or
logical_or      = logical_and { "||" logical_and }
logical_and     = bitwise_or { "&&" bitwise_or }
bitwise_or      = bitwise_xor { "|" bitwise_xor }
bitwise_xor     = bitwise_and { "^" bitwise_and }
bitwise_and     = equality { "&" equality }
equality        = comparison { ( "==" | "!=" ) comparison }
comparison      = shift { ( "<" | ">" | "<=" | ">=" ) shift }
shift           = additive { ( "<<" | ">>" ) additive }
additive        = multiplicative { ( "+" | "-" ) multiplicative }
multiplicative  = unary { ( "*" | "/" | "%" ) unary }

unary           = ( "!" | "-" | "~" | "*" | "&" ) unary | postfix
postfix         = primary { "[" expression "]" | "." identifier | "(" args ")" }
args            = [ expression { "," expression } ]

primary         = number | string_literal | char_literal | identifier
                | "true" | "false" | "(" expression ")"
                | struct_literal | array_literal
                | "sizeof" "(" type ")"
                | "alloc" "(" expression ")"
                | "free" "(" expression ")"

struct_literal  = identifier "{" field_inits "}"
field_inits     = field_init { "," field_init }
field_init      = identifier ":" expression

array_literal   = "[" [ expression { "," expression } ] "]"

type            = primitive_type | pointer_type | array_type | identifier
primitive_type  = "i8" | "i16" | "i32" | "i64" | "u8" | "u16" | "u32" | "u64"
                | "f32" | "f64" | "bool" | "char" | "ptr"
pointer_type    = "*" type
array_type      = "[" type ";" expression "]"

identifier      = letter { letter | digit | "_" }
number          = digit { digit } [ "." digit { digit } ]
string_literal  = '"' { any_char } '"'
char_literal    = "'" any_char "'"
```

## Error Handling

Flash uses explicit error codes rather than exceptions:

```
// Return error codes
fn divide(a: i32, b: i32) -> i32 {
    if b == 0 {
        return -1;  // Error code
    }
    return a / b;
}

// Check return values
let result: i32 = divide(10, 0);
if result == -1 {
    io.print("Error: division by zero\n");
}
```

## Type Safety Notes

- No null pointer checking (crashes on null dereference)
- No array bounds checking (undefined behavior on out-of-bounds)
- No integer overflow checking (wraps around)
- Programmer must ensure memory safety
- Use of uninitialized variables is undefined behavior

## Compilation Flags

```
flash build program.fl                    // Default build
flash build program.fl -O0                // No optimization
flash build program.fl -O1                // Basic optimization
flash build program.fl -O2                // Standard optimization
flash build program.fl -O3                // Aggressive optimization
flash build program.fl -o output          // Specify output name
flash build program.fl --release          // Release mode (O3 + strip)
flash build program.fl --debug            // Include debug symbols
flash build program.fl --target x86_64    // Target architecture
```

## Reserved for Future Use

The following features may be added in future versions:

- Generic types/functions
- Function pointers
- Union types
- Packed structs
- Bit fields
- Const generics
- Compile-time function execution
- SIMD intrinsics

## Implementation Notes

- Single-pass compilation where possible
- Direct machine code generation (no LLVM dependency initially)
- Minimal binary size
- Fast compile times (target: < 1 second for 10k lines)
- Explicit memory layout control
