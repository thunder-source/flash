; Comprehensive code generation test with real IR instructions
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
extern ir_emit_binary
extern ir_emit_move
extern ir_new_temp
extern GetStdHandle
extern WriteFile
extern ExitProcess

%define STD_OUTPUT_HANDLE -11
%define TYPE_I32 2
%define IR_ADD 0
%define IR_SUB 1
%define IR_MUL 2
%define IR_MOVE 40
%define IROperand_size 32

section .data
    func_name db "test_arithmetic", 0
    msg_header db "=== Full Code Generation Test ===", 13, 10, 0
    msg_creating db "Creating IR with instructions...", 13, 10, 0
    msg_generating db "Generating assembly code...", 13, 10, 0
    msg_output db 13, 10, "Generated Assembly:", 13, 10, 0
    msg_separator db "========================================", 13, 10, 0
    msg_done db 13, 10, "Test Complete!", 13, 10, 0
    msg_error db "ERROR!", 13, 10, 0

section .bss
    stdout_handle resq 1
    bytes_written resq 1
    ir_func resq 1
    dest_op resb IROperand_size
    src1_op resb IROperand_size
    src2_op resb IROperand_size

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
    
    ; Create IR program and function
    call ir_program_create
    test rax, rax
    jz .error
    
    lea rcx, [func_name]
    mov rdx, 14
    mov r8, TYPE_I32
    call ir_function_create
    test rax, rax
    jz .error
    mov [ir_func], rax      ; Save function pointer
    
    ; Create IR instructions
    lea rcx, [msg_creating]
    call print_str
    
    ; Build simple test function:
    ; t1 = 10
    ; t2 = 20
    ; t3 = t1 + t2
    
    ; Instruction 1: t1 = 10 (MOVE t1, 10)
    call ir_new_temp        ; Allocate t1
    test rax, rax
    jz .error
    mov r12, rax            ; Save t1 number (should be 1)
    
    lea rcx, [dest_op]
    mov rdx, r12
    mov r8, TYPE_I32
    call ir_operand_temp
    
    lea rcx, [src1_op]
    mov rdx, 10
    mov r8, TYPE_I32
    call ir_operand_const
    
    lea rcx, [dest_op]
    lea rdx, [src1_op]
    call ir_emit_move
    test rax, rax
    jz .error
    
    ; Instruction 2: t2 = 20 (MOVE t2, 20)
    call ir_new_temp        ; Allocate t2
    test rax, rax
    jz .error
    mov r13, rax            ; Save t2 number (should be 2)
    
    lea rcx, [dest_op]
    mov rdx, r13
    mov r8, TYPE_I32
    call ir_operand_temp
    
    lea rcx, [src1_op]
    mov rdx, 20
    mov r8, TYPE_I32
    call ir_operand_const
    
    lea rcx, [dest_op]
    lea rdx, [src1_op]
    call ir_emit_move
    test rax, rax
    jz .error
    
    ; Instruction 3: t3 = t1 + t2 (ADD t3, t1, t2)
    call ir_new_temp        ; Allocate t3
    test rax, rax
    jz .error
    mov r14, rax            ; Save t3 number (should be 3)
    
    lea rcx, [dest_op]
    mov rdx, r14
    mov r8, TYPE_I32
    call ir_operand_temp
    
    lea rcx, [src1_op]
    mov rdx, r12            ; t1
    mov r8, TYPE_I32
    call ir_operand_temp
    
    lea rcx, [src2_op]
    mov rdx, r13            ; t2
    mov r8, TYPE_I32
    call ir_operand_temp
    
    mov rcx, IR_ADD
    lea rdx, [dest_op]
    lea r8, [src1_op]
    lea r9, [src2_op]
    call ir_emit_binary
    test rax, rax
    jz .error
    
    ; Generate assembly
    lea rcx, [msg_generating]
    call print_str
    
    mov rcx, [ir_func]
    call codegen_generate_function
    test rax, rax
    jnz .error_codegen
    
    ; Get and print output
    call codegen_get_output
    test rax, rax
    jz .error
    
    push rax
    push rdx
    
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
    
.error_codegen:
    lea rcx, [msg_output]
    call print_str
    
    ; Try to get output anyway to see what was generated
    call codegen_get_output
    test rax, rax
    jz .error
    
    push rax
    push rdx
    lea rcx, [msg_separator]
    call print_str
    pop rdx
    pop rax
    
    mov rcx, rax
    call print_buffer
    
    lea rcx, [msg_separator]
    call print_str
    jmp .error
    
.error:
    lea rcx, [msg_error]
    call print_str
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
    mov qword [rbp - 32], 0
    call WriteFile
    
.exit:
    add rsp, 48
    pop rbx
    pop rbp
    ret

; Print buffer with length
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
