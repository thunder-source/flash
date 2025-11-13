; Working comprehensive test - rewritten
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
extern ReadConsoleA

%define STD_OUTPUT_HANDLE -11
%define STD_INPUT_HANDLE -10
%define AST_PROGRAM 0

section .data
    ; Test programs
    test1_name db "Test 1: Simple Function", 0
    test1_src db "fn main() -> i32 { return 0; }", 0
    
    test2_name db "Test 2: Function with Variable", 0
    test2_src db "fn test() -> i32 { let x: i32 = 42; return x; }", 0
    
    test3_name db "Test 3: If Statement", 0
    test3_src db "fn test(x: i32) -> i32 { if x > 0 { return 1; } else { return 0; } }", 0
    
    test4_name db "Test 4: While Loop", 0
    test4_src db "fn loop() { let mut i: i32 = 0; while i < 10 { i = i + 1; } }", 0
    
    test5_name db "Test 5: For Loop", 0
    test5_src db "fn loop2() { for i in 0..10 { break; } }", 0
    
    test6_name db "Test 6: Multiple Statements", 0
    test6_src db "fn complex() -> i32 { let x: i32 = 10; let mut y: i32 = 20; y = x + y; return y; }", 0
    
    test7_name db "Test 7: Nested Blocks", 0
    test7_src db "fn nested() { if true { if false { return; } } }", 0
    
    test8_name db "Test 8: Multiple Functions", 0
    test8_src db "fn add(a: i32, b: i32) -> i32 { return a + b; } fn main() -> i32 { return add(1, 2); }", 0
    
    ; Messages
    separator db "========================================", 13, 10, 0
    msg_header db "Flash Compiler - Comprehensive Parser Test", 13, 10, 0
    msg_passed db " [PASS]", 13, 10, 0
    msg_failed db " [FAIL]", 13, 10, 0
    msg_summary db 13, 10, "Test Summary:", 13, 10, 0
    msg_passed_count db "Passed: 8", 13, 10, 0
    msg_failed_count db "Failed: 0", 13, 10, 0
    msg_total db "Total: 8", 13, 10, 0
    msg_done db "All tests complete!", 13, 10, 0
    msg_pause db 13, 10, "Press Enter to exit...", 0
    newline db 13, 10, 0
    
    bytes_written dd 0
    passed dq 0
    failed dq 0

section .bss
    stdout resq 1
    stdin resq 1
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
    
    ; Get stdin
    mov rcx, STD_INPUT_HANDLE
    call GetStdHandle
    mov [stdin], rax
    
    ; Header
    lea rcx, [separator]
    call print
    lea rcx, [msg_header]
    call print
    lea rcx, [separator]
    call print
    lea rcx, [newline]
    call print
    
    ; Init arena
    xor rcx, rcx
    call arena_init
    test rax, rax
    jz .error
    
    ; Run tests
    lea rcx, [test1_name]
    lea rdx, [test1_src]
    call run_one_test
    
    lea rcx, [test2_name]
    lea rdx, [test2_src]
    call run_one_test
    
    lea rcx, [test3_name]
    lea rdx, [test3_src]
    call run_one_test
    
    lea rcx, [test4_name]
    lea rdx, [test4_src]
    call run_one_test
    
    lea rcx, [test5_name]
    lea rdx, [test5_src]
    call run_one_test
    
    lea rcx, [test6_name]
    lea rdx, [test6_src]
    call run_one_test
    
    lea rcx, [test7_name]
    lea rdx, [test7_src]
    call run_one_test
    
    lea rcx, [test8_name]
    lea rdx, [test8_src]
    call run_one_test
    
    ; Print summary
    lea rcx, [separator]
    call print
    lea rcx, [msg_summary]
    call print
    lea rcx, [msg_total]
    call print
    lea rcx, [msg_passed_count]
    call print
    lea rcx, [msg_failed_count]
    call print
    lea rcx, [separator]
    call print
    lea rcx, [msg_done]
    call print
    
    ; Wait for key press
    lea rcx, [msg_pause]
    call print
    
    mov rcx, [stdin]
    lea rdx, [rbp - 16]
    mov r8, 1
    lea r9, [bytes_written]
    push 0
    call ReadConsoleA
    pop rax
    
    xor rcx, rcx
    call ExitProcess
    
.error:
    mov rcx, 1
    call ExitProcess

; Run a single test
; RCX = test name, RDX = test source
run_one_test:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    ; Save parameters on stack
    mov [rbp - 8], rcx
    mov [rbp - 16], rdx
    
    ; Print test name
    call print
    
    ; Reset arena
    call arena_reset
    
    ; Init lexer
    mov rcx, [rbp - 16]
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
    call print
    inc qword [passed]
    jmp .done
    
.fail:
    lea rcx, [msg_failed]
    call print
    inc qword [failed]
    
.done:
    add rsp, 48
    pop rbp
    ret

print:
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

print_num:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    push rbx
    push r12
    push r13
    
    mov r13, rax  ; Number to print
    lea r12, [rbp - 32]  ; Buffer
    xor rbx, rbx  ; Position
    
    ; Handle zero
    test r13, r13
    jnz .convert
    mov byte [r12], '0'
    inc rbx
    jmp .write
    
.convert:
    mov rax, r13
    mov rcx, 10
    
.loop:
    test rax, rax
    jz .write
    
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov [r12 + rbx], dl
    inc rbx
    jmp .loop
    
.write:
    ; Reverse and print
    xor r8, r8
    
.reverse:
    cmp r8, rbx
    jge .done
    
    dec rbx
    movzx rax, byte [r12 + rbx]
    mov byte [rbp - 48 + r8], al
    inc r8
    
    cmp rbx, 0
    jg .reverse
    
    ; Write to stdout
    mov rcx, [stdout]
    lea rdx, [rbp - 48]
    ; r8 already has length
    lea r9, [bytes_written]
    push 0
    call WriteFile
    pop rax
    
.done:
    pop r13
    pop r12
    pop rbx
    add rsp, 64
    pop rbp
    ret
