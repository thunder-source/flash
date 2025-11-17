; ============================================================================
; Flash Compiler - Compilation Driver
; ============================================================================
; Implements the main compilation pipeline:
; 1. Read source file
; 2. Lexical analysis (tokenization)
; 3. Syntactic analysis (parsing to AST)
; 4. Semantic analysis (type checking, symbol resolution)
; 5. Code generation
; 6. Write output file
; ============================================================================

%include "cli.inc"

bits 64
default rel

; External dependencies
extern printf
extern fprintf
extern stderr
extern malloc
extern free

; File I/O
extern file_read_all
extern file_write_all

; Compiler components
extern lexer_init
extern parser_parse
extern analyze_semantic
extern codegen_generate

; ============================================================================
; Data Section
; ============================================================================
section .data
    ; Error messages
    error_read_file      db "error: could not read file: %s", 0x0A, 0
    error_write_file     db "error: could not write file: %s", 0x0A, 0
    error_compilation    db "error: compilation failed", 0x0A, 0
    error_no_input       db "error: no input file specified", 0x0A, 0
    error_no_output      db "error: no output file specified", 0x0A, 0
    error_lexer          db "error: lexical analysis failed", 0x0A, 0
    error_parser         db "error: syntax error", 0x0A, 0
    error_semantic       db "error: semantic analysis failed", 0x0A, 0
    error_codegen        db "error: code generation failed", 0x0A, 0

; ============================================================================
; Text Section
; ============================================================================
section .text

; ============================================================================
; Compile a source file
; Arguments:
;   rcx = input filename (null-terminated)
;   rdx = output filename (null-terminated, NULL for default)
;   r8  = optimization level (0-3)
; Returns:
;   eax = 0 on success, non-zero on error
; ============================================================================
global compile_file
compile_file:
    push rbp
    mov rbp, rsp
    sub rsp, 32 + 8*6    ; Shadow space + 6 parameters + local vars

    ; Save non-volatile registers
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    ; Save arguments
    mov [rbp-8], rcx     ; input_filename
    mov [rbp-16], rdx    ; output_filename
    mov [rbp-20], r8d    ; optimization_level (dword)
    
    ; Initialize locals
    mov qword [rbp-28], 0 ; source_buffer
    mov qword [rbp-36], 0 ; source_size
    mov qword [rbp-44], 0 ; ast_root
    mov qword [rbp-52], 0 ; output_buffer
    mov qword [rbp-60], 0 ; output_size

    ; 1. Check input file
    test rcx, rcx
    jz .error_no_input

    ; 2. Read source file
    call file_read_all
    test rax, rax
    jz .read_error
    
    mov [rbp-28], rax    ; source_buffer
    mov [rbp-36], rdx    ; source_size

    ; 3. Initialize lexer
    mov rcx, rax         ; source_buffer
    mov rdx, rdx         ; source_size
    call lexer_init
    test eax, eax
    jnz .lexer_error

    ; 4. Parse source to AST
    call parser_parse
    test rax, rax
    jz .parser_error
    
    mov [rbp-44], rax    ; ast_root

    ; 5. Semantic analysis
    mov rcx, rax         ; ast_root
    call analyze_semantic
    test eax, eax
    jnz .semantic_error

    ; 6. Generate code
    mov rcx, [rbp-44]    ; ast_root
    mov edx, [rbp-20]    ; optimization_level
    call codegen_generate
    test rax, rax
    jz .codegen_error
    
    mov [rbp-52], rax    ; output_buffer
    mov [rbp-60], rdx    ; output_size

    ; 7. Generate output filename if not provided
    mov rcx, [rbp-16]    ; output_filename
    test rcx, rcx
    jnz .write_output
    
    ; Generate default output filename (input.asm)
    mov rcx, [rbp-8]     ; input_filename
    call generate_output_filename
    test rax, rax
    jz .error_no_output
    mov [rbp-16], rax    ; output_filename

.write_output:
    ; 8. Write output file
    mov rcx, [rbp-16]    ; output_filename
    mov rdx, [rbp-52]    ; output_buffer
    mov r8, [rbp-60]     ; output_size
    call file_write_all
    test eax, eax
    jnz .write_error

    ; Success - clean up and return 0
    xor eax, eax
    jmp .cleanup

.error_no_input:
    lea rcx, [error_no_input]
    jmp .print_error

.read_error:
    lea rcx, [error_read_file]
    mov rdx, [rbp-8]     ; input_filename
    jmp .print_error

.lexer_error:
    lea rcx, [error_lexer]
    jmp .print_error

.parser_error:
    lea rcx, [error_parser]
    jmp .print_error

.semantic_error:
    lea rcx, [error_semantic]
    jmp .print_error

.codegen_error:
    lea rcx, [error_codegen]
    jmp .print_error

.write_error:
    lea rcx, [error_write_file]
    mov rdx, [rbp-16]    ; output_filename
    jmp .print_error

.print_error:
    ; Print error message to stderr
    push rcx
    mov rcx, [stderr]
    pop rdx
    call fprintf
    mov eax, 1           ; Return error code 1

.cleanup:
    ; Free allocated resources
    
    ; Free source buffer
    mov rcx, [rbp-28]    ; source_buffer
    test rcx, rcx
    jz .no_source_cleanup
    call free

.no_source_cleanup:
    ; Free AST (if parser provides a free function)
    ; mov rcx, [rbp-44]  ; ast_root
    ; test rcx, rcx
    ; jz .no_ast_cleanup
    ; call ast_free

.no_ast_cleanup:
    ; Free output buffer
    mov rcx, [rbp-52]    ; output_buffer
    test rcx, rcx
    jz .no_output_cleanup
    call free

.no_output_cleanup:
    ; Restore non-volatile registers
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    
    mov rsp, rbp
    pop rbp
    ret

; ============================================================================
; Generate default output filename (input.asm)
; Arguments:
;   rcx = input filename (null-terminated)
; Returns:
;   rax = pointer to new filename (must be freed by caller), NULL on error
; ===========================================================================
generate_output_filename:
    push rbp
    mov rbp, rsp
    sub rsp, 32 + 8*3    ; Shadow space + 3 parameters + local vars

    ; Save non-volatile registers
    push rbx
    push rsi
    push rdi
    push r12

    ; Find the end of the input filename
    mov rdi, rcx
    xor al, al
    mov rcx, -1
    repne scasb
    not rcx
    dec rcx              ; rcx = strlen(input_filename)
    mov rsi, [rbp+16]    ; input_filename
    mov rdi, rcx         ; save length

    ; Find the last dot or backslash
    lea rdx, [rsi + rcx - 1] ; point to last character
    mov r8, rdx          ; save end pointer
    std                  ; set direction flag for backwards search

    ; Search for dot
    mov al, '.'
    repne scasb
    jne .no_extension
    
    ; Found dot, check if it's part of a path
    mov r9, rdi          ; save dot position
    mov al, '\'
    mov rcx, r8          ; end pointer
    sub rcx, r9          ; length from dot to end
    jbe .no_slash_after_dot
    
    repne scasb
    jne .has_extension

.no_slash_after_dot:
    ; Found a slash after dot, so no extension
    mov rdi, r9          ; restore dot position
    jmp .no_extension

.has_extension:
    ; Found extension, replace it
    mov rdi, r9          ; point to dot
    jmp .copy_base

.no_extension:
    cld                  ; clear direction flag
    lea rdi, [rsi + rcx] ; point to null terminator

.copy_base:
    ; Calculate length of base filename
    mov rcx, rdi
    sub rcx, rsi         ; length of base name
    
    ; Allocate memory for new filename (base + ".asm\0")
    lea rdx, [rcx + 5]   ; +5 for ".asm\0"
    mov rcx, rdx
    call malloc
    test rax, rax
    jz .error
    
    ; Copy base filename
    mov rdi, rax         ; destination
    mov rsi, [rbp+16]    ; source
    mov rcx, rdx         ; length
    rep movsb
    
    ; Append ".asm"
    mov dword [rdi-1], '.asm'
    mov byte [rdi+3], 0
    
    jmp .done

.error:
    xor rax, rax         ; return NULL on error

.done:
    cld                  ; ensure direction flag is cleared
    pop r12
    pop rdi
    pop rsi
    pop rbx
    mov rsp, rbp
    pop rbp
    ret
