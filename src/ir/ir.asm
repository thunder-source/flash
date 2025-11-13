; ============================================================================
; Flash Compiler - Intermediate Representation (IR)
; ============================================================================
; Three-Address Code (TAC) IR for the Flash compiler
; Simple, optimizable, and easy to translate to machine code
; ============================================================================

bits 64
default rel

; ============================================================================
; IR Opcode Definitions
; ============================================================================

; Arithmetic operations (0-19)
%define IR_ADD          0       ; dest = src1 + src2
%define IR_SUB          1       ; dest = src1 - src2
%define IR_MUL          2       ; dest = src1 * src2
%define IR_DIV          3       ; dest = src1 / src2
%define IR_MOD          4       ; dest = src1 % src2
%define IR_NEG          5       ; dest = -src1

; Bitwise operations (20-29)
%define IR_AND          20      ; dest = src1 & src2
%define IR_OR           21      ; dest = src1 | src2
%define IR_XOR          22      ; dest = src1 ^ src2
%define IR_NOT          23      ; dest = ~src1
%define IR_SHL          24      ; dest = src1 << src2
%define IR_SHR          25      ; dest = src1 >> src2

; Comparison operations (30-39)
%define IR_EQ           30      ; dest = src1 == src2
%define IR_NE           31      ; dest = src1 != src2
%define IR_LT           32      ; dest = src1 < src2
%define IR_LE           33      ; dest = src1 <= src2
%define IR_GT           34      ; dest = src1 > src2
%define IR_GE           35      ; dest = src1 >= src2

; Memory operations (40-49)
%define IR_MOVE         40      ; dest = src1 (copy)
%define IR_LOAD         41      ; dest = *src1 (load from memory)
%define IR_STORE        42      ; *dest = src1 (store to memory)
%define IR_ADDR         43      ; dest = &src1 (address of)
%define IR_ALLOC        44      ; dest = alloc(size)

; Control flow (50-69)
%define IR_LABEL        50      ; label:
%define IR_JUMP         51      ; goto label
%define IR_JUMP_IF      52      ; if src1 goto label
%define IR_JUMP_IF_NOT  53      ; if !src1 goto label
%define IR_CALL         54      ; dest = call func(args...)
%define IR_RETURN       55      ; return src1
%define IR_RETURN_VOID  56      ; return (void)
%define IR_PARAM        57      ; param src1 (pass parameter)

; Type conversions (70-79)
%define IR_CAST         70      ; dest = (type)src1
%define IR_ZEXT         71      ; dest = zero_extend(src1)
%define IR_SEXT         72      ; dest = sign_extend(src1)
%define IR_TRUNC        73      ; dest = truncate(src1)

; Array/struct operations (80-89)
%define IR_INDEX        80      ; dest = src1[src2]
%define IR_FIELD        81      ; dest = src1.field
%define IR_ARRAY_ALLOC  82      ; dest = alloc_array(count, elem_size)

; Special (90-99)
%define IR_NOP          90      ; no operation
%define IR_PHI          91      ; dest = phi(src1, src2, ...) for SSA

; ============================================================================
; IR Operand Types
; ============================================================================
%define IR_OP_TEMP      0       ; Temporary (virtual register)
%define IR_OP_VAR       1       ; Variable (named)
%define IR_OP_CONST     2       ; Constant (immediate)
%define IR_OP_LABEL     3       ; Label (for jumps)
%define IR_OP_FUNC      4       ; Function name
%define IR_OP_NONE      5       ; No operand

; ============================================================================
; IR Operand Structure
; ============================================================================
struc IROperand
    .type:          resq 1      ; Operand type (IR_OP_TEMP, etc.)
    .value:         resq 1      ; Value (temp number, var name, constant, label)
    .data_type:     resq 1      ; Data type (TYPE_I32, etc.)
    .aux:           resq 1      ; Auxiliary data (string length for vars, etc.)
endstruc

; ============================================================================
; IR Instruction Structure
; ============================================================================
struc IRInstruction
    .opcode:        resq 1      ; IR opcode
    .dest:          resb IROperand_size     ; Destination operand
    .src1:          resb IROperand_size     ; Source operand 1
    .src2:          resb IROperand_size     ; Source operand 2
    .line:          resq 1      ; Source line number
    .next:          resq 1      ; Next instruction in list
endstruc

; ============================================================================
; IR Function Structure
; ============================================================================
struc IRFunction
    .name:          resq 1      ; Function name
    .name_len:      resq 1      ; Name length
    .params:        resq 1      ; Array of IROperand (parameters)
    .param_count:   resq 1      ; Number of parameters
    .return_type:   resq 1      ; Return type
    .instructions:  resq 1      ; First instruction
    .last_inst:     resq 1      ; Last instruction (for easy append)
    .temp_count:    resq 1      ; Number of temporaries used
    .label_count:   resq 1      ; Number of labels used
    .next:          resq 1      ; Next function in program
endstruc

; ============================================================================
; IR Program Structure
; ============================================================================
struc IRProgram
    .functions:     resq 1      ; First function
    .last_func:     resq 1      ; Last function (for easy append)
    .func_count:    resq 1      ; Number of functions
    .global_vars:   resq 1      ; Global variables list
endstruc

; ============================================================================
; Data Section
; ============================================================================
section .bss
    current_ir_func:    resq 1      ; Current function being generated
    current_program:    resq 1      ; Current IR program

section .text

global ir_program_create
global ir_function_create
global ir_instruction_create
global ir_operand_temp
global ir_operand_var
global ir_operand_const
global ir_operand_label
global ir_emit
global ir_emit_label
global ir_emit_binary
global ir_emit_unary
global ir_emit_move
global ir_emit_jump
global ir_emit_jump_if
global ir_emit_call
global ir_emit_return
global ir_new_temp
global ir_new_label

extern arena_alloc

; ============================================================================
; ir_program_create - Create new IR program
; Returns:
;   RAX = pointer to IRProgram
; ============================================================================
ir_program_create:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    mov rcx, IRProgram_size
    call arena_alloc
    test rax, rax
    jz .error
    
    ; Initialize program
    mov qword [rax + IRProgram.functions], 0
    mov qword [rax + IRProgram.last_func], 0
    mov qword [rax + IRProgram.func_count], 0
    mov qword [rax + IRProgram.global_vars], 0
    
    mov [current_program], rax
    
.error:
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; ir_function_create - Create new IR function
; Parameters:
;   RCX = function name pointer
;   RDX = function name length
;   R8  = return type
; Returns:
;   RAX = pointer to IRFunction
; ============================================================================
ir_function_create:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    
    mov rbx, rcx    ; name
    mov r12, rdx    ; name_len
    mov r13, r8     ; return_type
    
    mov rcx, IRFunction_size
    call arena_alloc
    test rax, rax
    jz .error
    
    ; Initialize function
    mov [rax + IRFunction.name], rbx
    mov [rax + IRFunction.name_len], r12
    mov qword [rax + IRFunction.params], 0
    mov qword [rax + IRFunction.param_count], 0
    mov [rax + IRFunction.return_type], r13
    mov qword [rax + IRFunction.instructions], 0
    mov qword [rax + IRFunction.last_inst], 0
    mov qword [rax + IRFunction.temp_count], 1    ; Start at 1 to distinguish from error (0)
    mov qword [rax + IRFunction.label_count], 1   ; Start at 1 to distinguish from error (0)
    mov qword [rax + IRFunction.next], 0
    
    ; Add to program if one exists
    mov rcx, [current_program]
    test rcx, rcx
    jz .no_program
    
    ; Append to program's function list
    mov rdx, [rcx + IRProgram.last_func]
    test rdx, rdx
    jz .first_func
    
    ; Add after last function
    mov [rdx + IRFunction.next], rax
    mov [rcx + IRProgram.last_func], rax
    jmp .update_count
    
.first_func:
    mov [rcx + IRProgram.functions], rax
    mov [rcx + IRProgram.last_func], rax
    
.update_count:
    inc qword [rcx + IRProgram.func_count]
    
.no_program:
    mov [current_ir_func], rax
    
.error:
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; ir_instruction_create - Create new IR instruction
; Parameters:
;   RCX = opcode
; Returns:
;   RAX = pointer to IRInstruction
; ============================================================================
ir_instruction_create:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    
    mov rbx, rcx    ; opcode
    
    mov rcx, IRInstruction_size
    call arena_alloc
    test rax, rax
    jz .error
    
    ; Initialize instruction
    mov [rax + IRInstruction.opcode], rbx
    mov qword [rax + IRInstruction.line], 0
    mov qword [rax + IRInstruction.next], 0
    
    ; Initialize operands to NONE
    lea rcx, [rax + IRInstruction.dest]
    mov qword [rcx + IROperand.type], IR_OP_NONE
    
    lea rcx, [rax + IRInstruction.src1]
    mov qword [rcx + IROperand.type], IR_OP_NONE
    
    lea rcx, [rax + IRInstruction.src2]
    mov qword [rcx + IROperand.type], IR_OP_NONE
    
.error:
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; ir_operand_temp - Create temporary operand
; Parameters:
;   RCX = pointer to operand structure
;   RDX = temp number
;   R8  = data type
; ============================================================================
ir_operand_temp:
    push rbp
    mov rbp, rsp
    
    mov qword [rcx + IROperand.type], IR_OP_TEMP
    mov [rcx + IROperand.value], rdx
    mov [rcx + IROperand.data_type], r8
    mov qword [rcx + IROperand.aux], 0
    
    pop rbp
    ret

; ============================================================================
; ir_operand_var - Create variable operand
; Parameters:
;   RCX = pointer to operand structure
;   RDX = variable name pointer
;   R8  = variable name length
;   R9  = data type
; ============================================================================
ir_operand_var:
    push rbp
    mov rbp, rsp
    
    mov qword [rcx + IROperand.type], IR_OP_VAR
    mov [rcx + IROperand.value], rdx
    mov [rcx + IROperand.aux], r8
    mov [rcx + IROperand.data_type], r9
    
    pop rbp
    ret

; ============================================================================
; ir_operand_const - Create constant operand
; Parameters:
;   RCX = pointer to operand structure
;   RDX = constant value
;   R8  = data type
; ============================================================================
ir_operand_const:
    push rbp
    mov rbp, rsp
    
    mov qword [rcx + IROperand.type], IR_OP_CONST
    mov [rcx + IROperand.value], rdx
    mov [rcx + IROperand.data_type], r8
    mov qword [rcx + IROperand.aux], 0
    
    pop rbp
    ret

; ============================================================================
; ir_operand_label - Create label operand
; Parameters:
;   RCX = pointer to operand structure
;   RDX = label number
; ============================================================================
ir_operand_label:
    push rbp
    mov rbp, rsp
    
    mov qword [rcx + IROperand.type], IR_OP_LABEL
    mov [rcx + IROperand.value], rdx
    mov qword [rcx + IROperand.data_type], 0
    mov qword [rcx + IROperand.aux], 0
    
    pop rbp
    ret

; ============================================================================
; ir_emit - Emit instruction to current function
; Parameters:
;   RCX = pointer to IRInstruction
; ============================================================================
ir_emit:
    push rbp
    mov rbp, rsp
    push rbx
    
    mov rbx, rcx    ; instruction
    mov rcx, [current_ir_func]
    test rcx, rcx
    jz .no_function
    
    ; Get last instruction
    mov rdx, [rcx + IRFunction.last_inst]
    test rdx, rdx
    jz .first_inst
    
    ; Append after last
    mov [rdx + IRInstruction.next], rbx
    mov [rcx + IRFunction.last_inst], rbx
    jmp .done
    
.first_inst:
    mov [rcx + IRFunction.instructions], rbx
    mov [rcx + IRFunction.last_inst], rbx
    
.done:
.no_function:
    pop rbx
    pop rbp
    ret

; ============================================================================
; ir_new_temp - Allocate new temporary register
; Returns:
;   RAX = temporary number
; ============================================================================
ir_new_temp:
    push rbp
    mov rbp, rsp
    
    mov rax, [current_ir_func]
    test rax, rax
    jz .error
    
    mov rcx, [rax + IRFunction.temp_count]
    mov rax, rcx
    inc rcx
    mov rdx, [current_ir_func]
    mov [rdx + IRFunction.temp_count], rcx
    jmp .done
    
.error:
    xor rax, rax
    
.done:
    pop rbp
    ret

; ============================================================================
; ir_new_label - Allocate new label number
; Returns:
;   RAX = label number
; ============================================================================
ir_new_label:
    push rbp
    mov rbp, rsp
    
    mov rax, [current_ir_func]
    test rax, rax
    jz .error
    
    mov rcx, [rax + IRFunction.label_count]
    mov rax, rcx
    inc rcx
    mov rdx, [current_ir_func]
    mov [rdx + IRFunction.label_count], rcx
    jmp .done
    
.error:
    xor rax, rax
    
.done:
    pop rbp
    ret

; ============================================================================
; ir_emit_binary - Emit binary operation instruction
; Parameters:
;   RCX = opcode
;   RDX = dest operand ptr
;   R8  = src1 operand ptr
;   R9  = src2 operand ptr
; Returns:
;   RAX = pointer to created instruction
; ============================================================================
ir_emit_binary:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    push rbx
    push r12
    push r13
    push r14
    
    mov rbx, rcx    ; opcode
    mov r12, rdx    ; dest
    mov r13, r8     ; src1
    mov r14, r9     ; src2
    
    ; Create instruction
    mov rcx, rbx
    call ir_instruction_create
    test rax, rax
    jz .error
    
    push rax
    
    ; Copy operands
    lea rcx, [rax + IRInstruction.dest]
    mov rsi, r12
    mov rdi, rcx
    mov rcx, IROperand_size
    rep movsb
    
    pop rax
    push rax
    
    lea rcx, [rax + IRInstruction.src1]
    mov rsi, r13
    mov rdi, rcx
    mov rcx, IROperand_size
    rep movsb
    
    pop rax
    push rax
    
    lea rcx, [rax + IRInstruction.src2]
    mov rsi, r14
    mov rdi, rcx
    mov rcx, IROperand_size
    rep movsb
    
    pop rax
    push rax
    
    ; Emit instruction
    mov rcx, rax
    call ir_emit
    
    pop rax
    jmp .done
    
.error:
    xor rax, rax
    
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 64
    pop rbp
    ret

; ============================================================================
; ir_emit_move - Emit move instruction
; Parameters:
;   RCX = dest operand ptr
;   RDX = src operand ptr
; Returns:
;   RAX = pointer to created instruction
; ============================================================================
ir_emit_move:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    
    mov rbx, rcx    ; dest
    mov r12, rdx    ; src
    
    mov rcx, IR_MOVE
    call ir_instruction_create
    test rax, rax
    jz .error
    
    push rax
    
    ; Copy dest
    lea rcx, [rax + IRInstruction.dest]
    mov rsi, rbx
    mov rdi, rcx
    mov rcx, IROperand_size
    rep movsb
    
    pop rax
    push rax
    
    ; Copy src1
    lea rcx, [rax + IRInstruction.src1]
    mov rsi, r12
    mov rdi, rcx
    mov rcx, IROperand_size
    rep movsb
    
    pop rax
    push rax
    
    ; Emit
    mov rcx, rax
    call ir_emit
    
    pop rax
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
; ir_emit_return - Emit return instruction
; Parameters:
;   RCX = src operand ptr (or 0 for void return)
; Returns:
;   RAX = pointer to created instruction
; ============================================================================
ir_emit_return:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    
    mov rbx, rcx    ; src operand
    
    ; Choose opcode based on whether we have a value
    test rbx, rbx
    jz .void_return
    
    mov rcx, IR_RETURN
    jmp .create
    
.void_return:
    mov rcx, IR_RETURN_VOID
    
.create:
    call ir_instruction_create
    test rax, rax
    jz .error
    
    ; Copy src operand if provided
    test rbx, rbx
    jz .no_src
    
    push rax
    lea rcx, [rax + IRInstruction.src1]
    mov rsi, rbx
    mov rdi, rcx
    mov rcx, IROperand_size
    rep movsb
    pop rax
    
.no_src:
    push rax
    mov rcx, rax
    call ir_emit
    pop rax
    jmp .done
    
.error:
    xor rax, rax
    
.done:
    pop rbx
    add rsp, 32
    pop rbp
    ret
