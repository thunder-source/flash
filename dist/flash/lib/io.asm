; ============================================================================
; Flash Compiler - I/O Library
; ============================================================================
; Basic input/output functions for Flash programs
; ============================================================================

bits 64
default rel

; ============================================================================
; External Dependencies (Windows API)
; ============================================================================
extern GetStdHandle
extern WriteFile

; ============================================================================
; Constants
; ============================================================================
%define STD_OUTPUT_HANDLE -11
%define STD_INPUT_HANDLE  -10
%define STD_ERROR_HANDLE  -12

; ============================================================================
; Global Exports
; ============================================================================
global print_int
global print_str
global print_char
global print_newline

; ============================================================================
; BSS Section
; ============================================================================
section .bss
    stdout_handle:      resq 1
    bytes_written:      resq 1
    int_buffer:         resb 32     ; Buffer for integer to string conversion

; ============================================================================
; Data Section
; ============================================================================
section .data
    newline_str:        db 13, 10, 0

; ============================================================================
; Code Section
; ============================================================================
section .text

; ============================================================================
; io_init - Initialize I/O system (internal)
; Called automatically on first I/O operation
; ============================================================================
io_init:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Check if already initialized
    mov rax, [stdout_handle]
    test rax, rax
    jnz .done               ; Already initialized
    
    ; Get stdout handle
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout_handle], rax
    
.done:
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; print_int - Print signed 64-bit integer to stdout
; Parameters:
;   RCX = integer value (i64)
; ============================================================================
print_int:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    push rbx
    push r12
    push r13
    push r14
    
    ; Save integer value
    mov rbx, rcx
    
    ; Initialize I/O if needed
    call io_init
    
    ; Convert integer to string
    lea r12, [int_buffer + 30]  ; Point near end of buffer
    
    ; Handle negative numbers
    xor r14, r14                ; Sign flag
    test rbx, rbx
    jns .positive
    neg rbx
    mov r14, 1                  ; Set sign flag
    
.positive:
    ; Handle zero special case
    test rbx, rbx
    jnz .convert
    mov byte [r12], '0'
    dec r12
    jmp .print
    
.convert:
    ; Convert to decimal
    mov rax, rbx
    mov r13, 10
    
.convert_loop:
    xor rdx, rdx
    div r13                     ; RAX = quotient, RDX = remainder
    add dl, '0'                 ; Convert to ASCII
    mov [r12], dl
    dec r12
    test rax, rax
    jnz .convert_loop
    
    ; Add minus sign if negative
    test r14, r14
    jz .print
    mov byte [r12], '-'
    dec r12
    
.print:
    ; Calculate string length and pointer
    inc r12                     ; Point to first character
    lea r13, [int_buffer + 31]
    sub r13, r12                ; Length
    
    ; Write to stdout
    mov rcx, [stdout_handle]
    mov rdx, r12                ; Buffer
    mov r8, r13                 ; Length
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0     ; lpOverlapped = NULL
    call WriteFile
    
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 64
    pop rbp
    ret

; ============================================================================
; print_str - Print null-terminated string to stdout
; Parameters:
;   RCX = string pointer (char*)
; ============================================================================
print_str:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    
    mov rbx, rcx                ; Save string pointer
    
    ; Initialize I/O if needed
    call io_init
    
    ; Calculate string length
    xor rdx, rdx
.len_loop:
    cmp byte [rbx + rdx], 0
    je .len_done
    inc rdx
    jmp .len_loop
    
.len_done:
    mov r12, rdx                ; Save length
    test r12, r12
    jz .exit                    ; Empty string
    
    ; Write to stdout
    mov rcx, [stdout_handle]
    mov rdx, rbx                ; Buffer
    mov r8, r12                 ; Length
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0     ; lpOverlapped = NULL
    call WriteFile
    
.exit:
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; print_char - Print single character to stdout
; Parameters:
;   RCX = character (char/i8)
; ============================================================================
print_char:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    
    mov bl, cl                  ; Save character
    
    ; Initialize I/O if needed
    call io_init
    
    ; Write character
    mov byte [rbp - 16], bl     ; Store char on stack
    mov rcx, [stdout_handle]
    lea rdx, [rbp - 16]         ; Buffer
    mov r8, 1                   ; Length
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0     ; lpOverlapped = NULL
    call WriteFile
    
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; print_newline - Print newline (CRLF on Windows)
; Parameters: None
; ============================================================================
print_newline:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Initialize I/O if needed
    call io_init
    
    ; Print newline string
    mov rcx, [stdout_handle]
    lea rdx, [newline_str]
    mov r8, 2                   ; Length (CR + LF)
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0     ; lpOverlapped = NULL
    call WriteFile
    
    add rsp, 32
    pop rbp
    ret
