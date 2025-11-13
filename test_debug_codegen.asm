; Debug version - check each step
bits 64
default rel

extern arena_init
extern codegen_init
extern codegen_get_output
extern ir_program_create
extern ir_function_create
extern codegen_generate_function
extern GetStdHandle
extern WriteFile
extern ExitProcess

%define STD_OUTPUT_HANDLE -11
%define TYPE_I32 2

section .data
    test_func_name db "test_main", 0
    msg1 db "Step 1: arena_init...", 13, 10, 0
    msg2 db "Step 2: codegen_init...", 13, 10, 0
    msg3 db "Step 3: ir_program_create...", 13, 10, 0
    msg4 db "Step 4: ir_function_create...", 13, 10, 0
    msg5 db "Step 5: codegen_generate_function...", 13, 10, 0
    msg6 db "Step 6: codegen_get_output...", 13, 10, 0
    msg_ok db "  [OK]", 13, 10, 0
    msg_fail db "  [FAILED]", 13, 10, 0
    msg_output db 13, 10, "Generated code:", 13, 10, 0
    msg_done db 13, 10, "Success!", 13, 10, 0

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
    
    ; Step 1
    lea rcx, [msg1]
    call print_str
    xor rcx, rcx  ; Use default size
    call arena_init
    test rax, rax
    jz .fail      ; Returns arena pointer, NULL on error
    lea rcx, [msg_ok]
    call print_str
    
    ; Step 2
    lea rcx, [msg2]
    call print_str
    call codegen_init
    test rax, rax
    jnz .fail
    lea rcx, [msg_ok]
    call print_str
    
    ; Step 3
    lea rcx, [msg3]
    call print_str
    call ir_program_create
    test rax, rax
    jz .fail
    mov rbx, rax  ; Save program pointer in rbx instead of stack
    lea rcx, [msg_ok]
    call print_str
    
    ; Step 4
    lea rcx, [msg4]
    call print_str
    lea rcx, [test_func_name]
    mov rdx, 9
    mov r8, TYPE_I32
    call ir_function_create
    test rax, rax
    jz .fail
    mov rbx, rax
    lea rcx, [msg_ok]
    call print_str
    
    ; Step 5
    lea rcx, [msg5]
    call print_str
    mov rcx, rbx
    call codegen_generate_function
    test rax, rax
    jnz .fail
    lea rcx, [msg_ok]
    call print_str
    
    ; Step 6
    lea rcx, [msg6]
    call print_str
    call codegen_get_output
    test rax, rax
    jz .fail
    mov rbx, rax
    mov r12, rdx
    lea rcx, [msg_ok]
    call print_str
    
    ; Print output
    lea rcx, [msg_output]
    call print_str
    mov rcx, rbx
    mov rdx, r12
    call print_buffer
    
    ; Done
    lea rcx, [msg_done]
    call print_str
    
    xor rcx, rcx
    call ExitProcess
    
.fail:
    lea rcx, [msg_fail]
    call print_str
    mov rcx, 1
    call ExitProcess

; Print string
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
    mov qword [rbp - 32], 0
    call WriteFile
    
.exit:
    add rsp, 48
    pop rbx
    pop rbp
    ret

; Print buffer
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
    mov qword [rbp - 32], 0
    call WriteFile
    
.exit:
    add rsp, 48
    pop r12
    pop rbx
    pop rbp
    ret
