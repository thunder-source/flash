; ============================================================================
; Flash Compiler - Register Allocator
; ============================================================================
; Linear scan register allocation for x86-64
; ============================================================================

bits 64
default rel

; ============================================================================
; Register Allocation Strategy
; ============================================================================
; We use a simplified linear scan allocation:
; 1. Scan IR instructions linearly
; 2. Assign physical registers to temporaries on first use
; 3. Spill to stack when registers run out
; 4. Use callee-saved registers for long-lived temporaries
; 5. Use caller-saved registers for short-lived temporaries
; ============================================================================

; ============================================================================
; Available Registers for Allocation
; ============================================================================
; Priority order (prefer callee-saved for stability):
;   1. RBX (callee-saved)
;   2. R12-R15 (callee-saved)
;   3. RSI, RDI (callee-saved on Windows x64)
;   4. R10, R11 (caller-saved, scratch)
;
; Reserved:
;   RAX - return values, temporary calculations
;   RCX, RDX, R8, R9 - function parameters
;   RBP - frame pointer
;   RSP - stack pointer
; ============================================================================

section .data
    ; Allocation priority order (index into REG_* constants)
    alloc_priority:
        db 1    ; RBX
        db 12   ; R12
        db 13   ; R13
        db 14   ; R14
        db 15   ; R15
        db 4    ; RSI
        db 5    ; RDI
        db 10   ; R10
        db 11   ; R11
        db 0    ; RAX (last resort)
        db 255  ; End marker
    
    alloc_priority_count equ 10

section .text

; ============================================================================
; External references
; ============================================================================
extern codegen_context
%define CodeGenContext_temp_map         8 + 8 + 8 + 8 + 8
%define CodeGenContext_temp_offset      CodeGenContext_temp_map + 256*8
%define CodeGenContext_reg_free         CodeGenContext_temp_offset + 256*8
%define CodeGenContext_stack_size       8 + 8 + 8 + 8

; ============================================================================
; Global functions
; ============================================================================
global regalloc_get_register
global regalloc_free_register
global regalloc_spill_temp
global regalloc_reset

; ============================================================================
; regalloc_get_register - Allocate physical register for temporary
; Parameters:
;   RCX = temporary number
; Returns:
;   RAX = physical register number (REG_*), or REG_NONE if must spill
; ============================================================================
regalloc_get_register:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    sub rsp, 32
    
    mov rbx, rcx        ; Save temp number
    
    ; Check if already allocated
    lea rax, [codegen_context]
    mov r12, [rax + CodeGenContext_temp_map + rbx*8]
    cmp r12, 255        ; REG_NONE
    jne .already_allocated
    
    ; Find free register from priority list
    xor rcx, rcx        ; Index into priority list
    
.find_free:
    cmp rcx, alloc_priority_count
    jge .no_register
    
    ; Get register from priority list
    movzx rdx, byte [alloc_priority + rcx]
    cmp rdx, 255
    je .no_register
    
    ; Check if register is free
    lea rax, [codegen_context]
    movzx r8, byte [rax + CodeGenContext_reg_free + rdx]
    test r8, r8
    jz .try_next
    
    ; Found free register - allocate it
    mov byte [rax + CodeGenContext_reg_free + rdx], 0      ; Mark as used
    mov [rax + CodeGenContext_temp_map + rbx*8], rdx       ; Map temp to register
    mov rax, rdx
    jmp .exit
    
.try_next:
    inc rcx
    jmp .find_free
    
.no_register:
    ; No free registers - must spill
    mov rax, 255        ; REG_NONE
    jmp .exit
    
.already_allocated:
    mov rax, r12
    
.exit:
    add rsp, 32
    pop r12
    pop rbx
    pop rbp
    ret

; ============================================================================
; regalloc_free_register - Free a physical register
; Parameters:
;   RCX = register number (REG_*)
; ============================================================================
regalloc_free_register:
    push rbp
    mov rbp, rsp
    
    cmp rcx, 16
    jge .exit           ; Invalid register
    
    lea rax, [codegen_context]
    mov byte [rax + CodeGenContext_reg_free + rcx], 1
    
.exit:
    pop rbp
    ret

; ============================================================================
; regalloc_spill_temp - Spill temporary to stack
; Parameters:
;   RCX = temporary number
; Returns:
;   RAX = stack offset for spilled temp
; ============================================================================
regalloc_spill_temp:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 32
    
    mov rbx, rcx        ; Save temp number
    
    ; Allocate stack space (8 bytes for 64-bit value)
    lea rax, [codegen_context]
    mov rcx, [rax + CodeGenContext_stack_size]
    add rcx, 8
    mov [rax + CodeGenContext_stack_size], rcx
    
    ; Save stack offset for this temp
    mov [rax + CodeGenContext_temp_offset + rbx*8], rcx
    mov rax, rcx
    
    add rsp, 32
    pop rbx
    pop rbp
    ret

; ============================================================================
; regalloc_reset - Reset register allocator for new function
; ============================================================================
regalloc_reset:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 32
    
    lea rbx, [codegen_context]
    
    ; Clear temp map
    xor rcx, rcx
.clear_temps:
    cmp rcx, 256
    jge .clear_regs
    mov qword [rbx + CodeGenContext_temp_map + rcx*8], 255  ; REG_NONE
    mov qword [rbx + CodeGenContext_temp_offset + rcx*8], 0
    inc rcx
    jmp .clear_temps
    
.clear_regs:
    ; Mark all registers as free
    xor rcx, rcx
.clear_regs_loop:
    cmp rcx, 16
    jge .done
    mov byte [rbx + CodeGenContext_reg_free + rcx], 1
    inc rcx
    jmp .clear_regs_loop
    
.done:
    ; Reset stack size
    mov qword [rbx + CodeGenContext_stack_size], 0
    
    add rsp, 32
    pop rbx
    pop rbp
    ret
