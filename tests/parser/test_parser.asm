; ============================================================================
; Test program for Flash Compiler Parser
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
    ; Simple test program
    test_source db "fn main() -> i32 {", 10
                db "    let x: i32 = 42;", 10
                db "    return x;", 10
                db "}", 0
    
    newline db 13, 10
    
    ; Messages
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
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Get stdout handle
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout], rax
    
    ; Print init message
    lea rcx, [msg_init]
    call print_cstring
    
    ; Initialize arena allocator
    xor rcx, rcx  ; Use default size
    call arena_init
    test rax, rax
    jz .error
    
    ; Initialize lexer
    lea rcx, [msg_lexer]
    call print_cstring
    
    lea rcx, [test_source]
    call lexer_init
    mov [lexer_ptr], rax
    
    ; Initialize parser
    lea rcx, [msg_parser]
    call print_cstring
    
    mov rcx, [lexer_ptr]
    call parser_init
    mov [parser_ptr], rax
    
    ; Parse the program
    lea rcx, [msg_parsing]
    call print_cstring
    
    mov rcx, [parser_ptr]
    call parser_parse
    test rax, rax
    jz .error
    
    mov [ast_root], rax
    
    ; Success!
    lea rcx, [msg_success]
    call print_cstring
    
    ; Check if we got a program node
    mov rax, [ast_root]
    mov rdx, [rax]  ; Get node type
    cmp rdx, AST_PROGRAM
    jne .error
    
    lea rcx, [msg_ast_root]
    call print_cstring
    
    ; Print done message
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
; print_cstring - Print null-terminated string
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
    test rbx, rbx
    jz .done
    
    mov rcx, [stdout]
    mov rdx, r12
    mov r8, rbx
    lea r9, [bytes_written]
    xor rax, rax
    mov [rsp + 32], rax
    call WriteFile
    
.done:
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret
