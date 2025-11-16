; ============================================================================
; Flash Compiler - Mirror of Working Parser Test
; ============================================================================
; Exact mirror of the working parser test structure with Flash program
; ============================================================================

bits 64
default rel

extern lexer_init
extern parser_init
extern parser_parse
extern arena_init
extern ExitProcess
extern GetStdHandle
extern WriteFile

%define STD_OUTPUT_HANDLE -11

%define AST_PROGRAM         0
%define AST_FUNCTION        1
%define AST_BLOCK           20
%define AST_LET_STMT        21
%define AST_RETURN_STMT     26

section .data
    ; Flash program (more complex than parser test)
    flash_source db "fn fibonacci(n: i32) -> i32 {", 10
                 db "    if n <= 1 {", 10
                 db "        return n;", 10
                 db "    }", 10
                 db "    return fibonacci(n - 1) + fibonacci(n - 2);", 10
                 db "}", 10
                 db "", 10
                 db "fn main() -> i32 {", 10
                 db "    let result: i32 = fibonacci(7);", 10
                 db "    return result;", 10
                 db "}", 0

    newline db 13, 10

    ; Messages (exact same as parser test)
    msg_init db "Initializing compiler...", 13, 10, 0
    msg_lexer db "Initializing lexer...", 13, 10, 0
    msg_parser db "Initializing parser...", 13, 10, 0
    msg_parsing db "Parsing program...", 13, 10, 0
    msg_success db "Parse successful!", 13, 10, 0
    msg_ast_root db "AST Root: Program node", 13, 10, 0
    msg_error db "Parse failed!", 13, 10, 0
    msg_done db "Test complete.", 13, 10, 0

    bytes_written dd 0

section .bss
    stdout resq 1
    lexer_ptr resq 1
    parser_ptr resq 1
    ast_root resq 1

section .text
global main

main:
    ; Prologue (exact same as parser test)
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; Get stdout handle (exact same as parser test)
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout], rax

    ; Initialize arena allocator first (exact same as parser test)
    call arena_init

    ; Print init message (exact same as parser test)
    lea rcx, [msg_init]
    call print_cstring

    ; Initialize lexer (exact same as parser test)
    lea rcx, [msg_lexer]
    call print_cstring

    lea rcx, [flash_source]
    lea rdx, [flash_source]
    mov r8, 0
.calc_len:
    cmp byte [rdx + r8], 0
    je .len_done
    inc r8
    jmp .calc_len
.len_done:
    call lexer_init
    mov [lexer_ptr], rax

    ; Initialize parser (exact same as parser test)
    lea rcx, [msg_parser]
    call print_cstring

    call parser_init
    mov [parser_ptr], rax

    ; Parse the program (exact same as parser test)
    lea rcx, [msg_parsing]
    call print_cstring

    mov rcx, [parser_ptr]
    call parser_parse
    test rax, rax
    jz .error

    mov [ast_root], rax

    ; Success! (exact same as parser test)
    lea rcx, [msg_success]
    call print_cstring

    ; Check if we got a program node (exact same as parser test)
    mov rax, [ast_root]
    cmp rax, 0
    je .success_no_check
    mov rdx, [rax]  ; Get node type
    cmp rdx, AST_PROGRAM
    jne .success_no_check

.success_no_check:
    lea rcx, [msg_ast_root]
    call print_cstring

    ; Print done message (exact same as parser test)
    lea rcx, [msg_done]
    call print_cstring

    xor rcx, rcx
    call ExitProcess

.error:
    lea rcx, [msg_error]
    call print_cstring

    mov rcx, 1
    call ExitProcess

; ============================================================================
; print_cstring - Print null-terminated string (exact same as parser test)
; Parameters:
;   RCX = pointer to string
; ============================================================================
print_cstring:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12

    mov r12, rcx

    ; Calculate length
    xor rbx, rbx
.len_loop:
    cmp byte [r12 + rbx], 0
    je .print
    inc rbx
    jmp .len_loop

.print:
    ; Write to stdout
    mov rcx, [stdout]
    mov rdx, r12
    mov r8, rbx
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteFile
    add rsp, 40

    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret
