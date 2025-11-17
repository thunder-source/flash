; ============================================================================
; Flash Compiler - Lexer Unit Test
; ============================================================================

bits 64
default rel

%include "src/lexer/lexer.inc"

extern lexer_init
extern lexer_next_token
extern ExitProcess
extern GetStdHandle
extern WriteFile

%define STD_OUTPUT_HANDLE -11

struc ExpectedToken
    .type       resd 1
    ._pad       resd 1
    .lexeme     resq 1
    .length     resq 1
endstruc

%macro EXPECT_TOKEN 3
    dd %1
    dd 0
    dq %2
    dq %3
%endmacro

section .data
    test_source db "fn main() {", 10
                db "    let mut x: i32 = 42;", 10
                db "    x = x + 10;", 10
                db "    return x;", 10
                db "}", 0

    newline db 13, 10
newline_len equ $-newline

    success_msg db "Lexer unit test passed", 13, 10
success_len equ $-success_msg

    error_type_msg db "Type mismatch at token "
error_type_len equ $-error_type_msg

    error_length_msg db "Length mismatch at token "
error_length_len equ $-error_length_msg

    error_lexeme_msg db "Lexeme mismatch at token "
error_lexeme_len equ $-error_lexeme_msg

    error_null_msg db "Unexpected NULL token at index "
error_null_len equ $-error_null_msg

    fatal_msg db "Failed to initialize lexer", 13, 10
fatal_len equ $-fatal_msg

    bytes_written dd 0

    lex_fn db "fn"
lex_fn_len equ $-lex_fn
    db 0

    lex_main db "main"
lex_main_len equ $-lex_main
    db 0

    lex_lparen db "("
lex_lparen_len equ $-lex_lparen
    db 0

    lex_rparen db ")"
lex_rparen_len equ $-lex_rparen
    db 0

    lex_lbrace db "{"
lex_lbrace_len equ $-lex_lbrace
    db 0

    lex_rbrace db "}"
lex_rbrace_len equ $-lex_rbrace
    db 0

    lex_let db "let"
lex_let_len equ $-lex_let
    db 0

    lex_mut db "mut"
lex_mut_len equ $-lex_mut
    db 0

    lex_x db "x"
lex_x_len equ $-lex_x
    db 0

    lex_colon db ":"
lex_colon_len equ $-lex_colon
    db 0

    lex_i32 db "i32"
lex_i32_len equ $-lex_i32
    db 0

    lex_assign db "="
lex_assign_len equ $-lex_assign
    db 0

    lex_42 db "42"
lex_42_len equ $-lex_42
    db 0

    lex_10 db "10"
lex_10_len equ $-lex_10
    db 0

    lex_semicolon db ";"
lex_semicolon_len equ $-lex_semicolon
    db 0

    lex_plus db "+"
lex_plus_len equ $-lex_plus
    db 0

    lex_return db "return"
lex_return_len equ $-lex_return
    db 0

    lex_empty db 0
%define lex_empty_len 0

    expected_tokens:
        EXPECT_TOKEN TOKEN_FN,         lex_fn,        lex_fn_len
        EXPECT_TOKEN TOKEN_IDENTIFIER, lex_main,      lex_main_len
        EXPECT_TOKEN TOKEN_LPAREN,     lex_lparen,    lex_lparen_len
        EXPECT_TOKEN TOKEN_RPAREN,     lex_rparen,    lex_rparen_len
        EXPECT_TOKEN TOKEN_LBRACE,     lex_lbrace,    lex_lbrace_len
        EXPECT_TOKEN TOKEN_LET,        lex_let,       lex_let_len
        EXPECT_TOKEN TOKEN_MUT,        lex_mut,       lex_mut_len
        EXPECT_TOKEN TOKEN_IDENTIFIER, lex_x,         lex_x_len
        EXPECT_TOKEN TOKEN_COLON,      lex_colon,     lex_colon_len
        EXPECT_TOKEN TOKEN_I32,        lex_i32,       lex_i32_len
        EXPECT_TOKEN TOKEN_ASSIGN,     lex_assign,    lex_assign_len
        EXPECT_TOKEN TOKEN_NUMBER,     lex_42,        lex_42_len
        EXPECT_TOKEN TOKEN_SEMICOLON,  lex_semicolon, lex_semicolon_len
        EXPECT_TOKEN TOKEN_IDENTIFIER, lex_x,         lex_x_len
        EXPECT_TOKEN TOKEN_ASSIGN,     lex_assign,    lex_assign_len
        EXPECT_TOKEN TOKEN_IDENTIFIER, lex_x,         lex_x_len
        EXPECT_TOKEN TOKEN_PLUS,       lex_plus,      lex_plus_len
        EXPECT_TOKEN TOKEN_NUMBER,     lex_10,        lex_10_len
        EXPECT_TOKEN TOKEN_SEMICOLON,  lex_semicolon, lex_semicolon_len
        EXPECT_TOKEN TOKEN_RETURN,     lex_return,    lex_return_len
        EXPECT_TOKEN TOKEN_IDENTIFIER, lex_x,         lex_x_len
        EXPECT_TOKEN TOKEN_SEMICOLON,  lex_semicolon, lex_semicolon_len
        EXPECT_TOKEN TOKEN_RBRACE,     lex_rbrace,    lex_rbrace_len
        EXPECT_TOKEN TOKEN_EOF,        lex_empty,     lex_empty_len
    expected_tokens_end:
%assign EXPECTED_TOKEN_COUNT ((expected_tokens_end - expected_tokens) / ExpectedToken_size)

section .bss
    stdout      resq 1
    lexer_ptr   resq 1
    token_index resq 1
    buffer      resb 256

section .text
global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout], rax

    lea rcx, [test_source]
    call lexer_init
    test rax, rax
    jz .init_fail
    mov [lexer_ptr], rax

    mov qword [token_index], 0

.verify_loop:
    mov rax, [token_index]
    cmp rax, EXPECTED_TOKEN_COUNT
    jae .success

    mov rcx, [lexer_ptr]
    call lexer_next_token
    test rax, rax
    jz .unexpected_null
    mov r8, rax

    mov rax, [token_index]
    imul rax, ExpectedToken_size
    lea r9, [expected_tokens]
    add r9, rax

    mov edx, [r9 + ExpectedToken.type]
    cmp dword [r8 + Token.type], edx
    jne .type_mismatch

    mov r10, [r9 + ExpectedToken.length]
    cmp qword [r8 + Token.length], r10
    jne .length_mismatch

    test r10, r10
    jz .lexeme_checked

    mov rsi, [r8 + Token.start]
    mov rdi, [r9 + ExpectedToken.lexeme]
    mov rcx, r10

.compare_loop:
    mov al, [rsi]
    mov dl, [rdi]
    cmp al, dl
    jne .lexeme_mismatch
    inc rsi
    inc rdi
    dec rcx
    jnz .compare_loop

.lexeme_checked:
    inc qword [token_index]
    jmp .verify_loop

.success:
    lea rcx, [success_msg]
    mov rdx, success_len
    call print_string
    xor rcx, rcx
    call ExitProcess

.type_mismatch:
    lea rcx, [error_type_msg]
    mov rdx, error_type_len
    jmp .fail_with_index

.length_mismatch:
    lea rcx, [error_length_msg]
    mov rdx, error_length_len
    jmp .fail_with_index

.lexeme_mismatch:
    lea rcx, [error_lexeme_msg]
    mov rdx, error_lexeme_len
    jmp .fail_with_index

.unexpected_null:
    lea rcx, [error_null_msg]
    mov rdx, error_null_len

.fail_with_index:
    call print_string
    mov rax, [token_index]
    call print_number
    lea rcx, [newline]
    mov rdx, newline_len
    call print_string
    mov rcx, 1
    call ExitProcess

.init_fail:
    lea rcx, [fatal_msg]
    mov rdx, fatal_len
    call print_string
    mov rcx, 1
    call ExitProcess

; ============================================================================
; print_string - Print a string to stdout
;   RCX = pointer, RDX = length
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
; print_number - Print number in RAX
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

.num_loop:
    test rax, rax
    jz .print
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov [rbx], dl
    dec rbx
    jmp .num_loop

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
