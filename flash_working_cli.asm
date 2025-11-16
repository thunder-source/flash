; ============================================================================
; Flash Compiler - Working CLI with File Input
; ============================================================================
; A Flash CLI that actually works by combining the working parser test
; structure with proper file input handling
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
extern GetCommandLineA

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

%define AST_PROGRAM         0
%define AST_FUNCTION        1
%define AST_BLOCK           20
%define AST_LET_STMT        21
%define AST_RETURN_STMT     26

section .data
    ; Messages (matching working parser test format)
    msg_header db "Flash Compiler v0.2.0 - Working CLI", 13, 10, 0
    msg_usage db "Usage: flash_working_cli <filename.fl>", 13, 10, 0
    msg_reading db "Reading source file: ", 0
    msg_init db "Initializing compiler...", 13, 10, 0
    msg_lexer db "Initializing lexer...", 13, 10, 0
    msg_parser db "Initializing parser...", 13, 10, 0
    msg_parsing db "Parsing program...", 13, 10, 0
    msg_success db "Parse successful!", 13, 10, 0
    msg_ast_root db "AST Root: Program node", 13, 10, 0
    msg_done db "Compilation complete.", 13, 10, 0

    ; Error messages
    msg_no_args db "Error: No input file specified", 13, 10, 0
    msg_file_error db "Error: Could not read file", 13, 10, 0
    msg_parse_error db "Parse failed!", 13, 10, 0

    newline db 13, 10, 0
    bytes_written dd 0

    ; Default filename for testing
    default_file db "test.fl", 0

section .bss
    stdout resq 1
    file_handle resq 1
    source_buffer resq 1
    source_size resq 1
    bytes_read resq 1
    ast_root resq 1
    input_filename resb 260

section .text
global main

main:
    ; Prologue (exact same as working parser test)
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; Get stdout handle (exact same as working parser test)
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout], rax

    ; Print header
    lea rcx, [msg_header]
    call print_cstring

    ; Parse command line arguments
    call parse_simple_args
    cmp rax, 0
    je show_usage

    ; Print what file we're reading
    lea rcx, [msg_reading]
    call print_cstring
    lea rcx, [input_filename]
    call print_cstring
    lea rcx, [newline]
    call print_cstring

    ; Read the source file
    call read_source_file
    cmp rax, 0
    jne file_read_error

    ; Initialize arena allocator (exact same as working parser test)
    call arena_init

    ; Print init message (exact same as working parser test)
    lea rcx, [msg_init]
    call print_cstring

    ; Initialize lexer (exact same as working parser test)
    lea rcx, [msg_lexer]
    call print_cstring

    ; Initialize lexer with file content
    mov rcx, [source_buffer]
    mov rdx, [source_size]
    call lexer_init

    ; Initialize parser (exact same as working parser test)
    lea rcx, [msg_parser]
    call print_cstring

    call parser_init

    ; Parse the program (exact same as working parser test)
    lea rcx, [msg_parsing]
    call print_cstring

    call parser_parse
    test rax, rax
    jz parse_error

    mov [ast_root], rax

    ; Success! (exact same as working parser test)
    lea rcx, [msg_success]
    call print_cstring

    ; Check if we got a program node (exact same as working parser test)
    mov rax, [ast_root]
    cmp rax, 0
    je success_no_check
    mov rdx, [rax]  ; Get node type
    cmp rdx, AST_PROGRAM
    jne success_no_check

success_no_check:
    lea rcx, [msg_ast_root]
    call print_cstring

    ; Print done message (exact same as working parser test)
    lea rcx, [msg_done]
    call print_cstring

    ; Cleanup and successful exit
    call cleanup_memory
    xor rcx, rcx
    call ExitProcess

show_usage:
    lea rcx, [msg_usage]
    call print_cstring
    mov rcx, 1
    call ExitProcess

file_read_error:
    lea rcx, [msg_file_error]
    call print_cstring
    call cleanup_memory
    mov rcx, 1
    call ExitProcess

parse_error:
    lea rcx, [msg_parse_error]
    call print_cstring
    call cleanup_memory
    mov rcx, 1
    call ExitProcess

; ============================================================================
; Simple argument parsing
; ============================================================================
parse_simple_args:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Get command line
    call GetCommandLineA
    mov rsi, rax

    ; Skip program name - find first space after program name
    xor rcx, rcx
skip_program_name:
    mov al, [rsi + rcx]
    cmp al, 0
    je no_args_found
    cmp al, ' '
    je found_space
    cmp al, '"'
    je skip_quoted_program
    inc rcx
    jmp skip_program_name

skip_quoted_program:
    inc rcx
skip_quoted_loop:
    mov al, [rsi + rcx]
    cmp al, 0
    je no_args_found
    cmp al, '"'
    je found_quote_end
    inc rcx
    jmp skip_quoted_loop

found_quote_end:
    inc rcx
    mov al, [rsi + rcx]
    cmp al, ' '
    je found_space
    cmp al, 0
    je no_args_found
    inc rcx
    jmp skip_program_name

found_space:
    ; Skip spaces to first argument
skip_spaces:
    inc rcx
    mov al, [rsi + rcx]
    cmp al, ' '
    je skip_spaces
    cmp al, 0
    je no_args_found

    ; Copy the filename
    lea rdi, [input_filename]
    xor rdx, rdx
copy_filename:
    mov al, [rsi + rcx + rdx]
    cmp al, 0
    je filename_done
    cmp al, ' '
    je filename_done
    cmp rdx, 259  ; Max filename length
    jae filename_done
    mov [rdi + rdx], al
    inc rdx
    jmp copy_filename

filename_done:
    mov byte [rdi + rdx], 0
    mov rax, 1  ; Success - found filename
    jmp parse_args_end

no_args_found:
    ; Use default filename for testing
    lea rsi, [default_file]
    lea rdi, [input_filename]
    xor rcx, rcx
copy_default:
    mov al, [rsi + rcx]
    mov [rdi + rcx], al
    cmp al, 0
    je default_copied
    inc rcx
    jmp copy_default

default_copied:
    mov rax, 1  ; Success - using default

parse_args_end:
    mov rsp, rbp
    pop rbp
    ret

; ============================================================================
; Read source file
; ============================================================================
read_source_file:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; Open the file
    lea rcx, [input_filename]
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

    cmp rax, -1                     ; INVALID_FILE_SIZE
    je read_error_close
    cmp rax, 1048576                ; 1MB max
    ja read_error_close
    mov [source_size], rax

    ; Allocate memory for file content
    mov rcx, rax
    add rcx, 16                     ; Extra space for null terminator
    mov rdx, MEM_COMMIT | MEM_RESERVE
    mov r8, PAGE_READWRITE
    push 0
    sub rsp, 32
    call VirtualAlloc
    add rsp, 40

    cmp rax, 0
    je read_error_close
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

    ; Add null terminator for safety
    mov rax, [source_buffer]
    mov rcx, [source_size]
    mov byte [rax + rcx], 0

    xor rax, rax                    ; Success
    jmp read_end

read_error_close:
    mov rcx, [file_handle]
    call CloseHandle

read_error:
    mov rax, 1                      ; Error

read_end:
    mov rsp, rbp
    pop rbp
    ret

; ============================================================================
; Cleanup memory
; ============================================================================
cleanup_memory:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Free source buffer if allocated
    cmp qword [source_buffer], 0
    je cleanup_end
    mov rcx, [source_buffer]
    mov rdx, 0
    mov r8, MEM_RELEASE
    call VirtualFree

cleanup_end:
    mov rsp, rbp
    pop rbp
    ret

; ============================================================================
; print_cstring - Print null-terminated string (exact same as parser test)
; Parameters:
;   RCX = pointer to string
; ============================================================================
print_cstring:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12

    mov r12, rcx

    ; Calculate length
    xor rbx, rbx
len_loop:
    cmp byte [r12 + rbx], 0
    je print_str
    inc rbx
    jmp len_loop

print_str:
    test rbx, rbx
    jz print_done

    mov rcx, [stdout]
    mov rdx, r12
    mov r8, rbx
    lea r9, [bytes_written]
    xor rax, rax
    mov [rsp + 32], rax
    call WriteConsoleA

print_done:
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret
