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
// Mutable by default
let x: i32 = 10;

// Immutable variables
const y: i32 = 20;
y = 30;

// Type inference
let z = 15;  // inferred as i32
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
// If statement
if (x > 0) {
    // code
} else if (x < 0) {
    // code
} else {
    // code
}

// While loop
while (x < 10) {
    x = x + 1;
}

// For loop (range-based)
for (i in 0..10) {
    // code
}

// Break and continue
while (true) {
    if (condition) {
        break;
    }
    if (other_condition) {
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
```

### Pointers and References

```
// Get address
let ptr: *i32 = &x;

// Dereference
let value: i32 = *ptr;

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
let x_val = p.x;
```

### Arrays

```
// Fixed-size arrays
let arr: [i32; 5] = [1, 2, 3, 4, 5];

// Array indexing
let first = arr[0];

// Array size
let size = arr.len;
```

### Memory Management

```
// Explicit allocation (calls system allocator)
let ptr: *i32 = alloc(sizeof(i32));

// Explicit deallocation
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
```

## Keywords

```
fn          // Function definition
let         // Variable declaration (Mutable)
const         // Variable declaration (immutable)
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
cconst       // Compile-time constant
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
// Import external module
import io;
import math;
import temp from "path";
import { temp } from "path";

// Use imported functions
io.print("Hello");
let result = math.sqrt(16.0);

// Export symbols for other modules
export fn public_function() {
    // code
}
```

## Compile-Time Constants

```
cconst MAX_SIZE: i32 = 1024;
cconst PI: f64 = 3.14159265359;

// Used like regular variables but evaluated at compile time
let buffer: [u8; MAX_SIZE];
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
    let result = fibonacci(10);
}
```

### Array Sum

```
fn sum_array(arr: *i32, len: i32) -> i32 {
    mut total: i32 = 0;
    for i in 0..len {
        total = total + arr[i];
    }
    return total;
}

fn main() {
    let numbers: [i32; 5] = [1, 2, 3, 4, 5];
    let sum = sum_array(&numbers[0], 5);
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

## Calling Conventions

### x86-64 (System V AMD64 ABI)

- First 6 integer args: RDI, RSI, RDX, RCX, R8, R9
- First 8 float args: XMM0-XMM7
- Return value: RAX (integer), XMM0 (float)
- Stack aligned to 16 bytes

### Windows x64

- First 4 args: RCX, RDX, R8, R9
- Return value: RAX
- Stack aligned to 16 bytes

## Memory Model

- Stack grows downward
- Heap managed by explicit alloc/free
- No automatic memory management
- Programmer responsible for all memory

## Standard Library (Minimal)

```
// io module
io.print(str)       // Print string
io.read()           // Read input
io.open(path)       // Open file
io.close(fd)        // Close file

// math module
math.sqrt(x)        // Square root
math.pow(x, y)      // Power
math.abs(x)         // Absolute value

// memory module
mem.copy(dest, src, size)   // Memory copy
mem.set(dest, val, size)    // Memory set
mem.cmp(a, b, size)         // Memory compare

// string module
str.len(s)          // String length
str.cmp(a, b)       // String compare
str.copy(dest, src) // String copy
```

## Grammar (EBNF-like)

```
program         = { import_stmt | function_def | struct_def | enum_def }
import_stmt     = "import" identifier ";"
function_def    = [ "inline" ] "fn" identifier "(" params ")" [ "->" type ] block
params          = [ param { "," param } ]
param           = identifier ":" type
block           = "{" { statement } "}"
statement       = let_stmt | assignment | if_stmt | while_stmt | for_stmt | return_stmt | expr_stmt
let_stmt        = "let" [ "mut" ] identifier ":" type "=" expression ";"
assignment      = identifier "=" expression ";"
if_stmt         = "if" expression block [ "else" ( if_stmt | block ) ]
while_stmt      = "while" expression block
for_stmt        = "for" identifier "in" expression ".." expression block
return_stmt     = "return" [ expression ] ";"
expr_stmt       = expression ";"
expression      = binary_expr | unary_expr | primary
binary_expr     = expression binary_op expression
unary_expr      = unary_op expression
primary         = number | string | identifier | "(" expression ")" | function_call | array_access
function_call   = identifier "(" [ expression { "," expression } ] ")"
array_access    = identifier "[" expression "]"
type            = primitive_type | pointer_type | array_type | identifier
pointer_type    = "*" type
array_type      = "[" type ";" number "]"
```

## Next Steps

1. Finalize any missing details in specification
2. Create example programs to test language design
3. Begin implementing lexer for this syntax
4. Design internal representation for AST
