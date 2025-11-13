; Test with real IR instructions
bits 64
default rel

extern arena_init
extern codegen_init
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
%define IR_RETURN 55

%define IR_OP_TEMP 0
%define IR_OP_CONST 2

section .data
    test_func_name db "add_numbers", 0
    msg_header db "=== Real Code Generation Test ===", 13, 10, 0
    msg_step1 db "Creating IR function...", 13, 10, 0
    msg_step2 db "Adding IR instructions...", 13, 10, 0
    msg_step3 db "Generating assembly...", 13, 10, 0
    msg_output db 13, 10, "Generated Assembly:", 13, 10, 0
    msg_separator db "----------------------------------------", 13, 10, 0
    msg_done db 13, 10, "Done!", 13, 10, 0

section .bss
    stdout_handle resq 1
    bytes_written resq 1
    ir_func resq 1
    ir_inst resq 1

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
    xor rcx, rcx
    call arena_init
    test rax, rax
    jz .error
    
    call codegen_init
    test rax, rax
    jnz .error
    
    ; Step 1: Create IR
    lea rcx, [msg_step1]
    call print_str
    
    call ir_program_create
    test rax, rax
    jz .error
    
    lea rcx, [test_func_name]
    mov rdx, 11
    mov r8, TYPE_I32
    call ir_function_create
    test rax, rax
    jz .error
    mov [ir_func], rax
    
    ; Step 2: Add instructions
    lea rcx, [msg_step2]
    call print_str
    
    ; We'll manually create a simple function:
    ; t0 = 10
    ; t1 = 20
    ; t2 = t0 + t1
    ; return t2
    
    ; TODO: Need to add IR instruction creation functions
    ; For now, just generate the empty function
    
    ; Step 3: Generate code
    lea rcx, [msg_step3]
    call print_str
    
    mov rcx, [ir_func]
    call codegen_generate_function
    test rax, rax
    jnz .error
    
    ; Get output
    call codegen_get_output
    test rax, rax
    jz .error
    
    push rax
    push rdx
    
    ; Print output
    lea rcx, [msg_output]
    call print_str
    lea rcx, [msg_separator]
    call print_str
    
    pop rdx
    pop rax
    mov rcx, rax
    call print_buffer
    
    lea rcx, [msg_separator]
    call print_str
    lea rcx, [msg_done]
    call print_str
    
    xor rcx, rcx
    call ExitProcess
    
.error:
    mov rcx, 1
    call ExitProcess

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
