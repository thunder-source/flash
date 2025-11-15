; Test the runtime library
bits 64
default rel

extern print_int
extern print_str
extern print_newline

section .data
    msg1 db "Testing runtime library...", 0
    msg2 db "Print int: ", 0
    msg3 db "Print string: Hello from Flash!", 0
    msg4 db "All tests complete!", 0

section .text
global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Test 1: Print string
    lea rcx, [msg1]
    call print_str
    call print_newline
    
    ; Test 2: Print integer
    lea rcx, [msg2]
    call print_str
    mov rcx, 42
    call print_int
    call print_newline
    
    ; Test 3: Print negative integer
    lea rcx, [msg2]
    call print_str
    mov rcx, -123
    call print_int
    call print_newline
    
    ; Test 4: Another string
    lea rcx, [msg3]
    call print_str
    call print_newline
    
    ; Test 5: Done
    lea rcx, [msg4]
    call print_str
    call print_newline
    
    ; Return 0
    xor rax, rax
    add rsp, 32
    pop rbp
    ret
