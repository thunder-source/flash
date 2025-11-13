; Test with exactly one IR instruction
bits 64
default rel

extern arena_init
extern codegen_init
extern codegen_generate_function
extern codegen_get_output
extern ir_program_create
extern ir_function_create
extern ir_operand_temp
extern ir_operand_const
extern ir_emit_move
extern ir_new_temp
extern GetStdHandle
extern WriteFile
extern ExitProcess

%define STD_OUTPUT_HANDLE -11
%define TYPE_I32 2
%define IROperand_size 32

section .data
    func_name db "one_inst", 0
    msg_header db "=== One Instruction Test ===", 13, 10, 0
    msg_output db 13, 10, "Generated:", 13, 10, 0
    msg_done db 13, 10, "Done!", 13, 10, 0

section .bss
    stdout_handle resq 1
    bytes_written resq 1
    dest_op resb IROperand_size
    src1_op resb IROperand_size

section .text
global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout_handle], rax
    
    lea rcx, [msg_header]
    call print_str
    
    xor rcx, rcx
    call arena_init
    test rax, rax
    jz .error
    
    call codegen_init
    test rax, rax
    jnz .error
    
    call ir_program_create
    test rax, rax
    jz .error
    
    lea rcx, [func_name]
    mov rdx, 8
    mov r8, TYPE_I32
    call ir_function_create
    test rax, rax
    jz .error
    
    ; Add ONE instruction: t1 = 42
    call ir_new_temp
    test rax, rax
    jz .error
    
    lea rcx, [dest_op]
    mov rdx, rax
    mov r8, TYPE_I32
    call ir_operand_temp
    
    lea rcx, [src1_op]
    mov rdx, 42
    mov r8, TYPE_I32
    call ir_operand_const
    
    lea rcx, [dest_op]
    lea rdx, [src1_op]
    call ir_emit_move
    test rax, rax
    jz .error
    
    ; Generate code
    mov rcx, [ir_function_create]  ; WRONG! Need the function pointer we saved
    ; Let me fix this...
    
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
