; ============================================================================
; Flash Compiler - Fixed CLI Entry Point
; ============================================================================
; A corrected command-line interface that properly handles file I/O
; Fixes the argument parsing and file reading issues in the original
; ============================================================================

bits 64
default rel

; External functions from compiler components
extern arena_init
extern lexer_init
extern parser_init
extern parser_parse
extern analyze_semantic
extern ir_program_create
extern ir_generate_from_ast
extern optimize_ir_program
extern codegen_generate
extern GetStdHandle
extern WriteConsoleA
extern ReadFile
extern CreateFileA
extern WriteFile
extern CloseHandle
extern GetCommandLineA
extern GetFileSize
extern VirtualAlloc
extern VirtualFree
extern ExitProcess

; Constants
%define STD_OUTPUT_HANDLE -11
%define STD_ERROR_HANDLE -12
%define GENERIC_READ 0x80000000
%define GENERIC_WRITE 0x40000000
%define OPEN_EXISTING 3
%define CREATE_ALWAYS 2
%define FILE_ATTRIBUTE_NORMAL 0x80
%define MEM_COMMIT 0x1000
%define MEM_RESERVE 0x2000
%define PAGE_READWRITE 0x04
%define MEM_RELEASE 0x8000

%define MAX_SOURCE_SIZE 1048576    ; 1MB max source file
%define MAX_OUTPUT_SIZE 4194304    ; 4MB max output file
%define MAX_PATH 260

%define VERSION_STRING "Flash Compiler v0.2.0 - Fixed CLI"

; ============================================================================
; Compiler Context Structure
; ============================================================================
struc CompilerContext
    .source_buffer:     resq 1      ; Pointer to source code
    .source_size:       resq 1      ; Source file size
    .output_buffer:     resq 1      ; Pointer to output assembly
    .output_size:       resq 1      ; Output size
    .ast_program:       resq 1      ; AST root node
    .ir_program:        resq 1      ; IR program
    .error_code:        resq 1      ; Error status (0 = success)
    .error_msg:         resq 1      ; Error message pointer
    .input_filename:    resb MAX_PATH
    .output_filename:   resb MAX_PATH
endstruc

; ============================================================================
; Data Section
; ============================================================================
section .data
    ; Version and usage messages
    version_msg db VERSION_STRING, 0dh, 0ah, 0
    version_len equ $ - version_msg

    usage_msg db "Usage: flash [options] <input.fl>", 0dh, 0ah
              db "  -o <file>    Specify output file", 0dh, 0ah
              db "  -v           Verbose mode", 0dh, 0ah
              db "  --version    Show version", 0dh, 0ah
              db "  --help       Show this help", 0dh, 0ah, 0
    usage_len equ $ - usage_msg

    ; Status messages
    compiling_msg db "Flash Compiler: Processing ", 0
    success_msg db "Compilation successful", 0dh, 0ah, 0
    success_len equ $ - success_msg

    ; Error messages
    error_no_input db "Error: No input file specified", 0dh, 0ah, 0
    error_no_input_len equ $ - error_no_input

    error_file_not_found db "Error: Input file not found - ", 0

    error_file_too_large db "Error: Input file too large (max 1MB)", 0dh, 0ah, 0
    error_file_too_large_len equ $ - error_file_too_large

    error_memory_alloc db "Error: Memory allocation failed", 0dh, 0ah, 0
    error_memory_alloc_len equ $ - error_memory_alloc

    error_compilation db "Error: Compilation failed", 0dh, 0ah, 0
    error_compilation_len equ $ - error_compilation

    ; Phase messages
    phase_lexer db "Phase 1: Lexical analysis...", 0dh, 0ah, 0
    phase_lexer_len equ $ - phase_lexer

    phase_parser db "Phase 2: Parsing and AST generation...", 0dh, 0ah, 0
    phase_parser_len equ $ - phase_parser

    phase_complete db "Phase 3: Compilation phases completed!", 0dh, 0ah, 0
    phase_complete_len equ $ - phase_complete

    ; Command line parsing
    arg_help db "--help", 0
    arg_version db "--version", 0
    arg_verbose db "-v", 0
    arg_output db "-o", 0

    newline db 0dh, 0ah, 0

; ============================================================================
; BSS Section
; ============================================================================
section .bss
    compiler_context resb CompilerContext_size
    bytes_read resq 1
    bytes_written resq 1
    file_handle resq 1
    stdout_handle resq 1
    stderr_handle resq 1
    verbose_mode resb 1

    ; Command line parsing variables
    cmdline_ptr resq 1
    arg_count resq 1
    current_arg resq 1
    input_file_found resb 1

; ============================================================================
; Text Section
; ============================================================================
section .text
global main

main:
    ; Prologue
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; Initialize compiler context
    lea rcx, [compiler_context]
    call init_compiler_context

    ; Get standard handles
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout_handle], rax

    mov rcx, STD_ERROR_HANDLE
    call GetStdHandle
    mov [stderr_handle], rax

    ; Parse command line arguments
    call parse_command_line_fixed
    cmp rax, 0
    jne exit_with_error

    ; Check if we have an input file
    lea rsi, [compiler_context + CompilerContext.input_filename]
    cmp byte [rsi], 0
    je show_usage

    ; Print what we're compiling
    call print_compilation_start

    ; Read input file
    call read_source_file_fixed
    cmp rax, 0
    jne exit_with_error

    ; Initialize compiler components
    call init_compiler_components

    ; Run compilation pipeline
    call run_compilation_pipeline
    cmp rax, 0
    jne compilation_failed

    ; Print success message
    mov rcx, [stdout_handle]
    lea rdx, [success_msg]
    mov r8, success_len
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Success exit
    xor rax, rax
    jmp cleanup_and_exit

show_usage:
    mov rcx, [stdout_handle]
    lea rdx, [usage_msg]
    mov r8, usage_len
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40
    xor rax, rax
    jmp cleanup_and_exit

compilation_failed:
    mov rcx, [stderr_handle]
    lea rdx, [error_compilation]
    mov r8, error_compilation_len
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40
    mov rax, 1
    jmp cleanup_and_exit

exit_with_error:
    mov rax, 1

cleanup_and_exit:
    ; Cleanup memory allocations
    call cleanup_compiler_context

    ; Epilogue and exit
    mov rsp, rbp
    pop rbp
    mov rcx, rax
    call ExitProcess

; ============================================================================
; Helper Functions
; ============================================================================

init_compiler_context:
    push rbp
    mov rbp, rsp

    ; Zero out the compiler context
    lea rdi, [compiler_context]
    mov rcx, CompilerContext_size
    xor rax, rax
    rep stosb

    ; Initialize flags
    mov byte [verbose_mode], 0
    mov byte [input_file_found], 0

    mov rsp, rbp
    pop rbp
    ret

parse_command_line_fixed:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; Get command line
    call GetCommandLineA
    mov [cmdline_ptr], rax

    ; Skip program name - find first space
    mov rsi, rax
    xor rcx, rcx
.skip_program:
    mov al, [rsi + rcx]
    cmp al, 0
    je .no_args
    cmp al, ' '
    je .found_space
    inc rcx
    jmp .skip_program

.found_space:
    ; Skip spaces
.skip_spaces:
    inc rcx
    mov al, [rsi + rcx]
    cmp al, ' '
    je .skip_spaces
    cmp al, 0
    je .no_args

    ; Now process arguments
    lea rdi, [rsi + rcx]  ; Start of first argument

.parse_loop:
    mov al, [rdi]
    cmp al, 0
    je .parse_done

    ; Check for options
    cmp byte [rdi], '-'
    je .handle_option

    ; Must be input filename
    call copy_input_filename
    mov byte [input_file_found], 1
    jmp .next_arg

.handle_option:
    ; Check for --help
    lea rcx, [arg_help]
    mov rdx, rdi
    call compare_arg
    cmp rax, 0
    je .show_help

    ; Check for --version
    lea rcx, [arg_version]
    mov rdx, rdi
    call compare_arg
    cmp rax, 0
    je .show_version

    ; Check for -v
    lea rcx, [arg_verbose]
    mov rdx, rdi
    call compare_arg
    cmp rax, 0
    je .set_verbose

    ; Unknown option - skip
    jmp .next_arg

.show_help:
    mov rcx, [stdout_handle]
    lea rdx, [usage_msg]
    mov r8, usage_len
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40
    mov rax, 1  ; Exit after showing help
    jmp .parse_end

.show_version:
    mov rcx, [stdout_handle]
    lea rdx, [version_msg]
    mov r8, version_len
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40
    mov rax, 1  ; Exit after showing version
    jmp .parse_end

.set_verbose:
    mov byte [verbose_mode], 1
    jmp .next_arg

.next_arg:
    ; Skip to next argument
.skip_current:
    mov al, [rdi]
    cmp al, 0
    je .parse_done
    cmp al, ' '
    je .found_next_space
    inc rdi
    jmp .skip_current

.found_next_space:
    ; Skip spaces to next arg
.skip_next_spaces:
    inc rdi
    mov al, [rdi]
    cmp al, ' '
    je .skip_next_spaces
    cmp al, 0
    je .parse_done
    jmp .parse_loop

.no_args:
.parse_done:
    ; Generate output filename if we have input
    cmp byte [input_file_found], 0
    je .no_input_error
    call generate_output_filename
    xor rax, rax  ; Success
    jmp .parse_end

.no_input_error:
    mov rax, 1  ; Error - no input file

.parse_end:
    mov rsp, rbp
    pop rbp
    ret

copy_input_filename:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    lea rbx, [compiler_context + CompilerContext.input_filename]
    mov r12, rdi
    xor rcx, rcx

.copy_loop:
    mov al, [r12 + rcx]
    cmp al, 0
    je .copy_done
    cmp al, ' '
    je .copy_done
    cmp rcx, MAX_PATH - 1
    jae .copy_done
    mov [rbx + rcx], al
    inc rcx
    jmp .copy_loop

.copy_done:
    mov byte [rbx + rcx], 0

    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

compare_arg:
    push rbp
    mov rbp, rsp

    ; RCX = expected string, RDX = actual string
    xor rax, rax
.cmp_loop:
    mov r8b, [rcx + rax]
    mov r9b, [rdx + rax]

    ; Check if expected string ended
    cmp r8b, 0
    je .check_actual_end

    ; Check if they match
    cmp r8b, r9b
    jne .not_equal

    inc rax
    jmp .cmp_loop

.check_actual_end:
    ; Expected ended, check if actual also ended or has space
    cmp r9b, 0
    je .equal
    cmp r9b, ' '
    je .equal

.not_equal:
    mov rax, 1
    jmp .cmp_end

.equal:
    mov rax, 0

.cmp_end:
    mov rsp, rbp
    pop rbp
    ret

generate_output_filename:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    lea rbx, [compiler_context + CompilerContext.input_filename]
    lea r12, [compiler_context + CompilerContext.output_filename]

    ; Copy input filename to output
    xor rcx, rcx
.gen_copy:
    mov al, [rbx + rcx]
    cmp al, 0
    je .gen_done_copy
    cmp al, '.'
    je .gen_replace_ext
    mov [r12 + rcx], al
    inc rcx
    jmp .gen_copy

.gen_replace_ext:
    ; Replace extension with .asm
    mov byte [r12 + rcx], '.'
    inc rcx
    mov byte [r12 + rcx], 'a'
    inc rcx
    mov byte [r12 + rcx], 's'
    inc rcx
    mov byte [r12 + rcx], 'm'
    inc rcx
    mov byte [r12 + rcx], 0
    jmp .gen_end

.gen_done_copy:
    ; Add .asm extension
    mov byte [r12 + rcx], '.'
    inc rcx
    mov byte [r12 + rcx], 'a'
    inc rcx
    mov byte [r12 + rcx], 's'
    inc rcx
    mov byte [r12 + rcx], 'm'
    inc rcx
    mov byte [r12 + rcx], 0

.gen_end:
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

print_compilation_start:
    push rbp
    mov rbp, rsp

    ; Print "Flash Compiler: Processing "
    mov rcx, [stdout_handle]
    lea rdx, [compiling_msg]
    mov r8, 27  ; length
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Print filename
    mov rcx, [stdout_handle]
    lea rdx, [compiler_context + CompilerContext.input_filename]
    mov r8, MAX_PATH
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; Print newline
    mov rcx, [stdout_handle]
    lea rdx, [newline]
    mov r8, 2
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    mov rsp, rbp
    pop rbp
    ret

read_source_file_fixed:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; Open input file
    lea rcx, [compiler_context + CompilerContext.input_filename]
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
    je .file_not_found_error
    mov [file_handle], rax

    ; Get file size
    mov rcx, [file_handle]
    mov rdx, 0
    call GetFileSize

    cmp rax, -1                     ; INVALID_FILE_SIZE
    je .file_error
    cmp rax, MAX_SOURCE_SIZE
    ja .file_too_large_error

    mov [compiler_context + CompilerContext.source_size], rax

    ; Allocate memory for source (add extra space for null terminator)
    mov rcx, rax
    add rcx, 16                     ; Extra space for safety
    mov rdx, MEM_COMMIT | MEM_RESERVE
    mov r8, PAGE_READWRITE
    push 0
    sub rsp, 32
    call VirtualAlloc
    add rsp, 40

    cmp rax, 0
    je .memory_alloc_error
    mov [compiler_context + CompilerContext.source_buffer], rax

    ; Read file content
    mov rcx, [file_handle]
    mov rdx, [compiler_context + CompilerContext.source_buffer]
    mov r8, [compiler_context + CompilerContext.source_size]
    lea r9, [bytes_read]
    push 0
    sub rsp, 32
    call ReadFile
    add rsp, 40

    cmp rax, 0
    je .read_error

    ; Close file handle
    mov rcx, [file_handle]
    call CloseHandle

    ; Add null terminator for safety
    mov rax, [compiler_context + CompilerContext.source_buffer]
    mov rcx, [compiler_context + CompilerContext.source_size]
    mov byte [rax + rcx], 0

    xor rax, rax                    ; Success
    jmp .read_end

.file_not_found_error:
    ; Print error with filename
    mov rcx, [stderr_handle]
    lea rdx, [error_file_not_found]
    mov r8, 30  ; length of "Error: Input file not found - "
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    mov rcx, [stderr_handle]
    lea rdx, [compiler_context + CompilerContext.input_filename]
    mov r8, MAX_PATH
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    mov rcx, [stderr_handle]
    lea rdx, [newline]
    mov r8, 2
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    mov rax, 1
    jmp .read_end

.file_too_large_error:
    mov rcx, [file_handle]
    call CloseHandle

    mov rcx, [stderr_handle]
    lea rdx, [error_file_too_large]
    mov r8, error_file_too_large_len
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40
    mov rax, 1
    jmp .read_end

.memory_alloc_error:
    mov rcx, [file_handle]
    call CloseHandle

    mov rcx, [stderr_handle]
    lea rdx, [error_memory_alloc]
    mov r8, error_memory_alloc_len
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40
    mov rax, 1
    jmp .read_end

.read_error:
.file_error:
    mov rcx, [file_handle]
    call CloseHandle
    mov rax, 1

.read_end:
    mov rsp, rbp
    pop rbp
    ret

init_compiler_components:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Initialize arena allocator
    call arena_init

    ; Initialize lexer with source buffer
    mov rcx, [compiler_context + CompilerContext.source_buffer]
    mov rdx, [compiler_context + CompilerContext.source_size]
    call lexer_init

    ; Initialize parser
    call parser_init

    mov rsp, rbp
    pop rbp
    ret

run_compilation_pipeline:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Phase 1: Lexical Analysis
    cmp byte [verbose_mode], 0
    je .skip_lexer_verbose
    mov rcx, [stdout_handle]
    lea rdx, [phase_lexer]
    mov r8, phase_lexer_len
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

.skip_lexer_verbose:
    ; Phase 2: Parsing
    cmp byte [verbose_mode], 0
    je .skip_parser_verbose
    mov rcx, [stdout_handle]
    lea rdx, [phase_parser]
    mov r8, phase_parser_len
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

.skip_parser_verbose:
    ; Run parser
    call parser_parse
    cmp rax, 0
    je .parsing_failed

    ; Store AST result
    mov [compiler_context + CompilerContext.ast_program], rax

    ; Phase complete
    cmp byte [verbose_mode], 0
    je .skip_complete_verbose
    mov rcx, [stdout_handle]
    lea rdx, [phase_complete]
    mov r8, phase_complete_len
    lea r9, [bytes_written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

.skip_complete_verbose:
    xor rax, rax                    ; Success
    jmp .pipeline_end

.parsing_failed:
    mov rax, 1                      ; Error

.pipeline_end:
    mov rsp, rbp
    pop rbp
    ret

cleanup_compiler_context:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Free source buffer if allocated
    cmp qword [compiler_context + CompilerContext.source_buffer], 0
    je .skip_source_cleanup
    mov rcx, [compiler_context + CompilerContext.source_buffer]
    mov rdx, 0
    mov r8, MEM_RELEASE
    call VirtualFree

.skip_source_cleanup:
    ; Free output buffer if allocated
    cmp qword [compiler_context + CompilerContext.output_buffer], 0
    je .skip_output_cleanup
    mov rcx, [compiler_context + CompilerContext.output_buffer]
    mov rdx, 0
    mov r8, MEM_RELEASE
    call VirtualFree

.skip_output_cleanup:
    mov rsp, rbp
    pop rbp
    ret
