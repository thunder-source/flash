; ============================================================================
; Flash Compiler - Minimal Parser Stub
; ============================================================================
; This module consumes tokens from the lexer and produces a placeholder AST
; node so that the rest of the pipeline can execute. It is intentionally
; simple and focuses on exercising the lexer and build system.
; ============================================================================

bits 64
default rel

extern lexer_next_token
extern malloc

%include "src/lexer/lexer.inc"

; ============================================================================
; AST Node Definitions
; ============================================================================
%define AST_PROGRAM  0

struc AstProgram
    .node_type      resd 1
    .decl_count     resd 1
    .decls          resq 1
endstruc

; ============================================================================
; Parser State
; ============================================================================
struc Parser
    .lexer          resq 1
    .current_token  resq 1
    .previous_token resq 1
    .had_error      resb 1
    .panic_mode     resb 1
    ._padding       resw 1
endstruc

section .text

global parser_init
global parser_parse

; ---------------------------------------------------------------------------
; parser_init
;   RCX = pointer to initialized Lexer
;   Returns: RAX = pointer to Parser or 0 on failure
; ---------------------------------------------------------------------------
parser_init:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov rdx, rcx                ; Preserve lexer pointer
    mov rcx, Parser_size
    call malloc
    test rax, rax
    jz .error

    mov r8, rax                 ; r8 = parser pointer
    mov [r8 + Parser.lexer], rdx
    mov qword [r8 + Parser.current_token], 0
    mov qword [r8 + Parser.previous_token], 0
    mov byte [r8 + Parser.had_error], 0
    mov byte [r8 + Parser.panic_mode], 0

    mov rcx, [r8 + Parser.lexer]
    call lexer_next_token
    test rax, rax
    jz .error
    mov [r8 + Parser.current_token], rax

    mov rax, r8
    jmp .done

.error:
    xor eax, eax

.done:
    mov rsp, rbp
    pop rbp
    ret

; ---------------------------------------------------------------------------
; parser_parse
;   RCX = pointer to Parser
;   Returns: RAX = pointer to AstProgram or 0 on failure
; ---------------------------------------------------------------------------
parser_parse:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov [rsp + 8], rcx          ; Save parser pointer

    mov rcx, AstProgram_size
    call malloc
    test rax, rax
    jz .error

    mov rdx, rax                ; rdx = program pointer
    mov dword [rdx + AstProgram.node_type], AST_PROGRAM
    mov dword [rdx + AstProgram.decl_count], 0
    mov qword [rdx + AstProgram.decls], 0
    mov [rsp + 16], rdx

    mov rcx, [rsp + 8]
    call parser_drain_tokens
    test rax, rax
    jz .error

    mov rax, [rsp + 16]
    jmp .done

.error:
    xor eax, eax

.done:
    mov rsp, rbp
    pop rbp
    ret

; ---------------------------------------------------------------------------
; parser_drain_tokens
;   RCX = pointer to Parser
;   Returns: RAX = 1 on success, 0 on failure
; ---------------------------------------------------------------------------
parser_drain_tokens:
    push rbp
    mov rbp, rsp
    push rbx

    mov rbx, rcx

.next_token:
    mov rax, [rbx + Parser.current_token]
    test rax, rax
    jz .error
    cmp dword [rax + Token.type], TOKEN_EOF
    je .success

    mov rcx, rbx
    call parser_advance
    test rax, rax
    jz .error
    jmp .next_token

.success:
    mov eax, 1
    jmp .done

.error:
    mov byte [rbx + Parser.had_error], 1
    xor eax, eax

.done:
    pop rbx
    pop rbp
    ret

; ---------------------------------------------------------------------------
; parser_advance
;   RCX = pointer to Parser
;   Returns: RAX = pointer to new current token or 0 on failure
; ---------------------------------------------------------------------------
parser_advance:
    push rbp
    mov rbp, rsp
    push rbx

    mov rbx, rcx
    mov rax, [rbx + Parser.current_token]
    mov [rbx + Parser.previous_token], rax

    mov rcx, [rbx + Parser.lexer]
    call lexer_next_token
    test rax, rax
    jz .error

    mov [rbx + Parser.current_token], rax
    jmp .done

.error:
    mov byte [rbx + Parser.had_error], 1
    xor eax, eax

.done:
    pop rbx
    pop rbp
    ret
