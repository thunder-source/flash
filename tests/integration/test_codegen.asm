; ============================================================================
; Flash Compiler - Code Generation Test
; ============================================================================

bits 64
default rel

extern arena_init
extern codegen_init
extern codegen_generate_program
extern codegen_generate_function
extern codegen_get_output
extern ir_program_create
extern ir_function_create
extern ExitProcess
extern GetStdHandle
extern WriteFile

%define STD_OUTPUT_HANDLE -11
%define TYPE_I32 2

section .data
    msg_header db "=== Code Generation Test ===", 13, 10, 0
    msg_test1 db "Test 1: Initialize code generator... ", 0
    msg_test2 db "Test 2: Generate simple function... ", 0
    msg_test3 db "Test 3: Get generated code... ", 0
    msg_pass db "[PASS]", 13, 10, 0
    msg_fail db "[FAIL]", 13, 10, 0
    msg_output db 13, 10, "Generated code:", 13, 10, 0
    msg_separator db "========================================", 13, 10, 0
    
    test_func_name db "test_main", 0

section .bss
    stdout_handle:  resq 1
    bytes_written:  resq 1

section .text
global main

; ============================================================================
; main - Entry point
; ============================================================================
main:
    push rbp
    mov rbp, rsp
    sub rsp, 48             ; Extra space for alignment and parameters
    
    ; Get stdout handle
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout_handle], rax
    
    ; Print header
    lea rcx, [msg_header]
    call print_string
    
    ; Initialize memory arena
    call arena_init
    test rax, rax
    jnz .error
    
    ; Run tests - try just one at a time
    call test_init_codegen
    ; call test_generate_function
    ; call test_get_output
    
    ; Exit normally
    xor rax, rax
    add rsp, 48
    pop rbp
    ret
    
.error:
    mov rax, 1
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; Test 1: Initialize code generator
; ============================================================================
test_init_codegen:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    lea rcx, [msg_test1]
    call print_string
    
    call codegen_init
    test rax, rax
    jnz .fail
    
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
; Test 2: Generate simple function
; ============================================================================
test_generate_function:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 48
    
    lea rcx, [msg_test2]
    call print_string
    
    ; Create IR program
    call ir_program_create
    test rax, rax
    jz .fail
    
    ; Create IR function
    lea rcx, [test_func_name]
    mov rdx, 9
    mov r8, TYPE_I32
    call ir_function_create
    test rax, rax
    jz .fail
    
    mov rbx, rax            ; Save function pointer
    
    ; TODO: Add some IR instructions here for testing
    ; For now, just generate empty function
    
    ; Generate code for function
    mov rcx, rbx
    call codegen_generate_function
    test rax, rax
    jnz .fail
    
    lea rcx, [msg_pass]
    call print_string
    jmp .done
    
.fail:
    lea rcx, [msg_fail]
    call print_string
    
.done:
    add rsp, 48
    pop rbx
    pop rbp
    ret

; ============================================================================
; Test 3: Get generated code output
; ============================================================================
test_get_output:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    lea rcx, [msg_test3]
    call print_string
    
    call codegen_get_output
    test rax, rax
    jz .fail
    test rdx, rdx
    jz .fail
    
    lea rcx, [msg_pass]
    call print_string
    
    ; Print the generated code
    lea rcx, [msg_output]
    call print_string
    
    lea rcx, [msg_separator]
    call print_string
    
    ; Get output again
    call codegen_get_output
    mov rcx, rax        ; RCX = buffer pointer
    ; RDX already has length
    call print_buffer
    
    lea rcx, [msg_separator]
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
; print_string - Print null-terminated string
; Parameters: RCX = string pointer
; ============================================================================
print_string:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 48
    
    mov rbx, rcx
    
    ; Calculate length
    xor rdx, rdx
.len_loop:
    cmp byte [rbx + rdx], 0
    je .len_done
    inc rdx
    jmp .len_loop
    
.len_done:
    test rdx, rdx
    jz .exit
    
    ; Write to console
    mov rcx, [stdout_handle]
    mov r8, rdx
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0
    call WriteFile
    
.exit:
    add rsp, 48
    pop rbx
    pop rbp
    ret

; ============================================================================
; print_buffer - Print buffer with given length
; Parameters: 
;   RCX = buffer pointer
;   RDX = length
; ============================================================================
print_buffer:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    sub rsp, 48
    
    mov rbx, rcx        ; Save buffer
    mov r12, rdx        ; Save length
    
    test r12, r12
    jz .exit
    
    ; WriteFile parameters
    mov rcx, [stdout_handle]
    mov rdx, rbx        ; buffer
    mov r8, r12         ; length
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0
    call WriteFile
    
.exit:
    add rsp, 48
    pop r12
    pop rbx
    pop rbp
    ret
