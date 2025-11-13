; ============================================================================
; Flash Compiler - IR Generator
; ============================================================================
; Converts AST to Three-Address Code IR
; ============================================================================

bits 64
default rel

; External IR functions
extern ir_program_create
extern ir_function_create
extern ir_instruction_create
extern ir_operand_temp
extern ir_operand_var
extern ir_operand_const
extern ir_operand_label
extern ir_emit
extern ir_emit_binary
extern ir_emit_move
extern ir_emit_return
extern ir_new_temp
extern ir_new_label
extern arena_alloc

; Include AST node type definitions
%define AST_PROGRAM         0
%define AST_FUNCTION        1
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
%define AST_CALL_EXPR       54

; IR opcodes
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
%define IR_LABEL        50
%define IR_JUMP         51
%define IR_JUMP_IF      52
%define IR_JUMP_IF_NOT  53
%define IR_RETURN       55
%define IR_RETURN_VOID  56

; Token types for operators
%define TOKEN_PLUS      20
%define TOKEN_MINUS     21
%define TOKEN_STAR      22
%define TOKEN_SLASH     23
%define TOKEN_PERCENT   24
%define TOKEN_EQ_EQ     40
%define TOKEN_BANG_EQ   41
%define TOKEN_LT        42
%define TOKEN_LT_EQ     43
%define TOKEN_GT        44
%define TOKEN_GT_EQ     45
%define TOKEN_AND_AND   50
%define TOKEN_OR_OR     51

; Type kinds
%define TYPE_I32        2
%define TYPE_VOID       13

; IROperand size (from ir.asm)
%define IROperand_size  32

section .bss
    break_label_stack:  resq 32     ; Stack of break labels for loops
    continue_label_stack: resq 32   ; Stack of continue labels for loops
    loop_depth:         resq 1      ; Current loop nesting depth

section .text

global ir_generate
global ir_generate_program
global ir_generate_function
global ir_generate_statement
global ir_generate_expression

; ============================================================================
; ir_generate - Main entry point for IR generation
; Parameters:
;   RCX = pointer to AST root (program node)
; Returns:
;   RAX = pointer to IRProgram
; ============================================================================
ir_generate:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    
    mov rbx, rcx        ; Save AST root
    
    ; Create IR program
    call ir_program_create
    test rax, rax
    jz .error
    
    push rax            ; Save program pointer
    
    ; Generate IR from program node
    mov rcx, rbx
    call ir_generate_program
    
    pop rax             ; Return program pointer
    jmp .done
    
.error:
    xor rax, rax
    
.done:
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; ir_generate_program - Generate IR for program node
; Parameters:
;   RCX = pointer to program AST node
; ============================================================================
ir_generate_program:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    
    mov rbx, rcx
    
    ; Get declarations list
    mov r12, [rbx + 8]      ; declarations at offset 8
    
.gen_decl_loop:
    test r12, r12
    jz .done
    
    ; Get declaration node
    mov rax, [r12]
    
    ; Check node type
    mov rcx, [rax]
    cmp rcx, AST_FUNCTION
    je .gen_function
    
    ; TODO: Handle other declaration types
    jmp .next_decl
    
.gen_function:
    mov rcx, rax
    call ir_generate_function
    
.next_decl:
    mov r12, [r12 + 8]      ; Next declaration
    jmp .gen_decl_loop
    
.done:
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; ir_generate_function - Generate IR for function
; Parameters:
;   RCX = pointer to function AST node
; ============================================================================
ir_generate_function:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    push rbx
    push r12
    
    mov rbx, rcx        ; Function AST node
    
    ; Reset loop depth
    mov qword [loop_depth], 0
    
    ; Get function info
    mov rcx, [rbx + 16]     ; name
    mov rdx, [rbx + 24]     ; name_len
    
    ; Get return type
    mov r12, [rbx + 48]     ; return_type node
    test r12, r12
    jz .void_return
    mov r8, [r12 + 16]      ; type kind
    jmp .create_func
    
.void_return:
    mov r8, TYPE_VOID
    
.create_func:
    call ir_function_create
    test rax, rax
    jz .error
    
    ; Generate IR for function body
    mov r12, [rbx + 56]     ; body (block statement)
    test r12, r12
    jz .no_body
    
    mov rcx, r12
    call ir_generate_statement
    
.no_body:
.error:
    pop r12
    pop rbx
    add rsp, 64
    pop rbp
    ret

; ============================================================================
; ir_generate_statement - Generate IR for statement
; Parameters:
;   RCX = pointer to statement AST node
; Returns:
;   Nothing
; ============================================================================
ir_generate_statement:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    
    mov rbx, rcx
    test rbx, rbx
    jz .done
    
    ; Get statement type
    mov rax, [rbx]
    
    ; Dispatch based on statement type
    cmp rax, AST_BLOCK
    je .block
    cmp rax, AST_LET_STMT
    je .let_stmt
    cmp rax, AST_ASSIGN_STMT
    je .assign_stmt
    cmp rax, AST_RETURN_STMT
    je .return_stmt
    cmp rax, AST_IF_STMT
    je .if_stmt
    cmp rax, AST_WHILE_STMT
    je .while_stmt
    cmp rax, AST_FOR_STMT
    je .for_stmt
    cmp rax, AST_EXPR_STMT
    je .expr_stmt
    
    ; Unknown statement type
    jmp .done
    
.block:
    mov rcx, rbx
    call ir_generate_block
    jmp .done
    
.let_stmt:
    mov rcx, rbx
    call ir_generate_let
    jmp .done
    
.assign_stmt:
    mov rcx, rbx
    call ir_generate_assign
    jmp .done
    
.return_stmt:
    mov rcx, rbx
    call ir_generate_return
    jmp .done
    
.if_stmt:
    mov rcx, rbx
    call ir_generate_if
    jmp .done
    
.while_stmt:
    mov rcx, rbx
    call ir_generate_while
    jmp .done
    
.for_stmt:
    mov rcx, rbx
    call ir_generate_for
    jmp .done
    
.expr_stmt:
    ; Just generate the expression (for side effects like function calls)
    mov rcx, [rbx + 16]
    call ir_generate_expression
    jmp .done
    
.done:
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; ir_generate_block - Generate IR for block statement
; Parameters:
;   RCX = pointer to block AST node
; ============================================================================
ir_generate_block:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    
    mov rbx, rcx
    
    ; Get statements list
    mov r12, [rbx + 8]      ; statements at offset 8
    
.gen_stmt_loop:
    test r12, r12
    jz .done
    
    ; Generate statement
    mov rcx, [r12]
    call ir_generate_statement
    
    ; Next statement
    mov r12, [r12 + 8]
    jmp .gen_stmt_loop
    
.done:
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; ir_generate_let - Generate IR for let statement
; Parameters:
;   RCX = pointer to let statement AST node
; ============================================================================
ir_generate_let:
    push rbp
    mov rbp, rsp
    sub rsp, 96
    push rbx
    push r12
    push r13
    
    mov rbx, rcx
    
    ; Check if there's an initializer
    mov rcx, [rbx + 48]     ; initializer at offset 48
    test rcx, rcx
    jz .no_init
    
    ; Generate expression for initializer
    call ir_generate_expression
    mov r12, rax            ; Save result operand
    
    ; Create variable operand for destination
    mov rcx, IROperand_size
    call arena_alloc
    test rax, rax
    jz .no_init
    
    mov r13, rax            ; dest operand
    
    ; Fill in variable operand
    mov rcx, r13
    mov rdx, [rbx + 16]     ; variable name
    mov r8, [rbx + 24]      ; name length
    mov r9, TYPE_I32        ; TODO: get actual type
    call ir_operand_var
    
    ; Emit move instruction: var = temp
    mov rcx, r13            ; dest
    mov rdx, r12            ; src (result from expression)
    call ir_emit_move
    
.no_init:
    pop r13
    pop r12
    pop rbx
    add rsp, 96
    pop rbp
    ret

; ============================================================================
; ir_generate_assign - Generate IR for assignment statement
; Parameters:
;   RCX = pointer to assignment AST node
; ============================================================================
ir_generate_assign:
    push rbp
    mov rbp, rsp
    sub rsp, 96
    push rbx
    push r12
    push r13
    
    mov rbx, rcx
    
    ; Generate value expression
    mov rcx, [rbx + 24]     ; value at offset 24
    call ir_generate_expression
    mov r12, rax            ; Save result operand
    
    ; Get target (should be identifier for now)
    mov r13, [rbx + 16]     ; target at offset 16
    
    ; Create variable operand for target
    mov rcx, IROperand_size
    call arena_alloc
    test rax, rax
    jz .done
    
    push rax
    mov rcx, rax
    mov rdx, [r13 + 16]     ; identifier name
    mov r8, [r13 + 24]      ; name length
    mov r9, TYPE_I32        ; TODO: get actual type
    call ir_operand_var
    pop rax
    
    ; Emit move: target = value
    mov rcx, rax            ; dest
    mov rdx, r12            ; src
    call ir_emit_move
    
.done:
    pop r13
    pop r12
    pop rbx
    add rsp, 96
    pop rbp
    ret

; ============================================================================
; ir_generate_return - Generate IR for return statement
; Parameters:
;   RCX = pointer to return statement AST node
; ============================================================================
ir_generate_return:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    
    mov rbx, rcx
    
    ; Check if there's a return value
    mov rcx, [rbx + 16]     ; value at offset 16
    test rcx, rcx
    jz .void_return
    
    ; Generate expression
    call ir_generate_expression
    
    ; Emit return with value
    mov rcx, rax
    call ir_emit_return
    jmp .done
    
.void_return:
    ; Emit void return
    xor rcx, rcx
    call ir_emit_return
    
.done:
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; ir_generate_if - Generate IR for if statement
; Parameters:
;   RCX = pointer to if statement AST node
; ============================================================================
ir_generate_if:
    push rbp
    mov rbp, rsp
    sub rsp, 96
    push rbx
    push r12
    push r13
    push r14
    
    mov rbx, rcx
    
    ; Allocate labels
    call ir_new_label
    mov r12, rax            ; else_label or end_label
    
    call ir_new_label
    mov r13, rax            ; end_label
    
    ; Generate condition expression
    mov rcx, [rbx + 16]     ; condition at offset 16
    call ir_generate_expression
    mov r14, rax            ; Save condition result
    
    ; Check if there's an else branch
    mov rax, [rbx + 32]     ; else_block at offset 32
    test rax, rax
    jz .no_else
    
    ; Emit: JUMP_IF_NOT condition, else_label
    ; TODO: emit jump_if_not instruction
    
    ; Generate then block
    mov rcx, [rbx + 24]     ; then_block at offset 24
    call ir_generate_statement
    
    ; Emit: JUMP end_label
    ; TODO: emit jump instruction
    
    ; Emit: else_label:
    ; TODO: emit label
    
    ; Generate else block
    mov rcx, [rbx + 32]
    call ir_generate_statement
    
    jmp .end_if
    
.no_else:
    ; Emit: JUMP_IF_NOT condition, end_label
    ; TODO: emit jump_if_not instruction
    
    ; Generate then block
    mov rcx, [rbx + 24]
    call ir_generate_statement
    
.end_if:
    ; Emit: end_label:
    ; TODO: emit label
    
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 96
    pop rbp
    ret

; ============================================================================
; ir_generate_while - Generate IR for while loop
; Parameters:
;   RCX = pointer to while statement AST node
; ============================================================================
ir_generate_while:
    push rbp
    mov rbp, rsp
    sub rsp, 96
    push rbx
    push r12
    push r13
    push r14
    
    mov rbx, rcx
    
    ; Allocate labels
    call ir_new_label
    mov r12, rax            ; loop_start
    
    call ir_new_label
    mov r13, rax            ; loop_end
    
    ; Push labels to break/continue stacks
    mov rax, [loop_depth]
    mov [continue_label_stack + rax * 8], r12
    mov [break_label_stack + rax * 8], r13
    inc qword [loop_depth]
    
    ; Emit: loop_start:
    ; TODO: emit label
    
    ; Generate condition
    mov rcx, [rbx + 16]
    call ir_generate_expression
    mov r14, rax
    
    ; Emit: JUMP_IF_NOT condition, loop_end
    ; TODO: emit jump_if_not
    
    ; Generate body
    mov rcx, [rbx + 24]
    call ir_generate_statement
    
    ; Emit: JUMP loop_start
    ; TODO: emit jump
    
    ; Emit: loop_end:
    ; TODO: emit label
    
    ; Pop loop depth
    dec qword [loop_depth]
    
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 96
    pop rbp
    ret

; ============================================================================
; ir_generate_for - Generate IR for for loop
; Parameters:
;   RCX = pointer to for statement AST node
; ============================================================================
ir_generate_for:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    
    mov rbx, rcx
    
    ; For loop: similar to while but with implicit iterator
    ; TODO: Implement full for loop generation
    ; For now, just generate body
    
    mov rcx, [rbx + 48]     ; body
    test rcx, rcx
    jz .done
    
    call ir_generate_statement
    
.done:
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; ir_generate_expression - Generate IR for expression
; Parameters:
;   RCX = pointer to expression AST node
; Returns:
;   RAX = pointer to IROperand (result)
; ============================================================================
ir_generate_expression:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    
    mov rbx, rcx
    test rbx, rbx
    jz .error
    
    ; Get expression type
    mov rax, [rbx]
    
    cmp rax, AST_LITERAL_EXPR
    je .literal
    cmp rax, AST_IDENTIFIER
    je .identifier
    cmp rax, AST_BINARY_EXPR
    je .binary
    cmp rax, AST_UNARY_EXPR
    je .unary
    
.error:
    xor rax, rax
    jmp .done
    
.literal:
    mov rcx, rbx
    call ir_generate_literal
    jmp .done
    
.identifier:
    mov rcx, rbx
    call ir_generate_identifier
    jmp .done
    
.binary:
    mov rcx, rbx
    call ir_generate_binary
    jmp .done
    
.unary:
    mov rcx, rbx
    call ir_generate_unary
    jmp .done
    
.done:
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; ir_generate_literal - Generate IR for literal expression
; Parameters:
;   RCX = pointer to literal AST node
; Returns:
;   RAX = pointer to IROperand (constant)
; ============================================================================
ir_generate_literal:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    
    mov rbx, rcx
    
    ; Allocate operand
    mov rcx, IROperand_size
    call arena_alloc
    test rax, rax
    jz .error
    
    mov r12, rax
    
    ; Create constant operand
    mov rcx, r12
    mov rdx, [rbx + 16]     ; value
    mov r8, TYPE_I32        ; TODO: get actual type
    call ir_operand_const
    
    mov rax, r12
    jmp .done
    
.error:
    xor rax, rax
    
.done:
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; ir_generate_identifier - Generate IR for identifier expression
; Parameters:
;   RCX = pointer to identifier AST node
; Returns:
;   RAX = pointer to IROperand (variable)
; ============================================================================
ir_generate_identifier:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    
    mov rbx, rcx
    
    ; Allocate operand
    mov rcx, IROperand_size
    call arena_alloc
    test rax, rax
    jz .error
    
    mov r12, rax
    
    ; Create variable operand
    mov rcx, r12
    mov rdx, [rbx + 16]     ; name
    mov r8, [rbx + 24]      ; length
    mov r9, TYPE_I32        ; TODO: get actual type
    call ir_operand_var
    
    mov rax, r12
    jmp .done
    
.error:
    xor rax, rax
    
.done:
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; ir_generate_binary - Generate IR for binary expression
; Parameters:
;   RCX = pointer to binary expression AST node
; Returns:
;   RAX = pointer to IROperand (temporary with result)
; ============================================================================
ir_generate_binary:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    mov rbx, rcx
    
    ; Generate left operand
    mov rcx, [rbx + 16]
    call ir_generate_expression
    mov r12, rax            ; left operand
    
    ; Generate right operand
    mov rcx, [rbx + 24]
    call ir_generate_expression
    mov r13, rax            ; right operand
    
    ; Get operator and convert to IR opcode
    mov r14, [rbx + 32]     ; operator token type
    call token_to_ir_opcode
    mov r15, rax            ; IR opcode
    
    ; Allocate new temporary for result
    call ir_new_temp
    push rax
    
    ; Create temporary operand for destination
    mov rcx, IROperand_size
    call arena_alloc
    test rax, rax
    jz .error
    
    mov rbx, rax            ; dest operand
    pop rax
    push rax
    
    mov rcx, rbx
    mov rdx, rax            ; temp number
    mov r8, TYPE_I32        ; TODO: get actual type
    call ir_operand_temp
    
    pop rax
    
    ; Emit binary instruction
    mov rcx, r15            ; opcode
    mov rdx, rbx            ; dest
    mov r8, r12             ; src1
    mov r9, r13             ; src2
    call ir_emit_binary
    
    ; Return dest operand
    mov rax, rbx
    jmp .done
    
.error:
    add rsp, 8              ; Clean up pushed temp
    xor rax, rax
    
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 128
    pop rbp
    ret

; ============================================================================
; ir_generate_unary - Generate IR for unary expression
; Parameters:
;   RCX = pointer to unary expression AST node
; Returns:
;   RAX = pointer to IROperand (temporary with result)
; ============================================================================
ir_generate_unary:
    push rbp
    mov rbp, rsp
    sub rsp, 96
    push rbx
    push r12
    push r13
    push r14
    
    mov rbx, rcx
    
    ; Generate operand
    mov rcx, [rbx + 16]
    call ir_generate_expression
    mov r12, rax            ; operand
    
    ; Get operator
    mov r13, [rbx + 8]      ; operator token type
    ; TODO: Convert to IR opcode
    mov r14, IR_NEG         ; Default to NEG for now
    
    ; Allocate temporary
    call ir_new_temp
    push rax
    
    mov rcx, IROperand_size
    call arena_alloc
    test rax, rax
    jz .error
    
    mov rbx, rax
    pop rax
    
    mov rcx, rbx
    mov rdx, rax
    mov r8, TYPE_I32
    call ir_operand_temp
    
    ; TODO: Emit unary instruction
    
    mov rax, rbx
    jmp .done
    
.error:
    add rsp, 8
    xor rax, rax
    
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 96
    pop rbp
    ret

; ============================================================================
; token_to_ir_opcode - Convert token type to IR opcode
; Parameters:
;   RAX = token type
; Returns:
;   RAX = IR opcode
; ============================================================================
token_to_ir_opcode:
    push rbp
    mov rbp, rsp
    
    cmp rax, TOKEN_PLUS
    je .plus
    cmp rax, TOKEN_MINUS
    je .minus
    cmp rax, TOKEN_STAR
    je .mul
    cmp rax, TOKEN_SLASH
    je .div
    cmp rax, TOKEN_PERCENT
    je .mod
    cmp rax, TOKEN_EQ_EQ
    je .eq
    cmp rax, TOKEN_BANG_EQ
    je .ne
    cmp rax, TOKEN_LT
    je .lt
    cmp rax, TOKEN_LT_EQ
    je .le
    cmp rax, TOKEN_GT
    je .gt
    cmp rax, TOKEN_GT_EQ
    je .ge
    
    ; Default to ADD
    mov rax, IR_ADD
    jmp .done
    
.plus:
    mov rax, IR_ADD
    jmp .done
.minus:
    mov rax, IR_SUB
    jmp .done
.mul:
    mov rax, IR_MUL
    jmp .done
.div:
    mov rax, IR_DIV
    jmp .done
.mod:
    mov rax, IR_MOD
    jmp .done
.eq:
    mov rax, IR_EQ
    jmp .done
.ne:
    mov rax, IR_NE
    jmp .done
.lt:
    mov rax, IR_LT
    jmp .done
.le:
    mov rax, IR_LE
    jmp .done
.gt:
    mov rax, IR_GT
    jmp .done
.ge:
    mov rax, IR_GE
    jmp .done
    
.done:
    pop rbp
    ret
