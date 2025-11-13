bits 64
default rel

extern ExitProcess

section .text
global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32         ; Shadow space for Windows x64
    
    xor rcx, rcx
    call ExitProcess
    
    add rsp, 32
    pop rbp
    ret
