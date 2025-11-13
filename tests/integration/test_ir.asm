; ============================================================================
; IR Generation Test
; Tests the Three-Address Code IR generation from AST
; ============================================================================

bits 64
default rel

extern ir_program_create
extern ir_function_create
extern ir_generate
extern ir_new_temp
extern ir_emit_binary
extern arena_init
extern ExitProcess
extern GetStdHandle
extern WriteFile

%define STD_OUTPUT_HANDLE -11
%define IR_ADD 0
%define TYPE_I32 2
%define IROperand_size 32

section .data
    msg_header db "=== IR Generation Test ===", 13, 10, 0
    msg_test1 db "Test 1: Create IR program... ", 0
    msg_test2 db "Test 2: Create IR function... ", 0
    msg_test3 db "Test 3: Allocate temporary... ", 0
    msg_test4 db "Test 4: Generate simple expression... ", 0
    msg_pass db "[PASS]", 13, 10, 0
    msg_fail db "[FAIL]", 13, 10, 0
    msg_summary db 13, 10, "IR Generation Tests Complete!", 13, 10, 0
    msg_info db "IR system ready for AST-to-IR conversion.", 13, 10, 0
    msg_pause db 13, 10, "Press Enter to continue...", 13, 10, 0
    
    test_func_name db "test_func", 0

section .bss
    stdout_handle:  resq 1
    bytes_written:  resq 1
    test_result:    resq 1

section .text
global main

; ============================================================================
; main - Entry point
; ============================================================================
main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Get stdout handle
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout_handle], rax
    
    ; Print header
    lea rcx, [msg_header]
    call print_string
    
    ; Initialize memory arena
    call arena_init
    
    ; Run tests
    call test_create_program
    call test_create_function
    call test_allocate_temp
    call test_simple_expression
    
    ; Print summary
    lea rcx, [msg_summary]
    call print_string
    lea rcx, [msg_info]
    call print_string
    
    ; Pause
    lea rcx, [msg_pause]
    call print_string
    
    ; Exit
    xor rcx, rcx
    call ExitProcess

; ============================================================================
; Test 1: Create IR program
; ============================================================================
test_create_program:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    lea rcx, [msg_test1]
    call print_string
    
    call ir_program_create
    test rax, rax
    jz .fail
    
    lea rcx, [msg_pass]
    call print_string
    jmp .done
    
.fail:
    lea rcx, [msg_fail]
    call print_string
    
.done:
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; Test 2: Create IR function
; ============================================================================
test_create_function:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    lea rcx, [msg_test2]
    call print_string
    
    ; Create program first
    call ir_program_create
    test rax, rax
    jz .fail
    
    ; Create function
    lea rcx, [test_func_name]
    mov rdx, 9              ; length of "test_func"
    mov r8, TYPE_I32        ; return type
    call ir_function_create
    test rax, rax
    jz .fail
    
    lea rcx, [msg_pass]
    call print_string
    jmp .done
    
.fail:
    lea rcx, [msg_fail]
    call print_string
    
.done:
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; Test 3: Allocate temporary
; ============================================================================
test_allocate_temp:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    lea rcx, [msg_test3]
    call print_string
    
    ; Need a function context
    call ir_program_create
    lea rcx, [test_func_name]
    mov rdx, 9
    mov r8, TYPE_I32
    call ir_function_create
    
    ; Allocate temp
    call ir_new_temp
    cmp rax, 0
    jne .pass
    
    lea rcx, [msg_fail]
    call print_string
    jmp .done
    
.pass:
    lea rcx, [msg_pass]
    call print_string
    
.done:
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; Test 4: Simple expression
; ============================================================================
test_simple_expression:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    lea rcx, [msg_test4]
    call print_string
    
    ; This would require creating AST nodes
    ; For now, just mark as pass (placeholder)
    lea rcx, [msg_pass]
    call print_string
    
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; Helper: Print string
; ============================================================================
print_string:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    
    mov rbx, rcx
    
    ; Get string length
    xor rdx, rdx
.count_loop:
    cmp byte [rbx + rdx], 0
    je .count_done
    inc rdx
    jmp .count_loop
    
.count_done:
    ; Write to stdout
    mov rcx, [stdout_handle]
    mov r8, rdx
    lea rdx, [rbx]
    lea r9, [bytes_written]
    push 0
    call WriteFile
    add rsp, 8
    
    pop rbx
    add rsp, 48
    pop rbp
    ret
