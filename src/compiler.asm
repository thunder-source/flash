; ============================================================================
; Flash Compiler - Main Compiler Driver
; ============================================================================
; Orchestrates the complete compilation pipeline:
; 1. Read Flash source file
; 2. Lexical analysis (tokenization)
; 3. Syntactic analysis (parsing to AST)
; 4. Semantic analysis (type checking, symbol resolution)
; 5. IR generation (Three-Address Code)
; 6. Optimization passes
; 7. Code generation (x86-64 assembly)
; 8. Write assembly output
; ============================================================================

bits 64
default rel

extern arena_init
extern arena_reset
extern lexer_init
extern parser_init
extern parser_parse
extern analyze_semantic
extern ir_program_create
extern ir_generate_from_ast
extern optimize_ir_program
extern codegen_generate

%define MAX_SOURCE_SIZE 65536
%define MAX_OUTPUT_SIZE 262144

; ============================================================================
; Compiler Context Structure
; ============================================================================
struc CompilerContext
    .source_buffer:     resq 1      ; Source code
    .source_size:       resq 1      ; Source size
    .output_buffer:     resq 1      ; Output assembly
    .output_size:       resq 1      ; Output size
    .ast_program:       resq 1      ; AST root
    .ir_program:        resq 1      ; IR program
    .error_code:        resq 1      ; Error status (0 = success)
    .error_msg:         resq 1      ; Error message
endstruc

; ============================================================================
; Data Section
; ============================================================================
section .data
    ; Messages
    msg_usage           db "Usage: flash_compile <input.fl> <output.asm>", 13, 10, 0
    msg_reading         db "Reading source file...", 13, 10, 0
    msg_lexing          db "Lexical analysis...", 13, 10, 0
    msg_parsing         db "Parsing...", 13, 10, 0
    msg_semantic        db "Semantic analysis...", 13, 10, 0
    msg_ir_gen          db "Generating IR...", 13, 10, 0
    msg_optimize        db "Optimizing...", 13, 10, 0
    msg_codegen         db "Generating code...", 13, 10, 0
    msg_writing         db "Writing output...", 13, 10, 0
    msg_success         db "Compilation successful!", 13, 10, 0
    msg_error           db "Compilation failed: ", 0
    msg_read_error      db "Cannot read source file", 13, 10, 0
    msg_parse_error     db "Parse error", 13, 10, 0
    msg_semantic_error  db "Semantic error", 13, 10, 0
    msg_ir_error        db "IR generation error", 13, 10, 0
    msg_codegen_error   db "Code generation error", 13, 10, 0
    
section .text

global flash_compile

; ============================================================================
; flash_compile - Main compilation function
; Parameters:
;   RCX = input filename
;   RDX = output filename
; Returns:
;   RAX = 0 on success, error code on failure
; ============================================================================
flash_compile:
    push rbp
    mov rbp, rsp
    sub rsp, CompilerContext_size + 32
    push rbx
    push r12
    push r13
    
    mov r12, rcx        ; Input filename
    mov r13, rdx        ; Output filename
    lea rbx, [rbp - CompilerContext_size]  ; Context on stack
    
    ; Initialize arena
    xor rcx, rcx
    call arena_init
    test rax, rax
    jz .error_arena
    
    ; Initialize context
    mov qword [rbx + CompilerContext.error_code], 0
    
    ; Step 1: Read source file
    ; TODO: Implement file reading
    ; For now, assume source is passed in memory
    
    ; Step 2: Lexical analysis
    mov rcx, r12        ; Input file
    call lexer_init
    test rax, rax
    jz .error_lex
    
    ; Step 3: Parse
    call parser_init
    test rax, rax
    jz .error_parse
    call parser_parse
    mov [rbx + CompilerContext.ast_program], rax
    test rax, rax
    jz .error_parse
    
    ; Step 4: Semantic analysis
    mov rcx, [rbx + CompilerContext.ast_program]
    call analyze_semantic
    test rax, rax
    jz .error_semantic
    
    ; Step 5: IR generation
    call ir_program_create
    mov [rbx + CompilerContext.ir_program], rax
    test rax, rax
    jz .error_ir
    
    mov rcx, [rbx + CompilerContext.ast_program]
    call ir_generate_from_ast
    test rax, rax
    jnz .error_ir
    
    ; Step 6: Optimization
    mov rcx, [rbx + CompilerContext.ir_program]
    call optimize_ir_program
    test rax, rax
    jnz .error_optimize
    
    ; Step 7: Code generation
    mov rcx, [rbx + CompilerContext.ir_program]
    mov rdx, r13        ; Output filename
    call codegen_generate
    test rax, rax
    jnz .error_codegen
    
    ; Success
    xor rax, rax
    jmp .exit
    
.error_arena:
    mov rax, 1
    jmp .exit
    
.error_lex:
    mov rax, 2
    jmp .exit
    
.error_parse:
    mov rax, 3
    jmp .exit
    
.error_semantic:
    mov rax, 4
    jmp .exit
    
.error_ir:
    mov rax, 5
    jmp .exit
    
.error_optimize:
    mov rax, 6
    jmp .exit
    
.error_codegen:
    mov rax, 7
    jmp .exit
    
.exit:
    pop r13
    pop r12
    pop rbx
    add rsp, CompilerContext_size + 32
    pop rbp
    ret

