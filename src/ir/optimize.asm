; ============================================================================
; Flash Compiler - IR Optimization Passes
; ============================================================================
; Optimizations on Three-Address Code IR
; ============================================================================

bits 64
default rel

extern arena_alloc

; IR opcodes (from ir.asm)
%define IR_ADD          0
%define IR_SUB          1
%define IR_MUL          2
%define IR_DIV          3
%define IR_MOD          4
%define IR_NEG          5
%define IR_AND          20
%define IR_OR           21
%define IR_XOR          22
%define IR_NOT          23
%define IR_SHL          24
%define IR_SHR          25
%define IR_EQ           30
%define IR_NE           31
%define IR_LT           32
%define IR_LE           33
%define IR_GT           34
%define IR_GE           35
%define IR_MOVE         40
%define IR_LOAD         41
%define IR_STORE        42
%define IR_ADDR         43
%define IR_ALLOC        44
%define IR_LABEL        50
%define IR_JUMP         51
%define IR_JUMP_IF      52
%define IR_JUMP_IF_NOT  53
%define IR_CALL         54
%define IR_RETURN       55
%define IR_RETURN_VOID  56
%define IR_NOP          90

; IR operand types
%define IR_OP_TEMP      0
%define IR_OP_VAR       1
%define IR_OP_CONST     2
%define IR_OP_LABEL     3
%define IR_OP_FUNC      4
%define IR_OP_NONE      5

; IROperand structure offsets
%define IROperand.type      0
%define IROperand.value     8
%define IROperand.data_type 16
%define IROperand.aux       24
%define IROperand_size      32

; IRInstruction structure offsets
%define IRInstruction.opcode    0
%define IRInstruction.dest      8
%define IRInstruction.src1      40
%define IRInstruction.src2      72
%define IRInstruction.line      104
%define IRInstruction.next      112

; IRFunction structure offsets
%define IRFunction.name         0
%define IRFunction.name_len     8
%define IRFunction.params       16
%define IRFunction.param_count  24
%define IRFunction.return_type  32
%define IRFunction.instructions 40
%define IRFunction.last_inst    48
%define IRFunction.temp_count   56
%define IRFunction.label_count  64
%define IRFunction.next         72

section .bss
    opt_modified:   resq 1      ; Flag: was IR modified?
    opt_iterations: resq 1      ; Optimization iteration count

section .data
    msg_opt_start db "Starting optimization passes...", 0
    msg_opt_done db "Optimization complete", 0

section .text

global optimize_ir_program
global optimize_ir_function
global optimize_constant_folding
global optimize_dead_code_elimination
global optimize_copy_propagation
global optimize_algebraic_simplification
global optimize_pass

; ============================================================================
; optimize_ir_program - Run all optimization passes on entire program
; Parameters:
;   RCX = pointer to IRProgram
; Returns:
;   RAX = number of optimizations applied
; ============================================================================
optimize_ir_program:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    
    mov rbx, rcx        ; IRProgram
    xor r13, r13        ; Total optimizations count
    
    ; Get first function
    mov r12, [rbx]      ; IRProgram.functions at offset 0
    
.opt_func_loop:
    test r12, r12
    jz .done
    
    ; Optimize this function
    mov rcx, r12
    call optimize_ir_function
    add r13, rax        ; Add to total count
    
    ; Next function
    mov r12, [r12 + IRFunction.next]
    jmp .opt_func_loop
    
.done:
    mov rax, r13        ; Return total count
    
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; optimize_ir_function - Run optimization passes on a single function
; Parameters:
;   RCX = pointer to IRFunction
; Returns:
;   RAX = number of optimizations applied
; ============================================================================
optimize_ir_function:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    
    mov rbx, rcx        ; IRFunction
    xor r12, r12        ; Optimization count
    
    mov qword [opt_iterations], 0
    
.opt_loop:
    ; Reset modified flag
    mov qword [opt_modified], 0
    
    ; Pass 1: Constant folding
    mov rcx, rbx
    call optimize_constant_folding
    add r12, rax
    
    ; Pass 2: Algebraic simplification
    mov rcx, rbx
    call optimize_algebraic_simplification
    add r12, rax
    
    ; Pass 3: Copy propagation
    mov rcx, rbx
    call optimize_copy_propagation
    add r12, rax
    
    ; Pass 4: Dead code elimination
    mov rcx, rbx
    call optimize_dead_code_elimination
    add r12, rax
    
    ; Check if anything was modified
    mov rax, [opt_modified]
    test rax, rax
    jz .done
    
    ; Limit iterations to prevent infinite loops
    inc qword [opt_iterations]
    cmp qword [opt_iterations], 10
    jl .opt_loop
    
.done:
    mov rax, r12        ; Return optimization count
    
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; optimize_constant_folding - Fold constant expressions
; Parameters:
;   RCX = pointer to IRFunction
; Returns:
;   RAX = number of optimizations applied
; ============================================================================
optimize_constant_folding:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    mov rbx, rcx        ; IRFunction
    xor r12, r12        ; Optimization count
    
    ; Get first instruction
    mov r13, [rbx + IRFunction.instructions]
    
.inst_loop:
    test r13, r13
    jz .done
    
    ; Get instruction opcode
    mov r14, [r13 + IRInstruction.opcode]
    
    ; Check if this is a binary arithmetic operation
    cmp r14, IR_ADD
    je .check_binary
    cmp r14, IR_SUB
    je .check_binary
    cmp r14, IR_MUL
    je .check_binary
    cmp r14, IR_DIV
    je .check_binary
    cmp r14, IR_MOD
    je .check_binary
    cmp r14, IR_AND
    je .check_binary
    cmp r14, IR_OR
    je .check_binary
    cmp r14, IR_XOR
    je .check_binary
    cmp r14, IR_SHL
    je .check_binary
    cmp r14, IR_SHR
    je .check_binary
    
    jmp .next_inst
    
.check_binary:
    ; Check if both operands are constants
    lea r14, [r13 + IRInstruction.src1]
    lea r15, [r13 + IRInstruction.src2]
    
    mov rax, [r14 + IROperand.type]
    cmp rax, IR_OP_CONST
    jne .next_inst
    
    mov rax, [r15 + IROperand.type]
    cmp rax, IR_OP_CONST
    jne .next_inst
    
    ; Both operands are constants - fold them
    mov rcx, r13
    call fold_binary_constants
    test rax, rax
    jz .next_inst
    
    inc r12                     ; Count optimization
    mov qword [opt_modified], 1 ; Mark as modified
    
.next_inst:
    mov r13, [r13 + IRInstruction.next]
    jmp .inst_loop
    
.done:
    mov rax, r12
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; fold_binary_constants - Fold binary operation with constant operands
; Parameters:
;   RCX = pointer to IRInstruction
; Returns:
;   RAX = 1 if folded, 0 otherwise
; ============================================================================
fold_binary_constants:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    mov rbx, rcx        ; Instruction
    
    ; Get opcode
    mov r12, [rbx + IRInstruction.opcode]
    
    ; Get operand values
    lea rax, [rbx + IRInstruction.src1]
    mov r13, [rax + IROperand.value]   ; src1 value
    
    lea rax, [rbx + IRInstruction.src2]
    mov r14, [rax + IROperand.value]   ; src2 value
    
    ; Perform operation based on opcode
    cmp r12, IR_ADD
    je .do_add
    cmp r12, IR_SUB
    je .do_sub
    cmp r12, IR_MUL
    je .do_mul
    cmp r12, IR_DIV
    je .do_div
    cmp r12, IR_MOD
    je .do_mod
    cmp r12, IR_AND
    je .do_and
    cmp r12, IR_OR
    je .do_or
    cmp r12, IR_XOR
    je .do_xor
    cmp r12, IR_SHL
    je .do_shl
    cmp r12, IR_SHR
    je .do_shr
    
    ; Unknown opcode
    xor rax, rax
    jmp .done
    
.do_add:
    mov rax, r13
    add rax, r14
    jmp .convert_to_move
    
.do_sub:
    mov rax, r13
    sub rax, r14
    jmp .convert_to_move
    
.do_mul:
    mov rax, r13
    imul rax, r14
    jmp .convert_to_move
    
.do_div:
    test r14, r14
    jz .error           ; Division by zero
    mov rax, r13
    xor rdx, rdx
    cmp rax, 0
    jge .div_positive
    neg rax
    div r14
    neg rax
    jmp .convert_to_move
.div_positive:
    div r14
    jmp .convert_to_move
    
.do_mod:
    test r14, r14
    jz .error
    mov rax, r13
    xor rdx, rdx
    div r14
    mov rax, rdx        ; Remainder
    jmp .convert_to_move
    
.do_and:
    mov rax, r13
    and rax, r14
    jmp .convert_to_move
    
.do_or:
    mov rax, r13
    or rax, r14
    jmp .convert_to_move
    
.do_xor:
    mov rax, r13
    xor rax, r14
    jmp .convert_to_move
    
.do_shl:
    mov rax, r13
    mov rcx, r14
    shl rax, cl
    jmp .convert_to_move
    
.do_shr:
    mov rax, r13
    mov rcx, r14
    shr rax, cl
    jmp .convert_to_move
    
.convert_to_move:
    ; Convert instruction to MOVE with constant result
    mov qword [rbx + IRInstruction.opcode], IR_MOVE
    
    ; Set src1 to constant with computed value
    lea rcx, [rbx + IRInstruction.src1]
    mov qword [rcx + IROperand.type], IR_OP_CONST
    mov [rcx + IROperand.value], rax
    
    ; Clear src2
    lea rcx, [rbx + IRInstruction.src2]
    mov qword [rcx + IROperand.type], IR_OP_NONE
    
    mov rax, 1          ; Success
    jmp .done
    
.error:
    xor rax, rax        ; Failed
    
.done:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; ============================================================================
; optimize_algebraic_simplification - Simplify algebraic expressions
; Examples: x + 0 = x, x * 1 = x, x * 0 = 0, x - x = 0
; Parameters:
;   RCX = pointer to IRFunction
; Returns:
;   RAX = number of optimizations applied
; ============================================================================
optimize_algebraic_simplification:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    push r14
    
    mov rbx, rcx        ; IRFunction
    xor r12, r12        ; Optimization count
    
    ; Get first instruction
    mov r13, [rbx + IRFunction.instructions]
    
.inst_loop:
    test r13, r13
    jz .done
    
    mov r14, [r13 + IRInstruction.opcode]
    
    ; Check for x + 0 or 0 + x
    cmp r14, IR_ADD
    je .check_add_zero
    
    ; Check for x * 1, 1 * x, x * 0, 0 * x
    cmp r14, IR_MUL
    je .check_mul_identity
    
    ; Check for x - 0
    cmp r14, IR_SUB
    je .check_sub_zero
    
    jmp .next_inst
    
.check_add_zero:
    ; Check if src2 is 0
    lea rax, [r13 + IRInstruction.src2]
    mov rcx, [rax + IROperand.type]
    cmp rcx, IR_OP_CONST
    jne .check_add_zero_src1
    mov rcx, [rax + IROperand.value]
    test rcx, rcx
    jnz .check_add_zero_src1
    
    ; src2 is 0, convert to: dest = src1
    mov rcx, r13
    call simplify_to_move_src1
    inc r12
    mov qword [opt_modified], 1
    jmp .next_inst
    
.check_add_zero_src1:
    ; Check if src1 is 0
    lea rax, [r13 + IRInstruction.src1]
    mov rcx, [rax + IROperand.type]
    cmp rcx, IR_OP_CONST
    jne .next_inst
    mov rcx, [rax + IROperand.value]
    test rcx, rcx
    jnz .next_inst
    
    ; src1 is 0, convert to: dest = src2
    mov rcx, r13
    call simplify_to_move_src2
    inc r12
    mov qword [opt_modified], 1
    jmp .next_inst
    
.check_mul_identity:
    ; Check if src2 is 1
    lea rax, [r13 + IRInstruction.src2]
    mov rcx, [rax + IROperand.type]
    cmp rcx, IR_OP_CONST
    jne .check_mul_zero
    mov rcx, [rax + IROperand.value]
    cmp rcx, 1
    jne .check_mul_zero
    
    ; src2 is 1, convert to: dest = src1
    mov rcx, r13
    call simplify_to_move_src1
    inc r12
    mov qword [opt_modified], 1
    jmp .next_inst
    
.check_mul_zero:
    ; Check if src2 is 0
    lea rax, [r13 + IRInstruction.src2]
    mov rcx, [rax + IROperand.type]
    cmp rcx, IR_OP_CONST
    jne .next_inst
    mov rcx, [rax + IROperand.value]
    test rcx, rcx
    jnz .next_inst
    
    ; src2 is 0, convert to: dest = 0
    mov rcx, r13
    call simplify_to_const_zero
    inc r12
    mov qword [opt_modified], 1
    jmp .next_inst
    
.check_sub_zero:
    ; Check if src2 is 0
    lea rax, [r13 + IRInstruction.src2]
    mov rcx, [rax + IROperand.type]
    cmp rcx, IR_OP_CONST
    jne .next_inst
    mov rcx, [rax + IROperand.value]
    test rcx, rcx
    jnz .next_inst
    
    ; src2 is 0, convert to: dest = src1
    mov rcx, r13
    call simplify_to_move_src1
    inc r12
    mov qword [opt_modified], 1
    
.next_inst:
    mov r13, [r13 + IRInstruction.next]
    jmp .inst_loop
    
.done:
    mov rax, r12
    
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; simplify_to_move_src1 - Convert instruction to: dest = src1
; Parameters:
;   RCX = pointer to IRInstruction
; ============================================================================
simplify_to_move_src1:
    push rbp
    mov rbp, rsp
    push rbx
    
    mov rbx, rcx
    
    ; Change opcode to MOVE
    mov qword [rbx + IRInstruction.opcode], IR_MOVE
    
    ; Clear src2
    lea rax, [rbx + IRInstruction.src2]
    mov qword [rax + IROperand.type], IR_OP_NONE
    
    pop rbx
    pop rbp
    ret

; ============================================================================
; simplify_to_move_src2 - Convert instruction to: dest = src2
; Parameters:
;   RCX = pointer to IRInstruction
; ============================================================================
simplify_to_move_src2:
    push rbp
    mov rbp, rsp
    push rbx
    
    mov rbx, rcx
    
    ; Change opcode to MOVE
    mov qword [rbx + IRInstruction.opcode], IR_MOVE
    
    ; Move src2 to src1
    lea rsi, [rbx + IRInstruction.src2]
    lea rdi, [rbx + IRInstruction.src1]
    mov rcx, IROperand_size
    rep movsb
    
    ; Clear src2
    lea rax, [rbx + IRInstruction.src2]
    mov qword [rax + IROperand.type], IR_OP_NONE
    
    pop rbx
    pop rbp
    ret

; ============================================================================
; simplify_to_const_zero - Convert instruction to: dest = 0
; Parameters:
;   RCX = pointer to IRInstruction
; ============================================================================
simplify_to_const_zero:
    push rbp
    mov rbp, rsp
    push rbx
    
    mov rbx, rcx
    
    ; Change opcode to MOVE
    mov qword [rbx + IRInstruction.opcode], IR_MOVE
    
    ; Set src1 to constant 0
    lea rax, [rbx + IRInstruction.src1]
    mov qword [rax + IROperand.type], IR_OP_CONST
    mov qword [rax + IROperand.value], 0
    
    ; Clear src2
    lea rax, [rbx + IRInstruction.src2]
    mov qword [rax + IROperand.type], IR_OP_NONE
    
    pop rbx
    pop rbp
    ret

; ============================================================================
; optimize_copy_propagation - Propagate copies (x = y, use x -> use y)
; Parameters:
;   RCX = pointer to IRFunction
; Returns:
;   RAX = number of optimizations applied
; ============================================================================
optimize_copy_propagation:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; TODO: Implement copy propagation
    ; This is more complex and requires dataflow analysis
    
    xor rax, rax        ; Return 0 for now
    
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; optimize_dead_code_elimination - Remove unused instructions
; Parameters:
;   RCX = pointer to IRFunction
; Returns:
;   RAX = number of optimizations applied
; ============================================================================
optimize_dead_code_elimination:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    
    mov rbx, rcx        ; IRFunction
    xor r12, r12        ; Optimization count
    
    ; Get first instruction
    mov r13, [rbx + IRFunction.instructions]
    
.inst_loop:
    test r13, r13
    jz .done
    
    ; Check for NOPs
    mov rax, [r13 + IRInstruction.opcode]
    cmp rax, IR_NOP
    jne .next_inst
    
    ; Found NOP - could remove it (simplified for now)
    inc r12
    mov qword [opt_modified], 1
    
.next_inst:
    mov r13, [r13 + IRInstruction.next]
    jmp .inst_loop
    
.done:
    mov rax, r12
    
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; optimize_pass - Single optimization pass (legacy/wrapper)
; Parameters:
;   RCX = pointer to IRFunction
; Returns:
;   RAX = number of optimizations applied
; ============================================================================
optimize_pass:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    call optimize_ir_function
    
    add rsp, 32
    pop rbp
    ret
