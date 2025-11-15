; ============================================================================
; Flash Compiler - String Library
; Basic string helpers: strlen, strcmp, strcpy
; ============================================================================

bits 64
default rel

section .text

global strlen
global strcmp
global strcpy

; strlen(str)
; RCX = str
; returns length in RAX (u64)
strlen:
    push rbp
    mov rbp, rsp
    push rdi
    mov rdi, rcx
    xor rax, rax
.strlen_loop:
    cmp byte [rdi + rax], 0
    je .strlen_done
    inc rax
    jmp .strlen_loop
.strlen_done:
    pop rdi
    pop rbp
    ret

; strcmp(a, b)
; RCX = a, RDX = b
; returns 0 if equal, <0 if a<b, >0 if a>b (difference of first differing byte in RAX)
strcmp:
    push rbp
    mov rbp, rsp
    push rsi
    push rdi

    mov rsi, rcx    ; a
    mov rdi, rdx    ; b

.strcmp_loop:
    mov al, [rsi]
    mov dl, [rdi]
    cmp al, dl
    jne .strcmp_diff
    test al, al
    jz .strcmp_equal
    inc rsi
    inc rdi
    jmp .strcmp_loop

.strcmp_diff:
    movzx eax, al
    movzx edx, dl
    sub eax, edx
    jmp .strcmp_done

.strcmp_equal:
    xor rax, rax

.strcmp_done:
    pop rdi
    pop rsi
    pop rbp
    ret

; strcpy(dest, src)
; RCX = dest, RDX = src
; returns RCX (dest) in RAX
strcpy:
    push rbp
    mov rbp, rsp
    push rsi
    push rdi

    mov rax, rcx    ; save dest for return
    mov rdi, rcx    ; dest
    mov rsi, rdx    ; src

.strcpy_loop:
    mov bl, [rsi]
    mov [rdi], bl
    inc rsi
    inc rdi
    test bl, bl
    jnz .strcpy_loop

    ; return dest
    pop rdi
    pop rsi
    pop rbp
    ret
