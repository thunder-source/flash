; Simplified codegen test - generate actual code
bits 64
default rel

extern arena_init
extern codegen_init
extern codegen_generate_program
extern codegen_generate_function
extern codegen_get_output
extern ir_program_create
extern ir_function_create
extern ir_emit_instruction
extern ir_create_instruction
extern ir_new_temp
extern GetStdHandle
extern WriteFile
extern ExitProcess

%define STD_OUTPUT_HANDLE -11
%define TYPE_I32 2
%define IR_MOVE 40
%define IR_ADD 0

section .data
    test_func_name db "test_main", 0
    msg_header db "=== Simple Codegen Test ===", 13, 10, 0
    msg_output db 13, 10, "Generated Assembly:", 13, 10, 0
    msg_done db 13, 10, "Test Complete!", 13, 10, 0

section .bss
    stdout_handle resq 1
    bytes_written resq 1
    ir_func resq 1

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
    
    ; Print header
    lea rcx, [msg_header]
    call print_str
    
    ; Initialize
    call arena_init
    test rax, rax
    jnz .error
    
    call codegen_init
    test rax, rax
    jnz .error
    
    ; Create IR program
    call ir_program_create
    test rax, rax
    jz .error
    
    ; Save IR program pointer
    push rax
    
    ; Create function
    lea rcx, [test_func_name]
    mov rdx, 9
    mov r8, TYPE_I32
    call ir_function_create
    test rax, rax
    jz .error
    mov [ir_func], rax
    
    ; Generate code for function only (skip program for now)
    mov rcx, rax
    call codegen_generate_function
    test rax, rax
    jnz .error
    pop rax      ; Clean up saved program pointer
    
    ; Get output
    call codegen_get_output
    test rax, rax
    jz .error
    
    ; Print output label
    push rax
    push rdx
    lea rcx, [msg_output]
    call print_str
    pop rdx
    pop rax
    
    ; Print generated code
    mov rcx, rax
    call print_buffer
    
    ; Print done
    lea rcx, [msg_done]
    call print_str
    
    ; Success
    xor rcx, rcx
    call ExitProcess
    
.error:
    mov rcx, 1
    call ExitProcess

; Print null-terminated string
print_str:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 48
    
    mov rbx, rcx
    xor rdx, rdx
.loop:
    cmp byte [rbx + rdx], 0
    je .done
    inc rdx
    jmp .loop
.done:
    test rdx, rdx
    jz .exit
    
    mov rcx, [stdout_handle]
    mov r8, rdx
    mov rdx, rbx
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0
    call WriteFile
    
.exit:
    add rsp, 48
    pop rbx
    pop rbp
    ret

; Print buffer with length
; RCX = buffer, RDX = length
print_buffer:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    sub rsp, 48
    
    mov rbx, rcx
    mov r12, rdx
    
    test r12, r12
    jz .exit
    
    mov rcx, [stdout_handle]
    mov rdx, rbx
    mov r8, r12
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0
    call WriteFile
    
.exit:
    add rsp, 48
    pop r12
    pop rbx
    pop rbp
    ret
