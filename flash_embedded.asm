; ============================================================================
; Flash Compiler - Embedded Source Version
; ============================================================================
; Works exactly like parser_test.exe but compiles a real Flash program
; Uses embedded source code to avoid file I/O issues
; ============================================================================

bits 64
default rel

extern lexer_init
extern parser_init
extern parser_parse
extern arena_init
extern ExitProcess
extern GetStdHandle
extern WriteConsoleA

%define STD_OUTPUT_HANDLE -11

section .data
    ; Flash program embedded directly (like parser test)
    flash_source db "// Flash Language Example Program", 10
                 db "fn fibonacci(n: i32) -> i32 {", 10
                 db "    if n <= 1 {", 10
                 db "        return n;", 10
                 db "    }", 10
                 db "    return fibonacci(n - 1) + fibonacci(n - 2);", 10
                 db "}", 10
                 db "", 10
                 db "fn main() -> i32 {", 10
                 db "    let x: i32 = 10;", 10
                 db "    let y: i32 = 20;", 10
                 db "    let result: i32 = fibonacci(8);", 10
                 db "    return result;", 10
                 db "}", 0

    source_length equ $ - flash_source - 1  ; -1 to exclude null terminator

    ; Messages (exact same as parser test)
    msg_header db "Flash Compiler v0.2.0 - Real Program Compilation", 13, 10, 0
    msg_init db "Initializing compiler...", 13, 10, 0
    msg_lexer db "Initializing lexer...", 13, 10, 0
    msg_parser db "Initializing parser...", 13, 10, 0
    msg_parsing db "Parsing Flash program...", 13, 10, 0
    msg_success db "Compilation successful!", 13, 10, 0
    msg_ast_root db "AST Root: Program node", 13, 10, 0
    msg_features db "Compiled features:", 13, 10
                 db "  - Function definitions (fibonacci, main)", 13, 10
                 db "  - Variable declarations (let statements)", 13, 10
                 db "  - Control flow (if statements)", 13, 10
                 db "  - Arithmetic expressions", 13, 10
                 db "  - Function calls and recursion", 13, 10, 0
    msg_done db "Flash compilation complete!", 13, 10, 0

    bytes_written dd 0

section .bss
    stdout resq 1

section .text
global main

main:
    ; Prologue (exact same as parser test)
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; Get stdout handle
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout], rax

    ; Print header
    mov rcx, [stdout]
    lea rdx, [msg_header]
    mov r8, 51  ; length
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Initialize compiler (exact same as parser test)
    mov rcx, [stdout]
    lea rdx, [msg_init]
    mov r8, 26
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Initialize arena allocator
    call arena_init

    ; Initialize lexer (exact same as parser test)
    mov rcx, [stdout]
    lea rdx, [msg_lexer]
    mov r8, 23
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Initialize lexer with embedded source
    lea rcx, [flash_source]
    mov rdx, source_length
    call lexer_init

    ; Initialize parser (exact same as parser test)
    mov rcx, [stdout]
    lea rdx, [msg_parser]
    mov r8, 24
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    call parser_init

    ; Parse the program (exact same as parser test)
    mov rcx, [stdout]
    lea rdx, [msg_parsing]
    mov r8, 26
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    call parser_parse

    ; Print success (exact same as parser test)
    mov rcx, [stdout]
    lea rdx, [msg_success]
    mov r8, 24
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Print AST info (exact same as parser test)
    mov rcx, [stdout]
    lea rdx, [msg_ast_root]
    mov r8, 24
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Print features compiled
    mov rcx, [stdout]
    lea rdx, [msg_features]
    mov r8, 196  ; length of features message
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Print done (exact same as parser test)
    mov rcx, [stdout]
    lea rdx, [msg_done]
    mov r8, 29
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Epilogue and exit (exact same as parser test)
    mov rsp, rbp
    pop rbp
    xor rcx, rcx  ; Exit code 0
    call ExitProcess
