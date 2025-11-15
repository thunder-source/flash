; ============================================================================
; Flash Compiler - Memory Library
; Basic memory helpers: memcpy, memset, memcmp
; ============================================================================

bits 64
default rel

section .text

global memcpy
global memset
global memcmp

; memcpy(dest, src, size)
; RCX = dest, RDX = src, R8 = size
; returns RCX (dest) in RAX
memcpy:
    push rbp
    mov rbp, rsp
    push rsi
    push rdi
    push rbx

    mov r11, rcx        ; save dest for return
    mov rdi, rcx        ; dest pointer
    mov rsi, rdx        ; src pointer
    mov rdx, r8         ; size
    test rdx, rdx
    jz .memcpy_done

    ; Copy qwords while possible
    mov rcx, rdx
    shr rcx, 3
    jz .memcpy_tail
.memcpy_qloop:
    mov rax, [rsi]
    mov [rdi], rax
    add rsi, 8
    add rdi, 8
    dec rcx
    jnz .memcpy_qloop

.memcpy_tail:
    mov rcx, rdx
    and rcx, 7
    jz .memcpy_done
.memcpy_bloop:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    dec rcx
    jnz .memcpy_bloop

.memcpy_done:
    mov rax, r11        ; return dest
    pop rbx
    pop rdi
    pop rsi
    pop rbp
    ret

; memset(dest, value, size)
; RCX = dest, RDX = value (u8), R8 = size
; returns RCX (dest) in RAX
memset:
    push rbp
    mov rbp, rsp
    push rdi
    push rsi
    push rbx

    mov r11, rcx        ; save dest for return
    mov rdi, rcx        ; dest pointer
    mov al, dl          ; value (byte)
    mov rcx, r8         ; size
    test rcx, rcx
    jz .memset_done

    ; Simple byte-wise fill (safe and portable)
.memset_loop:
    mov [rdi], al
    inc rdi
    dec rcx
    jnz .memset_loop

.memset_done:
    mov rax, r11
    pop rbx
    pop rsi
    pop rdi
    pop rbp
    ret

; memcmp(a, b, size)
; RCX = a, RDX = b, R8 = size
; returns 0 if equal, <0 if a<b, >0 if a>b (difference of first differing byte as i32 in RAX)
memcmp:
    push rbp
    mov rbp, rsp
    push rsi
    push rdi
    push rbx

    mov rsi, rcx    ; a
    mov rdi, rdx    ; b
    mov rcx, r8     ; size
    test rcx, rcx
    jz .memcmp_equal

    ; Compare qwords when possible
    mov rbx, rcx
    shr rbx, 3
    jz .memcmp_tail
.memcmp_qloop:
    mov rax, [rsi]
    mov rdx, [rdi]
    cmp rax, rdx
    jne .memcmp_seek_byte
    add rsi, 8
    add rdi, 8
    dec rbx
    jnz .memcmp_qloop

.memcmp_tail:
    mov rcx, rcx
    and rcx, 7
    jz .memcmp_equal
.memcmp_bloop:
    mov al, [rsi]
    mov dl, [rdi]
    cmp al, dl
    jne .memcmp_diff
    inc rsi
    inc rdi
    dec rcx
    jnz .memcmp_bloop

.memcmp_equal:
    xor rax, rax
    jmp .memcmp_done

.memcmp_seek_byte:
    ; Found differing qwords - compare byte-by-byte to find first differing byte
    ; rax contains qword from a, rdx contains qword from b
    mov r9, rsi
    ; rewind to start of this qword
    ; compute address aligned back: r9 currently points to start of differing qword
    ; We already didn't advance rsi/rdi beyond this qword, so proceed bytewise
.memcmp_q_byte_loop:
    mov al, [rsi]
    mov dl, [rdi]
    cmp al, dl
    jne .memcmp_diff
    inc rsi
    inc rdi
    jmp .memcmp_q_byte_loop

.memcmp_diff:
    ; return signed difference (al - dl) as i32 in rax
    movzx eax, al
    movzx edx, dl
    sub eax, edx
.memcmp_done:
    pop rbx
    pop rdi
    pop rsi
    pop rbp
    ret
