; ============================================================================
; Comprehensive Test Program for Flash Compiler
; Tests lexer and parser with multiple sample programs
; ============================================================================

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

%define AST_PROGRAM         0
%define AST_FUNCTION        1
%define AST_STRUCT_DEF      2
%define AST_BLOCK           20
%define AST_LET_STMT        21
%define AST_ASSIGN_STMT     22
%define AST_IF_STMT         23
%define AST_WHILE_STMT      24
%define AST_FOR_STMT        25
%define AST_RETURN_STMT     26
%define AST_BREAK_STMT      27
%define AST_CONTINUE_STMT   28
%define AST_EXPR_STMT       29
%define AST_BINARY_EXPR     50
%define AST_UNARY_EXPR      51
%define AST_LITERAL_EXPR    52
%define AST_IDENTIFIER      53

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
    newline db 13, 10, 0
    msg_starting db "Flash Compiler - Comprehensive Parser Test", 13, 10, 0
    msg_init db "Initializing...", 13, 10, 0
    msg_testing db "Testing: ", 0
    msg_passed db "[PASS] ", 0
    msg_failed db "[FAIL] ", 0
    msg_ast_type db "AST Root Type: ", 0
    msg_parsing db "Parsing... ", 0
    msg_summary db 13, 10, "Test Summary:", 13, 10, 0
    msg_total db "Total Tests: ", 0
    msg_pass db "Passed: ", 0
    msg_fail db "Failed: ", 0
    msg_done db 13, 10, "Testing complete!", 13, 10, 0
    msg_error db 13, 10, "ERROR: Test initialization failed!", 13, 10, 0
    msg_press_key db 13, 10, "Press Ctrl+C to exit...", 13, 10, 0
    
    ; Test table
    test_table:
        dq test1_name, test1_src
        dq test2_name, test2_src
        dq test3_name, test3_src
        dq test4_name, test4_src
        dq test5_name, test5_src
        dq test6_name, test6_src
        dq test7_name, test7_src
        dq test8_name, test8_src
        dq 0, 0  ; End marker
    
    test_count dq 8
    
    bytes_written dd 0

section .bss
    stdout resq 1
    lexer_ptr resq 1
    parser_ptr resq 1
    ast_root resq 1
    passed_count resq 1
    failed_count resq 1
    buffer resb 256

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
    
    ; Print header
    lea rcx, [separator]
    call print_cstring
    lea rcx, [msg_starting]
    call print_cstring
    lea rcx, [separator]
    call print_cstring
    lea rcx, [newline]
    call print_cstring
    
    ; Initialize arena allocator
    lea rcx, [msg_init]
    call print_cstring
    
    xor rcx, rcx
    call arena_init
    test rax, rax
    jz .error
    
    ; Initialize counters
    mov qword [passed_count], 0
    mov qword [failed_count], 0
    
    ; Run tests
    lea rbx, [test_table]
    
.test_loop:
    mov rax, [rbx]
    test rax, rax
    jz .done_testing
    
    ; Save rbx before call (in case it gets clobbered)
    push rbx
    
    mov rcx, [rbx]      ; Test name
    mov rdx, [rbx + 8]  ; Test source
    call run_test
    
    ; Restore rbx
    pop rbx
    
    add rbx, 16
    jmp .test_loop
    
.done_testing:
    ; Print summary
    lea rcx, [separator]
    call print_cstring
    lea rcx, [msg_summary]
    call print_cstring
    
    lea rcx, [msg_total]
    call print_cstring
    mov rax, [test_count]
    call print_number
    lea rcx, [newline]
    call print_cstring
    
    lea rcx, [msg_pass]
    call print_cstring
    mov rax, [passed_count]
    call print_number
    lea rcx, [newline]
    call print_cstring
    
    lea rcx, [msg_fail]
    call print_cstring
    mov rax, [failed_count]
    call print_number
    lea rcx, [newline]
    call print_cstring
    
    lea rcx, [separator]
    call print_cstring
    lea rcx, [msg_done]
    call print_cstring
    
    ; Pause before exit
    lea rcx, [msg_press_key]
    call print_cstring
    
    xor rcx, rcx
    call ExitProcess
    
.error:
    lea rcx, [msg_error]
    call print_cstring
    
    ; Pause before exit
    lea rcx, [msg_press_key]
    call print_cstring
    
    mov rcx, 1
    call ExitProcess

; ============================================================================
; run_test - Run a single test
; Parameters:
;   RCX = test name pointer
;   RDX = test source pointer
; ============================================================================
run_test:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    
    ; Save parameters in local variables first
    mov [rbp - 8], rcx   ; Test name
    mov [rbp - 16], rdx  ; Test source
    
    ; Print test name
    lea rcx, [msg_testing]
    call print_cstring
    
    mov rcx, [rbp - 8]  ; Reload test name
    call print_cstring
    
    lea rcx, [newline]
    call print_cstring
    
    ; Now save in non-volatile registers
    mov r12, [rbp - 8]   ; Test name
    mov r13, [rbp - 16]  ; Test source
    
    ; Reset arena for new test
    call arena_reset
    
    ; Initialize lexer
    mov rcx, r13
    call lexer_init
    mov [lexer_ptr], rax
    
    ; Initialize parser
    mov rcx, [lexer_ptr]
    call parser_init
    mov [parser_ptr], rax
    
    ; Parse
    lea rcx, [msg_parsing]
    call print_cstring
    
    mov rcx, [parser_ptr]
    call parser_parse
    test rax, rax
    jz .test_failed
    
    mov [ast_root], rax
    
    ; Verify AST root is program node
    mov rdx, [rax]
    cmp rdx, AST_PROGRAM
    jne .test_failed
    
    ; Test passed
    lea rcx, [msg_passed]
    call print_cstring
    mov rcx, r12
    call print_cstring
    lea rcx, [newline]
    call print_cstring
    
    inc qword [passed_count]
    jmp .test_done
    
.test_failed:
    lea rcx, [msg_failed]
    call print_cstring
    mov rcx, r12
    call print_cstring
    lea rcx, [newline]
    call print_cstring
    
    inc qword [failed_count]
    
.test_done:
    lea rcx, [newline]
    call print_cstring
    
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

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

; ============================================================================
; print_number - Print a number to stdout
; Parameters:
;   RAX = number to print
; ============================================================================
print_number:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    
    mov r12, rax
    lea rbx, [buffer + 255]
    mov byte [rbx], 0
    dec rbx
    
    test r12, r12
    jnz .convert
    
    mov byte [rbx], '0'
    jmp .print
    
.convert:
    mov rax, r12
    mov rcx, 10
    
.loop:
    test rax, rax
    jz .print
    
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov [rbx], dl
    dec rbx
    jmp .loop
    
.print:
    inc rbx
    mov rcx, rbx
    lea rax, [buffer + 256]
    sub rax, rbx
    mov rdx, rax
    call print_string
    
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; print_string - Print a string to stdout
; Parameters:
;   RCX = pointer to string
;   RDX = length
; ============================================================================
print_string:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    mov r8, rdx
    mov rdx, rcx
    mov rcx, [stdout]
    lea r9, [bytes_written]
    xor rax, rax
    mov [rsp + 32], rax
    call WriteFile
    
    add rsp, 32
    pop rbp
    ret
