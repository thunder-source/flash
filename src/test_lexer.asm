; ============================================================================
; Test program for Flash Compiler Lexer
; ============================================================================

bits 64
default rel

extern lexer_init
extern lexer_next_token
extern ExitProcess
extern GetStdHandle
extern WriteFile

%define STD_OUTPUT_HANDLE -11

section .data
    test_source db "fn main() {", 10
                db "    let mut x: i32 = 42;", 10
                db "    x = x + 10;", 10
                db "    return x;", 10
                db "}", 0
    
    newline db 13, 10
    token_msg db "Token: type=", 0
    length_msg db " length=", 0
    line_msg db " line=", 0
    content_msg db " content=", 0
    
    bytes_written dd 0

section .bss
    token resb 32  ; Token structure
    stdout resq 1
    buffer resb 256

section .text
global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Get stdout handle
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout], rax
    
    ; Initialize lexer
    lea rcx, [test_source]
    call lexer_init
    mov rbx, rax  ; Save lexer pointer
    
.token_loop:
    ; Get next token
    mov rcx, rbx
    lea rdx, [token]
    call lexer_next_token
    
    ; Check for EOF
    mov rax, [token]
    test rax, rax
    jz .done
    
    ; Print token info
    call print_token
    
    jmp .token_loop
    
.done:
    ; Print final message
    lea rcx, [newline]
    mov rdx, 2
    call print_string
    
    xor rcx, rcx
    call ExitProcess

; ============================================================================
; print_token - Print token information
; ============================================================================
print_token:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Print "Token: type="
    lea rcx, [token_msg]
    mov rdx, 13
    call print_string
    
    ; Print token type as number
    mov rax, [token]
    call print_number
    
    ; Print " length="
    lea rcx, [length_msg]
    mov rdx, 8
    call print_string
    
    ; Print token length
    mov rax, [token + 16]
    call print_number
    
    ; Print " line="
    lea rcx, [line_msg]
    mov rdx, 6
    call print_string
    
    ; Print line number
    mov rax, [token + 24]
    call print_number
    
    ; Print " content="
    lea rcx, [content_msg]
    mov rdx, 9
    call print_string
    
    ; Print token content
    mov rcx, [token + 8]   ; start pointer
    mov rdx, [token + 16]  ; length
    call print_string
    
    ; Print newline
    lea rcx, [newline]
    mov rdx, 2
    call print_string
    
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; print_string - Print a string to stdout
; Parameters:
;   RCX = pointer to string
;   RDX = length
; ============================================================================
print_string:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    mov r8, rdx
    mov rdx, rcx
    mov rcx, [stdout]
    lea r9, [bytes_written]
    xor rax, rax
    mov [rsp + 32], rax
    call WriteFile
    
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; print_number - Print a number to stdout
; Parameters:
;   RAX = number to print
; ============================================================================
print_number:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    
    mov r12, rax
    lea rbx, [buffer + 255]
    mov byte [rbx], 0
    dec rbx
    
    test r12, r12
    jnz .convert
    
    mov byte [rbx], '0'
    jmp .print
    
.convert:
    mov rax, r12
    mov rcx, 10
    
.loop:
    test rax, rax
    jz .print
    
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov [rbx], dl
    dec rbx
    jmp .loop
    
.print:
    inc rbx
    mov rcx, rbx
    lea rax, [buffer + 256]
    sub rax, rbx
    mov rdx, rax
    call print_string
    
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret
