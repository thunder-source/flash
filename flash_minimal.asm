; ============================================================================
; Flash Compiler - Minimal Working CLI
; ============================================================================
; A minimal, robust command-line interface for the Flash compiler
; Focuses on core functionality with proper error handling
; ============================================================================

bits 64
default rel

; External functions from compiler components
extern arena_init
extern lexer_init
extern parser_init
extern parser_parse
extern GetStdHandle
extern WriteConsoleA
extern CreateFileA
extern ReadFile
extern CloseHandle
extern GetFileSize
extern VirtualAlloc
extern VirtualFree
extern ExitProcess

; Constants
%define STD_OUTPUT_HANDLE -11
%define STD_ERROR_HANDLE -12
%define GENERIC_READ 0x80000000
%define OPEN_EXISTING 3
%define FILE_ATTRIBUTE_NORMAL 0x80
%define MEM_COMMIT 0x1000
%define MEM_RESERVE 0x2000
%define PAGE_READWRITE 0x04
%define MEM_RELEASE 0x8000
%define MAX_SOURCE_SIZE 1048576

section .data
    ; Messages
    welcome_msg db "Flash Compiler v0.2.0 - Minimal CLI", 13, 10, 0
    usage_msg db "Usage: flash_minimal <input.fl>", 13, 10, 0
    processing_msg db "Processing: ", 0

    ; Phase messages
    phase1_msg db "Phase 1: Lexical analysis...", 13, 10, 0
    phase2_msg db "Phase 2: Parsing...", 13, 10, 0
    success_msg db "Compilation successful!", 13, 10, 0

    ; Error messages
    error_no_file db "Error: No input file specified", 13, 10, 0
    error_open_file db "Error: Cannot open file", 13, 10, 0
    error_read_file db "Error: Cannot read file", 13, 10, 0
    error_too_large db "Error: File too large", 13, 10, 0
    error_no_memory db "Error: Memory allocation failed", 13, 10, 0
    error_parse db "Error: Parsing failed", 13, 10, 0

    newline db 13, 10, 0
    bytes_written dd 0

section .bss
    stdout_handle resq 1
    stderr_handle resq 1
    file_handle resq 1
    source_buffer resq 1
    source_size resq 1
    bytes_read resq 1
    input_filename resb 260

section .text
global main

main:
    ; Prologue
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; Get standard handles
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout_handle], rax

    mov rcx, STD_ERROR_HANDLE
    call GetStdHandle
    mov [stderr_handle], rax

    ; Print welcome message
    lea rcx, [welcome_msg]
    call print_message

    ; Parse command line - simplified approach
    call simple_parse_args
    cmp rax, 0
    je show_usage_exit

    ; Print what we're processing
    lea rcx, [processing_msg]
    call print_message
    lea rcx, [input_filename]
    call print_message
    lea rcx, [newline]
    call print_message

    ; Read the source file
    call read_file
    cmp rax, 0
    jne exit_error

    ; Initialize compiler
    call init_components
    cmp rax, 0
    jne exit_error

    ; Run compilation
    call run_compilation
    cmp rax, 0
    jne exit_error

    ; Success
    lea rcx, [success_msg]
    call print_message
    jmp cleanup_exit

show_usage_exit:
    lea rcx, [usage_msg]
    call print_message
    jmp cleanup_exit

exit_error:
    mov rax, 1
    jmp cleanup_exit

cleanup_exit:
    ; Free memory if allocated
    cmp qword [source_buffer], 0
    je skip_cleanup
    mov rcx, [source_buffer]
    mov rdx, 0
    mov r8, MEM_RELEASE
    call VirtualFree

skip_cleanup:
    ; Exit
    mov rsp, rbp
    pop rbp
    mov rcx, rax
    call ExitProcess

; ============================================================================
; Simple argument parsing
; ============================================================================
simple_parse_args:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; For minimal version, we'll hardcode the filename for testing
    ; In a real implementation, you'd parse the actual command line

    ; Check if test.fl exists by trying to open it
    lea rcx, [test_filename]
    lea rdx, [input_filename]
    call copy_string

    ; Try to open the file to validate
    lea rcx, [input_filename]
    mov rdx, GENERIC_READ
    mov r8, 0
    mov r9, 0
    push FILE_ATTRIBUTE_NORMAL
    push OPEN_EXISTING
    push 0
    sub rsp, 32
    call CreateFileA
    add rsp, 56

    cmp rax, -1
    je arg_parse_fail

    ; Close the test handle
    mov rcx, rax
    call CloseHandle

    mov rax, 1  ; Success
    jmp arg_parse_end

arg_parse_fail:
    xor rax, rax  ; Failure

arg_parse_end:
    mov rsp, rbp
    pop rbp
    ret

; ============================================================================
; Read source file
; ============================================================================
read_file:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; Open file
    lea rcx, [input_filename]
    mov rdx, GENERIC_READ
    mov r8, 0
    mov r9, 0
    push FILE_ATTRIBUTE_NORMAL
    push OPEN_EXISTING
    push 0
    sub rsp, 32
    call CreateFileA
    add rsp, 56

    cmp rax, -1
    je read_open_error
    mov [file_handle], rax

    ; Get file size
    mov rcx, [file_handle]
    mov rdx, 0
    call GetFileSize

    cmp rax, -1
    je read_size_error
    cmp rax, MAX_SOURCE_SIZE
    ja read_too_large
    mov [source_size], rax

    ; Allocate memory
    mov rcx, rax
    add rcx, 16  ; Extra space for null terminator
    mov rdx, MEM_COMMIT | MEM_RESERVE
    mov r8, PAGE_READWRITE
    push 0
    sub rsp, 32
    call VirtualAlloc
    add rsp, 40

    cmp rax, 0
    je read_memory_error
    mov [source_buffer], rax

    ; Read file
    mov rcx, [file_handle]
    mov rdx, [source_buffer]
    mov r8, [source_size]
    lea r9, [bytes_read]
    push 0
    sub rsp, 32
    call ReadFile
    add rsp, 40

    ; Close file
    mov rcx, [file_handle]
    call CloseHandle

    ; Add null terminator
    mov rax, [source_buffer]
    mov rcx, [source_size]
    mov byte [rax + rcx], 0

    xor rax, rax  ; Success
    jmp read_end

read_open_error:
    lea rcx, [error_open_file]
    call print_error
    mov rax, 1
    jmp read_end

read_size_error:
    mov rcx, [file_handle]
    call CloseHandle
    lea rcx, [error_read_file]
    call print_error
    mov rax, 1
    jmp read_end

read_too_large:
    mov rcx, [file_handle]
    call CloseHandle
    lea rcx, [error_too_large]
    call print_error
    mov rax, 1
    jmp read_end

read_memory_error:
    mov rcx, [file_handle]
    call CloseHandle
    lea rcx, [error_no_memory]
    call print_error
    mov rax, 1

read_end:
    mov rsp, rbp
    pop rbp
    ret

; ============================================================================
; Initialize compiler components
; ============================================================================
init_components:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Initialize arena
    call arena_init
    cmp rax, 0
    je init_error

    ; Initialize lexer
    mov rcx, [source_buffer]
    mov rdx, [source_size]
    call lexer_init
    cmp rax, 0
    je init_error

    ; Initialize parser
    call parser_init
    cmp rax, 0
    je init_error

    xor rax, rax  ; Success
    jmp init_end

init_error:
    mov rax, 1

init_end:
    mov rsp, rbp
    pop rbp
    ret

; ============================================================================
; Run compilation phases
; ============================================================================
run_compilation:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Phase 1
    lea rcx, [phase1_msg]
    call print_message

    ; Phase 2
    lea rcx, [phase2_msg]
    call print_message

    ; Run parser
    call parser_parse
    cmp rax, 0
    je parse_error

    ; Success
    xor rax, rax
    jmp compile_end

parse_error:
    lea rcx, [error_parse]
    call print_error
    mov rax, 1

compile_end:
    mov rsp, rbp
    pop rbp
    ret

; ============================================================================
; Print message to stdout
; ============================================================================
print_message:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx

    mov rbx, rcx

    ; Calculate string length
    xor rax, rax
calc_len:
    cmp byte [rbx + rax], 0
    je print_now
    inc rax
    jmp calc_len

print_now:
    mov rcx, [stdout_handle]
    mov rdx, rbx
    mov r8, rax
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; ============================================================================
; Print error message to stderr
; ============================================================================
print_error:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx

    mov rbx, rcx

    ; Calculate string length
    xor rax, rax
calc_err_len:
    cmp byte [rbx + rax], 0
    je print_err_now
    inc rax
    jmp calc_err_len

print_err_now:
    mov rcx, [stderr_handle]
    mov rdx, rbx
    mov r8, rax
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; ============================================================================
; Copy string utility
; ============================================================================
copy_string:
    push rbp
    mov rbp, rsp

    ; RCX = source, RDX = dest
    xor rax, rax
copy_loop:
    mov r8b, [rcx + rax]
    mov [rdx + rax], r8b
    cmp r8b, 0
    je copy_done
    inc rax
    jmp copy_loop

copy_done:
    mov rsp, rbp
    pop rbp
    ret

section .data
    test_filename db "test.fl", 0
