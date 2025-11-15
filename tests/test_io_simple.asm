; Minimal I/O test - no runtime, just test I/O functions
bits 64
default rel

extern GetStdHandle
extern WriteFile
extern ExitProcess

%define STD_OUTPUT_HANDLE -11

section .data
    msg1 db "Test 1: Direct WriteFile", 13, 10, 0
    msg2 db "Test 2: Print 42 = ", 0
    msg3 db "42", 13, 10, 0

section .bss
    stdout_handle resq 1
    bytes_written resq 1

section .text
global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    ; Get stdout
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout_handle], rax
    
    ; Test 1: Direct write
    mov rcx, rax
    lea rdx, [msg1]
    mov r8, 26
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0
    call WriteFile
    
    ; Test 2: Print message
    mov rcx, [stdout_handle]
    lea rdx, [msg2]
    mov r8, 20
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0
    call WriteFile
    
    ; Test 3: Print number
    mov rcx, [stdout_handle]
    lea rdx, [msg3]
    mov r8, 4
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0
    call WriteFile
    
    ; Exit cleanly
    xor eax, eax
    add rsp, 48
    pop rbp
    ret
