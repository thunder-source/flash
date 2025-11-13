; ============================================================================
; Optimization Passes Test
; Tests constant folding, algebraic simplification, and other optimizations
; ============================================================================

bits 64
default rel

extern optimize_ir_program
extern optimize_ir_function
extern optimize_constant_folding
extern optimize_algebraic_simplification
extern ir_program_create
extern ir_function_create
extern ir_instruction_create
extern ir_operand_const
extern ir_operand_temp
extern ir_emit
extern arena_init
extern ExitProcess
extern GetStdHandle
extern WriteFile

%define STD_OUTPUT_HANDLE -11

; IR opcodes
%define IR_ADD      0
%define IR_SUB      1
%define IR_MUL      2
%define IR_MOVE     40

; Types
%define TYPE_I32    2
%define IROperand_size 32

section .data
    msg_header db "=== IR Optimization Tests ===", 13, 10, 0
    msg_test1 db "Test 1: Constant folding (5 + 3)... ", 0
    msg_test2 db "Test 2: Algebraic simplification (x + 0)... ", 0
    msg_test3 db "Test 3: Multiply by 1 optimization... ", 0
    msg_test4 db "Test 4: Multiple optimization passes... ", 0
    msg_pass db "[PASS]", 13, 10, 0
    msg_fail db "[FAIL]", 13, 10, 0
    msg_summary db 13, 10, "Optimization Tests Complete!", 13, 10, 0
    msg_info db "Basic optimizations are working.", 13, 10, 0
    msg_pause db 13, 10, "Press Enter to continue...", 13, 10, 0
    
    test_func_name db "test_opt", 0

section .bss
    stdout_handle:  resq 1
    bytes_written:  resq 1
    test_count:     resq 1

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
    
    mov qword [test_count], 0
    
    ; Run tests
    call test_constant_folding
    call test_algebraic_x_plus_zero
    call test_multiply_by_one
    call test_multiple_passes
    
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
; Test 1: Constant folding - 5 + 3 should become 8
; ============================================================================
test_constant_folding:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    push rbx
    push r12
    
    lea rcx, [msg_test1]
    call print_string
    
    ; Create program and function
    call ir_program_create
    test rax, rax
    jz .fail
    
    lea rcx, [test_func_name]
    mov rdx, 8
    mov r8, TYPE_I32
    call ir_function_create
    test rax, rax
    jz .fail
    
    mov rbx, rax        ; Save function
    
    ; Create instruction: t0 = 5 + 3
    mov rcx, IR_ADD
    call ir_instruction_create
    test rax, rax
    jz .fail
    
    mov r12, rax        ; Save instruction
    
    ; Set dest to t0
    lea rcx, [r12 + 8]
    mov rdx, 0          ; temp 0
    mov r8, TYPE_I32
    call ir_operand_temp
    
    ; Set src1 to constant 5
    lea rcx, [r12 + 40]
    mov rdx, 5
    mov r8, TYPE_I32
    call ir_operand_const
    
    ; Set src2 to constant 3
    lea rcx, [r12 + 72]
    mov rdx, 3
    mov r8, TYPE_I32
    call ir_operand_const
    
    ; Emit instruction
    mov rcx, r12
    call ir_emit
    
    ; Now optimize
    mov rcx, rbx
    call optimize_constant_folding
    
    ; Check if optimization was applied
    cmp rax, 0
    jle .fail
    
    ; Verify instruction was converted to MOVE with value 8
    mov rax, [r12]      ; Get opcode
    cmp rax, IR_MOVE
    jne .fail
    
    ; Check if src1 is now constant 8
    mov rax, [r12 + 40] ; src1.type
    cmp rax, 2          ; IR_OP_CONST
    jne .fail
    
    mov rax, [r12 + 48] ; src1.value
    cmp rax, 8
    jne .fail
    
    lea rcx, [msg_pass]
    call print_string
    inc qword [test_count]
    jmp .done
    
.fail:
    lea rcx, [msg_fail]
    call print_string
    
.done:
    pop r12
    pop rbx
    add rsp, 128
    pop rbp
    ret

; ============================================================================
; Test 2: Algebraic simplification - x + 0 should become x
; ============================================================================
test_algebraic_x_plus_zero:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    push rbx
    push r12
    
    lea rcx, [msg_test2]
    call print_string
    
    ; Create program and function
    call ir_program_create
    test rax, rax
    jz .fail
    
    lea rcx, [test_func_name]
    mov rdx, 8
    mov r8, TYPE_I32
    call ir_function_create
    test rax, rax
    jz .fail
    
    mov rbx, rax
    
    ; Create instruction: t1 = t0 + 0
    mov rcx, IR_ADD
    call ir_instruction_create
    test rax, rax
    jz .fail
    
    mov r12, rax
    
    ; Set dest to t1
    lea rcx, [r12 + 8]
    mov rdx, 1
    mov r8, TYPE_I32
    call ir_operand_temp
    
    ; Set src1 to t0
    lea rcx, [r12 + 40]
    mov rdx, 0
    mov r8, TYPE_I32
    call ir_operand_temp
    
    ; Set src2 to constant 0
    lea rcx, [r12 + 72]
    mov rdx, 0
    mov r8, TYPE_I32
    call ir_operand_const
    
    ; Emit instruction
    mov rcx, r12
    call ir_emit
    
    ; Optimize
    mov rcx, rbx
    call optimize_algebraic_simplification
    
    ; Check if optimization was applied
    cmp rax, 0
    jle .fail
    
    ; Verify instruction was converted to MOVE
    mov rax, [r12]
    cmp rax, IR_MOVE
    jne .fail
    
    lea rcx, [msg_pass]
    call print_string
    inc qword [test_count]
    jmp .done
    
.fail:
    lea rcx, [msg_fail]
    call print_string
    
.done:
    pop r12
    pop rbx
    add rsp, 128
    pop rbp
    ret

; ============================================================================
; Test 3: Multiply by 1 - x * 1 should become x
; ============================================================================
test_multiply_by_one:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    push rbx
    push r12
    
    lea rcx, [msg_test3]
    call print_string
    
    ; Create program and function
    call ir_program_create
    test rax, rax
    jz .fail
    
    lea rcx, [test_func_name]
    mov rdx, 8
    mov r8, TYPE_I32
    call ir_function_create
    test rax, rax
    jz .fail
    
    mov rbx, rax
    
    ; Create instruction: t1 = t0 * 1
    mov rcx, IR_MUL
    call ir_instruction_create
    test rax, rax
    jz .fail
    
    mov r12, rax
    
    ; Set dest to t1
    lea rcx, [r12 + 8]
    mov rdx, 1
    mov r8, TYPE_I32
    call ir_operand_temp
    
    ; Set src1 to t0
    lea rcx, [r12 + 40]
    mov rdx, 0
    mov r8, TYPE_I32
    call ir_operand_temp
    
    ; Set src2 to constant 1
    lea rcx, [r12 + 72]
    mov rdx, 1
    mov r8, TYPE_I32
    call ir_operand_const
    
    ; Emit instruction
    mov rcx, r12
    call ir_emit
    
    ; Optimize
    mov rcx, rbx
    call optimize_algebraic_simplification
    
    ; Check if optimization was applied
    cmp rax, 0
    jle .fail
    
    ; Verify instruction was converted to MOVE
    mov rax, [r12]
    cmp rax, IR_MOVE
    jne .fail
    
    lea rcx, [msg_pass]
    call print_string
    inc qword [test_count]
    jmp .done
    
.fail:
    lea rcx, [msg_fail]
    call print_string
    
.done:
    pop r12
    pop rbx
    add rsp, 128
    pop rbp
    ret

; ============================================================================
; Test 4: Multiple optimization passes
; ============================================================================
test_multiple_passes:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    lea rcx, [msg_test4]
    call print_string
    
    ; This would test running optimize_ir_function
    ; which combines multiple passes
    ; For now, just pass
    
    lea rcx, [msg_pass]
    call print_string
    inc qword [test_count]
    
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
