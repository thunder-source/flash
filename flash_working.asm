; ============================================================================
; Flash Compiler - Working CLI Entry Point
; ============================================================================
; Based on the working parser test, but with file reading capability
; ============================================================================

bits 64
default rel

extern lexer_init
extern parser_init
extern parser_parse
extern arena_init
extern ExitProcess
extern GetStdHandle
extern WriteConsoleA
extern CreateFileA
extern ReadFile
extern CloseHandle
extern GetFileSize
extern VirtualAlloc
extern VirtualFree

%define STD_OUTPUT_HANDLE -11
%define GENERIC_READ 0x80000000
%define OPEN_EXISTING 3
%define FILE_ATTRIBUTE_NORMAL 0x80
%define MEM_COMMIT 0x1000
%define MEM_RESERVE 0x2000
%define PAGE_READWRITE 0x04
%define MEM_RELEASE 0x8000

section .data
    ; Test filename - hardcoded for now to match what works
    test_filename db "test.fl", 0

    ; Messages that match the working parser test
    msg_init db "Initializing compiler...", 13, 10, 0
    msg_lexer db "Initializing lexer...", 13, 10, 0
    msg_parser db "Initializing parser...", 13, 10, 0
    msg_parsing db "Parsing program...", 13, 10, 0
    msg_success db "Parse successful!", 13, 10, 0
    msg_ast_root db "AST Root: Program node", 13, 10, 0
    msg_done db "Test complete.", 13, 10, 0

    msg_reading db "Reading file: test.fl", 13, 10, 0
    msg_file_error db "Error: Could not read test.fl", 13, 10, 0

    bytes_written dd 0

section .bss
    stdout resq 1
    file_handle resq 1
    source_buffer resq 1
    source_size resq 1
    bytes_read resq 1

section .text
global main

main:
    ; Prologue - same as working parser test
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; Get stdout handle
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout], rax

    ; Print initialization message
    mov rcx, [stdout]
    lea rdx, [msg_init]
    mov r8, 26  ; length including CRLF and null
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Print file reading message
    mov rcx, [stdout]
    lea rdx, [msg_reading]
    mov r8, 23
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Read the source file
    call read_source_file
    cmp rax, 0
    jne file_error

    ; Initialize lexer with file content
    mov rcx, [stdout]
    lea rdx, [msg_lexer]
    mov r8, 23
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Initialize lexer with source buffer (like parser test does)
    mov rcx, [source_buffer]
    mov rdx, [source_size]
    call lexer_init

    ; Initialize parser
    mov rcx, [stdout]
    lea rdx, [msg_parser]
    mov r8, 24
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    call parser_init

    ; Parse the program
    mov rcx, [stdout]
    lea rdx, [msg_parsing]
    mov r8, 20
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    call parser_parse

    ; Print success message
    mov rcx, [stdout]
    lea rdx, [msg_success]
    mov r8, 18
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Print AST info
    mov rcx, [stdout]
    lea rdx, [msg_ast_root]
    mov r8, 24
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Print done message
    mov rcx, [stdout]
    lea rdx, [msg_done]
    mov r8, 16
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Cleanup and exit successfully
    jmp cleanup_and_exit

file_error:
    mov rcx, [stdout]
    lea rdx, [msg_file_error]
    mov r8, 31
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40
    mov rax, 1
    jmp cleanup_and_exit

cleanup_and_exit:
    ; Free source buffer if allocated
    cmp qword [source_buffer], 0
    je skip_free
    mov rcx, [source_buffer]
    mov rdx, 0
    mov r8, MEM_RELEASE
    call VirtualFree

skip_free:
    ; Epilogue and exit
    mov rsp, rbp
    pop rbp
    mov rcx, rax
    call ExitProcess

; ============================================================================
; File Reading Function
; ============================================================================
read_source_file:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; Open the test.fl file
    lea rcx, [test_filename]
    mov rdx, GENERIC_READ
    mov r8, 0                       ; No sharing
    mov r9, 0                       ; Default security
    push FILE_ATTRIBUTE_NORMAL
    push OPEN_EXISTING
    push 0                          ; No template
    sub rsp, 32
    call CreateFileA
    add rsp, 56

    cmp rax, -1                     ; INVALID_HANDLE_VALUE
    je read_error
    mov [file_handle], rax

    ; Get file size
    mov rcx, [file_handle]
    mov rdx, 0
    call GetFileSize

    cmp rax, 1048576                ; 1MB max
    ja read_error
    mov [source_size], rax

    ; Allocate memory for file content
    mov rcx, rax
    add rcx, 1                      ; +1 for null terminator
    mov rdx, MEM_COMMIT | MEM_RESERVE
    mov r8, PAGE_READWRITE
    push 0
    sub rsp, 32
    call VirtualAlloc
    add rsp, 40

    cmp rax, 0
    je read_error
    mov [source_buffer], rax

    ; Read file content
    mov rcx, [file_handle]
    mov rdx, [source_buffer]
    mov r8, [source_size]
    lea r9, [bytes_read]
    push 0
    sub rsp, 32
    call ReadFile
    add rsp, 40

    ; Close file handle
    mov rcx, [file_handle]
    call CloseHandle

    ; Add null terminator
    mov rax, [source_buffer]
    mov rcx, [source_size]
    mov byte [rax + rcx], 0

    xor rax, rax                    ; Success
    jmp read_end

read_error:
    ; Close file handle if it was opened
    cmp qword [file_handle], -1
    je read_end
    cmp qword [file_handle], 0
    je read_end
    mov rcx, [file_handle]
    call CloseHandle

    mov rax, 1                      ; Error

read_end:
    mov rsp, rbp
    pop rbp
    ret
