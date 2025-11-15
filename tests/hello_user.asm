; Simple user program to test stdlib I/O
bits 64
default rel

section .data
hello_str: db 'Hello, Phase9!', 0

section .text
global main
extern print_str
extern print_newline

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    lea rcx, [rel hello_str]
    call print_str
    call print_newline

    mov rax, 0
    add rsp, 32
    pop rbp
    ret
