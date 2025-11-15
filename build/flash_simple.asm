; Simple Flash Compiler Stub 
; Tests build system without dependencies 
 
bits 64 
default rel 
 
extern ExitProcess 
extern GetStdHandle 
extern WriteConsoleA 
 
section .data 
    msg db 'Flash Compiler v0.2.0 - Build System Working!', 0dh, 0ah, 0 
    msg_len equ $ - msg 
 
section .bss 
    bytes_written resq 1 
 
section .text 
global main 
 
main: 
    push rbp 
    mov rbp, rsp 
    sub rsp, 32 
 
    ; Get stdout handle 
    mov rcx, -11 
    call GetStdHandle 
 
    ; Print message 
    mov rcx, rax 
    lea rdx, [msg] 
    mov r8, msg_len 
    lea r9, [bytes_written] 
    push 0 
    sub rsp, 32 
    call WriteConsoleA 
    add rsp, 40 
 
    ; Exit 
    mov rsp, rbp 
    pop rbp 
    xor rcx, rcx 
    call ExitProcess 
