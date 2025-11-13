; Simple debug test
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

section .data
    test_src db "fn main() -> i32 { return 0; }", 0
    msg_start db "Starting test...", 13, 10, 0
    msg_arena db "Initializing arena...", 13, 10, 0
    msg_lexer db "Initializing lexer...", 13, 10, 0
    msg_parser db "Initializing parser...", 13, 10, 0
    msg_parse db "Parsing...", 13, 10, 0
    msg_success db "SUCCESS!", 13, 10, 0
    msg_fail db "FAILED!", 13, 10, 0
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
    
    ; Print start
    lea rcx, [msg_start]
    call print_msg
    
    ; Init arena
    lea rcx, [msg_arena]
    call print_msg
    xor rcx, rcx
    call arena_init
    test rax, rax
    jz .fail
    
    ; Init lexer
    lea rcx, [msg_lexer]
    call print_msg
    lea rcx, [test_src]
    call lexer_init
    mov [lexer_ptr], rax
    
    ; Init parser
    lea rcx, [msg_parser]
    call print_msg
    mov rcx, [lexer_ptr]
    call parser_init
    mov [parser_ptr], rax
    
    ; Parse
    lea rcx, [msg_parse]
    call print_msg
    mov rcx, [parser_ptr]
    call parser_parse
    test rax, rax
    jz .fail
    
    ; Success
    lea rcx, [msg_success]
    call print_msg
    xor rcx, rcx
    call ExitProcess
    
.fail:
    lea rcx, [msg_fail]
    call print_msg
    mov rcx, 1
    call ExitProcess

print_msg:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    
    mov r12, rcx
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
