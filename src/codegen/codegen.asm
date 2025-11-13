; ============================================================================
; Flash Compiler - Code Generator
; ============================================================================
; x86-64 code generation from Three-Address Code IR
; Implements register allocation, instruction selection, and emission
; ============================================================================

bits 64
default rel

; ============================================================================
; External Dependencies
; ============================================================================
extern arena_alloc
extern regalloc_reset
extern regalloc_get_register

; ============================================================================
; x86-64 Register Definitions
; ============================================================================
%define REG_RAX     0
%define REG_RBX     1
%define REG_RCX     2
%define REG_RDX     3
%define REG_RSI     4
%define REG_RDI     5
%define REG_RBP     6
%define REG_RSP     7
%define REG_R8      8
%define REG_R9      9
%define REG_R10     10
%define REG_R11     11
%define REG_R12     12
%define REG_R13     13
%define REG_R14     14
%define REG_R15     15
%define REG_NONE    255

; ============================================================================
; Register Allocation Strategy
; ============================================================================
; Caller-saved (volatile): RAX, RCX, RDX, R8, R9, R10, R11
; Callee-saved (non-volatile): RBX, RBP, RDI, RSI, RSP, R12-R15
;
; Windows x64 calling convention:
;   First 4 integer params: RCX, RDX, R8, R9
;   Return value: RAX
;   Stack aligned to 16 bytes
;   Shadow space: 32 bytes for 4 register params
;
; Available for general allocation:
;   RBX, RSI, RDI, R10, R11, R12, R13, R14, R15
; ============================================================================

; ============================================================================
; Code Generator Context Structure
; ============================================================================
struc CodeGenContext
    .output_buffer:     resq 1      ; Pointer to output assembly text buffer
    .output_size:       resq 1      ; Current size of output buffer
    .output_capacity:   resq 1      ; Capacity of output buffer
    .current_func:      resq 1      ; Current function being generated
    .stack_size:        resq 1      ; Current function stack size
    .temp_map:          resq 256    ; Map from temp number to physical register
    .temp_offset:       resq 256    ; Map from temp number to stack offset (if spilled)
    .reg_free:          resb 16     ; Free/used status of physical registers
    .label_count:       resq 1      ; Label counter for generated labels
endstruc

; ============================================================================
; Register Name Strings
; ============================================================================
section .data
    reg_names_64:
        dq str_rax, str_rbx, str_rcx, str_rdx
        dq str_rsi, str_rdi, str_rbp, str_rsp
        dq str_r8,  str_r9,  str_r10, str_r11
        dq str_r12, str_r13, str_r14, str_r15
    
    reg_names_32:
        dq str_eax, str_ebx, str_ecx, str_edx
        dq str_esi, str_edi, str_ebp, str_esp
        dq str_r8d,  str_r9d,  str_r10d, str_r11d
        dq str_r12d, str_r13d, str_r14d, str_r15d
    
    ; Register name strings
    str_rax     db "rax", 0
    str_rbx     db "rbx", 0
    str_rcx     db "rcx", 0
    str_rdx     db "rdx", 0
    str_rsi     db "rsi", 0
    str_rdi     db "rdi", 0
    str_rbp     db "rbp", 0
    str_rsp     db "rsp", 0
    str_r8      db "r8", 0
    str_r9      db "r9", 0
    str_r10     db "r10", 0
    str_r11     db "r11", 0
    str_r12     db "r12", 0
    str_r13     db "r13", 0
    str_r14     db "r14", 0
    str_r15     db "r15", 0
    str_eax     db "eax", 0
    str_ebx     db "ebx", 0
    str_ecx     db "ecx", 0
    str_edx     db "edx", 0
    str_esi     db "esi", 0
    str_edi     db "edi", 0
    str_ebp     db "ebp", 0
    str_esp     db "esp", 0
    str_r8d     db "r8d", 0
    str_r9d     db "r9d", 0
    str_r10d    db "r10d", 0
    str_r11d    db "r11d", 0
    str_r12d    db "r12d", 0
    str_r13d    db "r13d", 0
    str_r14d    db "r14d", 0
    str_r15d    db "r15d", 0
    
    ; Assembly template strings
    str_section_text    db "section .text", 10, 0
    str_section_data    db "section .data", 10, 0
    str_section_bss     db "section .bss", 10, 0
    str_global          db "global ", 0
    str_extern          db "extern ", 0
    str_bits64          db "bits 64", 10, 0
    str_default_rel     db "default rel", 10, 0
    str_newline         db 10, 0
    str_tab             db 9, 0
    str_comma           db ", ", 0
    str_colon           db ":", 0
    
    ; Instruction mnemonics
    str_mov     db "mov", 0
    str_add     db "add", 0
    str_sub     db "sub", 0
    str_imul    db "imul", 0
    str_idiv    db "idiv", 0
    str_and     db "and", 0
    str_or      db "or", 0
    str_xor     db "xor", 0
    str_not     db "not", 0
    str_neg     db "neg", 0
    str_shl     db "shl", 0
    str_shr     db "shr", 0
    str_cmp     db "cmp", 0
    str_test    db "test", 0
    str_jmp     db "jmp", 0
    str_je      db "je", 0
    str_jne     db "jne", 0
    str_jl      db "jl", 0
    str_jle     db "jle", 0
    str_jg      db "jg", 0
    str_jge     db "jge", 0
    str_call    db "call", 0
    str_ret     db "ret", 0
    str_push    db "push", 0
    str_pop     db "pop", 0
    str_lea     db "lea", 0
    
    ; Function prologue/epilogue templates
    str_prologue_push_rbp       db "    push rbp", 10, 0
    str_prologue_mov_rbp_rsp    db "    mov rbp, rsp", 10, 0
    str_prologue_sub_rsp        db "    sub rsp, ", 0
    str_epilogue_mov_rsp_rbp    db "    mov rsp, rbp", 10, 0
    str_epilogue_pop_rbp        db "    pop rbp", 10, 0
    str_epilogue_ret            db "    ret", 10, 0

; ============================================================================
; BSS Section
; ============================================================================
section .bss
    codegen_context:    resb CodeGenContext_size

; ============================================================================
; Code Section
; ============================================================================
section .text

; ============================================================================
; Global Functions and Data
; ============================================================================
global codegen_init
global codegen_generate_program
global codegen_generate_function
global codegen_emit_instruction
global codegen_get_output
global codegen_context

; ============================================================================
; codegen_init - Initialize code generator
; ============================================================================
codegen_init:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Allocate output buffer (64KB initial size)
    mov rcx, 65536
    call arena_alloc
    test rax, rax
    jz .error
    
    ; Initialize context
    mov [codegen_context + CodeGenContext.output_buffer], rax
    mov qword [codegen_context + CodeGenContext.output_size], 0
    mov qword [codegen_context + CodeGenContext.output_capacity], 65536
    mov qword [codegen_context + CodeGenContext.current_func], 0
    mov qword [codegen_context + CodeGenContext.stack_size], 0
    mov qword [codegen_context + CodeGenContext.label_count], 0
    
    ; Initialize register allocation arrays
    xor rcx, rcx
.init_temps:
    cmp rcx, 256
    jge .init_regs
    mov qword [codegen_context + CodeGenContext.temp_map + rcx*8], REG_NONE
    mov qword [codegen_context + CodeGenContext.temp_offset + rcx*8], 0
    inc rcx
    jmp .init_temps
    
.init_regs:
    ; Mark all registers as free initially
    xor rcx, rcx
.init_regs_loop:
    cmp rcx, 16
    jge .done
    mov byte [codegen_context + CodeGenContext.reg_free + rcx], 1
    inc rcx
    jmp .init_regs_loop
    
.done:
    xor rax, rax        ; Success
    jmp .exit
    
.error:
    mov rax, 1          ; Error
    
.exit:
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; codegen_emit_string - Emit string to output buffer
; Parameters:
;   RCX = string pointer
; ============================================================================
codegen_emit_string:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    sub rsp, 32
    
    mov rbx, rcx        ; Save string pointer
    
    ; Calculate string length
    xor r12, r12        ; Length counter
    mov rax, rcx
.len_loop:
    cmp byte [rax], 0
    je .len_done
    inc rax
    inc r12
    jmp .len_loop
    
.len_done:
    test r12, r12
    jz .exit            ; Empty string, nothing to do
    
    ; Check if buffer has space
    mov rax, [codegen_context + CodeGenContext.output_size]
    add rax, r12
    cmp rax, [codegen_context + CodeGenContext.output_capacity]
    jg .buffer_full     ; TODO: Implement buffer expansion
    
    ; Copy string to output buffer
    mov rdi, [codegen_context + CodeGenContext.output_buffer]
    add rdi, [codegen_context + CodeGenContext.output_size]
    mov rsi, rbx
    mov rcx, r12
    rep movsb
    
    ; Update output size
    add [codegen_context + CodeGenContext.output_size], r12
    
.exit:
    add rsp, 32
    pop r12
    pop rbx
    pop rbp
    ret
    
.buffer_full:
    ; TODO: Expand buffer or return error
    jmp .exit

; ============================================================================
; codegen_generate_program - Generate code for entire program
; Parameters:
;   RCX = pointer to IRProgram
; Returns:
;   RAX = 0 on success, non-zero on error
; ============================================================================
codegen_generate_program:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 32
    
    mov rbx, rcx        ; Save program pointer
    
    ; Emit header
    lea rcx, [str_bits64]
    call codegen_emit_string
    lea rcx, [str_default_rel]
    call codegen_emit_string
    lea rcx, [str_newline]
    call codegen_emit_string
    
    ; Emit section .text
    lea rcx, [str_section_text]
    call codegen_emit_string
    lea rcx, [str_newline]
    call codegen_emit_string
    
    ; TODO: Iterate through functions and generate code
    ; For now, return success
    xor rax, rax
    
    add rsp, 32
    pop rbx
    pop rbp
    ret

; ============================================================================
; codegen_get_output - Get generated code output
; Returns:
;   RAX = pointer to output buffer
;   RDX = size of output
; ============================================================================
codegen_get_output:
    push rbp
    mov rbp, rsp
    
    mov rax, [codegen_context + CodeGenContext.output_buffer]
    mov rdx, [codegen_context + CodeGenContext.output_size]
    
    pop rbp
    ret

; ============================================================================
; codegen_emit_int - Emit integer as decimal string
; Parameters:
;   RCX = integer value
; ============================================================================
codegen_emit_int:
    push rbp
    mov rbp, rsp
    sub rsp, 80             ; Space for string buffer + alignment
    push rbx
    push r12
    push r13
    
    mov rax, rcx            ; Value to convert
    lea rbx, [rbp - 40]     ; Buffer pointer (start further back)
    lea r12, [rbp - 20]     ; End of buffer
    
    ; Work backwards from end of buffer
    mov byte [r12], 0       ; Null terminator at end
    dec r12                 ; Move back one
    
    ; Handle zero special case
    test rax, rax
    jnz .convert
    mov byte [r12], '0'
    jmp .emit
    
.convert:
    ; Convert to decimal (work backwards)
    mov r13, 10
.convert_loop:
    test rax, rax
    jz .convert_done
    
    xor rdx, rdx
    div r13                 ; RAX = quotient, RDX = remainder
    add dl, '0'             ; Convert to ASCII
    mov [r12], dl
    dec r12
    jmp .convert_loop
    
.convert_done:
    ; String is from r12+1 to end
    inc r12                 ; Point to first digit
    
.emit:
    mov rcx, r12
    call codegen_emit_string
    
    pop r13
    pop r12
    pop rbx
    add rsp, 80
    pop rbp
    ret

; ============================================================================
; codegen_generate_function - Generate code for a function
; Parameters:
;   RCX = pointer to IRFunction
; Returns:
;   RAX = 0 on success, non-zero on error
; ============================================================================
codegen_generate_function:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    sub rsp, 48
    
    mov rbx, rcx            ; Save function pointer
    
    ; Save current function
    mov [codegen_context + CodeGenContext.current_func], rbx
    
    ; Reset register allocator
    call regalloc_reset
    
    ; Emit function label
    lea rcx, [str_newline]
    call codegen_emit_string
    
    ; Emit function name
    mov r12, [rbx + 0]      ; IRFunction.name
    mov rcx, r12
    call codegen_emit_string
    
    lea rcx, [str_colon]
    call codegen_emit_string
    lea rcx, [str_newline]
    call codegen_emit_string
    
    ; Emit prologue
    lea rcx, [str_prologue_push_rbp]
    call codegen_emit_string
    lea rcx, [str_prologue_mov_rbp_rsp]
    call codegen_emit_string
    
    ; Calculate stack size (for now, use fixed 64 bytes)
    ; TODO: Calculate based on spilled temps and locals
    lea rcx, [str_prologue_sub_rsp]
    call codegen_emit_string
    mov rcx, 64
    call codegen_emit_int
    lea rcx, [str_newline]
    call codegen_emit_string
    
    ; Iterate through instructions and generate code
    mov r13, [rbx + 40]     ; IRFunction.instructions (offset 40 = 5*8)
.inst_loop:
    test r13, r13
    jz .inst_done
    
    ; Generate code for this instruction
    mov rcx, r13
    call codegen_emit_instruction
    test rax, rax
    jnz .error              ; Error in code generation
    
    ; Move to next instruction
    mov r13, [r13 + 136]    ; IRInstruction.next (offset at end of structure)
    jmp .inst_loop
    
.inst_done:
    ; Emit epilogue
    lea rcx, [str_epilogue_mov_rsp_rbp]
    call codegen_emit_string
    lea rcx, [str_epilogue_pop_rbp]
    call codegen_emit_string
    lea rcx, [str_epilogue_ret]
    call codegen_emit_string
    
    xor rax, rax            ; Success
    jmp .exit
    
.error:
    mov rax, 1              ; Error
    
.exit:
    add rsp, 48
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; ============================================================================
; codegen_emit_operand - Emit operand (register or constant)
; Parameters:
;   RCX = pointer to IROperand
; ============================================================================
codegen_emit_operand:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    sub rsp, 48
    
    mov rbx, rcx            ; Save operand pointer
    
    ; Get operand type
    mov rax, [rbx + 0]      ; IROperand.type
    cmp rax, 0              ; IR_OP_TEMP
    je .emit_temp
    cmp rax, 2              ; IR_OP_CONST
    je .emit_const
    
    ; Unknown operand type - emit nothing
    jmp .exit
    
.emit_temp:
    ; Get temp number and allocate register
    mov rcx, [rbx + 8]      ; IROperand.value (temp number)
    call regalloc_get_register
    cmp rax, 255            ; REG_NONE?
    je .exit                ; Spilled - not handling for now
    
    ; Emit register name
    lea r12, [reg_names_64]
    mov rcx, [r12 + rax*8]
    call codegen_emit_string
    jmp .exit
    
.emit_const:
    ; Emit constant value
    mov rcx, [rbx + 8]      ; IROperand.value
    call codegen_emit_int
    
.exit:
    add rsp, 48
    pop r12
    pop rbx
    pop rbp
    ret

; ============================================================================
; codegen_emit_instruction - Generate code for single IR instruction
; Parameters:
;   RCX = pointer to IRInstruction
; Returns:
;   RAX = 0 on success, non-zero on error
; ============================================================================
codegen_emit_instruction:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    sub rsp, 48
    
    mov rbx, rcx            ; Save instruction pointer
    
    ; Get opcode
    mov r12, [rbx + 0]      ; IRInstruction.opcode
    
    ; Dispatch based on opcode
    cmp r12, 40             ; IR_MOVE
    je .emit_move
    cmp r12, 0              ; IR_ADD
    je .emit_add
    cmp r12, 1              ; IR_SUB
    je .emit_sub
    cmp r12, 2              ; IR_MUL
    je .emit_mul
    cmp r12, 3              ; IR_DIV
    je .emit_div
    cmp r12, 4              ; IR_MOD
    je .emit_mod
    cmp r12, 5              ; IR_NEG
    je .emit_neg
    cmp r12, 20             ; IR_AND
    je .emit_and
    cmp r12, 21             ; IR_OR
    je .emit_or
    cmp r12, 22             ; IR_XOR
    je .emit_xor
    cmp r12, 23             ; IR_NOT
    je .emit_not
    cmp r12, 24             ; IR_SHL
    je .emit_shl
    cmp r12, 25             ; IR_SHR
    je .emit_shr
    cmp r12, 55             ; IR_RETURN
    je .emit_return
    cmp r12, 50             ; IR_LABEL
    je .emit_label
    cmp r12, 51             ; IR_JUMP
    je .emit_jump
    cmp r12, 52             ; IR_JUMP_IF
    je .emit_jump_if
    
    ; Unsupported instruction - skip for now
    xor rax, rax
    jmp .exit
    
.emit_label:
    ; Emit label: L<number>:
    lea rcx, [str_tab]
    call codegen_emit_string
    
    ; TODO: Emit label number from src1
    
    lea rcx, [str_colon]
    call codegen_emit_string
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_move:
    ; Emit: mov dest, src1
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_mov]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    ; Emit destination
    lea rcx, [rbx + 8]      ; IRInstruction.dest (32 bytes into structure)
    call codegen_emit_operand
    
    lea rcx, [str_comma]
    call codegen_emit_string
    
    ; Emit source
    lea rcx, [rbx + 8 + 32] ; IRInstruction.src1
    call codegen_emit_operand
    
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_add:
    ; Emit: add dest, src2  (assuming dest already has src1 value)
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_add]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    ; Emit destination
    lea rcx, [rbx + 8]
    call codegen_emit_operand
    
    lea rcx, [str_comma]
    call codegen_emit_string
    
    ; Emit source2
    lea rcx, [rbx + 8 + 64] ; IRInstruction.src2
    call codegen_emit_operand
    
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_sub:
    ; Emit: sub dest, src2
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_sub]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    lea rcx, [rbx + 8]
    call codegen_emit_operand
    
    lea rcx, [str_comma]
    call codegen_emit_string
    
    lea rcx, [rbx + 8 + 64]
    call codegen_emit_operand
    
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_mul:
    ; Emit: imul dest, src2
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_imul]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    lea rcx, [rbx + 8]
    call codegen_emit_operand
    
    lea rcx, [str_comma]
    call codegen_emit_string
    
    lea rcx, [rbx + 8 + 64]
    call codegen_emit_operand
    
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_div:
    ; Emit: idiv src2 (RAX = RAX / src2, RDX = remainder)
    ; TODO: Need to setup RAX with dest value first
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_idiv]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    lea rcx, [rbx + 8 + 64]
    call codegen_emit_operand
    
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_mod:
    ; Emit: idiv then use RDX (remainder)
    ; Similar to div but result is in RDX
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_idiv]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    lea rcx, [rbx + 8 + 64]
    call codegen_emit_operand
    
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_neg:
    ; Emit: neg dest
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_neg]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    lea rcx, [rbx + 8]
    call codegen_emit_operand
    
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_and:
    ; Emit: and dest, src2
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_and]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    lea rcx, [rbx + 8]
    call codegen_emit_operand
    
    lea rcx, [str_comma]
    call codegen_emit_string
    
    lea rcx, [rbx + 8 + 64]
    call codegen_emit_operand
    
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_or:
    ; Emit: or dest, src2
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_or]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    lea rcx, [rbx + 8]
    call codegen_emit_operand
    
    lea rcx, [str_comma]
    call codegen_emit_string
    
    lea rcx, [rbx + 8 + 64]
    call codegen_emit_operand
    
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_xor:
    ; Emit: xor dest, src2
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_xor]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    lea rcx, [rbx + 8]
    call codegen_emit_operand
    
    lea rcx, [str_comma]
    call codegen_emit_string
    
    lea rcx, [rbx + 8 + 64]
    call codegen_emit_operand
    
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_not:
    ; Emit: not dest
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_not]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    lea rcx, [rbx + 8]
    call codegen_emit_operand
    
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_shl:
    ; Emit: shl dest, src2
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_shl]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    lea rcx, [rbx + 8]
    call codegen_emit_operand
    
    lea rcx, [str_comma]
    call codegen_emit_string
    
    lea rcx, [rbx + 8 + 64]
    call codegen_emit_operand
    
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_shr:
    ; Emit: shr dest, src2
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_shr]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    lea rcx, [rbx + 8]
    call codegen_emit_operand
    
    lea rcx, [str_comma]
    call codegen_emit_string
    
    lea rcx, [rbx + 8 + 64]
    call codegen_emit_operand
    
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_jump:
    ; Emit: jmp label
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_jmp]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    ; TODO: Emit label from src1
    
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_jump_if:
    ; Emit: test src1, src1; jnz label
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_test]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    lea rcx, [rbx + 8 + 32]
    call codegen_emit_operand
    
    lea rcx, [str_comma]
    call codegen_emit_string
    
    lea rcx, [rbx + 8 + 32]
    call codegen_emit_operand
    
    lea rcx, [str_newline]
    call codegen_emit_string
    
    ; jnz label
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_jne]
    call codegen_emit_string
    lea rcx, [str_tab]
    call codegen_emit_string
    
    ; TODO: Emit label
    
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.emit_return:
    ; Return value should be in RAX - emit epilogue
    ; For now, just add a comment
    lea rcx, [str_tab]
    call codegen_emit_string
    lea rcx, [str_ret]
    call codegen_emit_string
    lea rcx, [str_newline]
    call codegen_emit_string
    jmp .done
    
.done:
    xor rax, rax            ; Success
    
.exit:
    add rsp, 48
    pop r12
    pop rbx
    pop rbp
    ret
