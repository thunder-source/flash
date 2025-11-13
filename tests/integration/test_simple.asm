; Simple single test
bits 64
default rel

extern lexer_init
extern parser_init
extern parser_parse
extern arena_init
extern arena_reset
extern ExitProcess
extern GetStdHandle
extern WriteFile

%define STD_OUTPUT_HANDLE -11
%define AST_PROGRAM 0

section .data
    test_name db "Test 1", 0
    test_src db "fn main() -> i32 { return 0; }", 0
    
    msg_header db "=== Simple Test ===", 13, 10, 0
    msg_testing db "Testing: ", 0
    msg_passed db " [PASS]", 13, 10, 0
    msg_failed db " [FAIL]", 13, 10, 0
    newline db 13, 10, 0
    bytes_written dd 0

section .bss
    stdout resq 1
    lexer_ptr resq 1
    parser_ptr resq 1

section .text
global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Get stdout
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout], rax
    
    ; Header
    lea rcx, [msg_header]
    call print_str
    
    ; Init arena
    xor rcx, rcx
    call arena_init
    
    ; Print test name
    lea rcx, [msg_testing]
    call print_str
    lea rcx, [test_name]
    call print_str
    lea rcx, [newline]
    call print_str
    
    ; Init lexer
    lea rcx, [test_src]
    call lexer_init
    mov [lexer_ptr], rax
    
    ; Init parser
    mov rcx, [lexer_ptr]
    call parser_init
    mov [parser_ptr], rax
    
    ; Parse
    mov rcx, [parser_ptr]
    call parser_parse
    test rax, rax
    jz .fail
    
    ; Check AST
    mov rdx, [rax]
    cmp rdx, AST_PROGRAM
    jne .fail
    
    ; Pass
    lea rcx, [msg_passed]
    call print_str
    xor rcx, rcx
    call ExitProcess
    
.fail:
    lea rcx, [msg_failed]
    call print_str
    mov rcx, 1
    call ExitProcess

print_str:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    
    mov r12, rcx
    xor rbx, rbx
    
.len:
    cmp byte [r12 + rbx], 0
    je .write
    inc rbx
    jmp .len
    
.write:
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
