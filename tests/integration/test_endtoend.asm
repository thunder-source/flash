; ============================================================================
; Flash Compiler - Comprehensive End-to-End Integration Test
; ============================================================================
; Tests the full pipeline: lexer → parser → semantic → IR → codegen
; with a real Flash program (comprehensive.fl equivalent)
; ============================================================================

bits 64
default rel

extern arena_init
extern lexer_init
extern lexer_tokenize
extern parser_init
extern parser_parse_program
extern analyze_semantic_program
extern ir_program_create
extern ir_generate_program
extern optimize_ir_program
extern codegen_generate_program
extern GetStdHandle
extern WriteFile
extern ExitProcess

%define STD_OUTPUT_HANDLE -11

section .data
    ; Simple test program (subset of comprehensive.fl)
    test_program db "fn add(a: i32, b: i32) -> i32 { return a + b; } fn main() -> i32 { let x = 10; let y = 20; let z = add(x, y); print_int(z); return 0; }", 0
    
    msg_start       db "=== Flash Compiler Integration Test ===", 13, 10, 0
    msg_arena       db "1. Initializing memory arena...", 13, 10, 0
    msg_lexer       db "2. Running lexer...", 13, 10, 0
    msg_parser      db "3. Running parser...", 13, 10, 0
    msg_semantic    db "4. Running semantic analysis...", 13, 10, 0
    msg_ir_gen      db "5. Generating IR...", 13, 10, 0
    msg_optimize    db "6. Optimizing...", 13, 10, 0
    msg_codegen     db "7. Generating x86-64 code...", 13, 10, 0
    msg_success     db "SUCCESS: All compilation phases completed!", 13, 10, 0
    msg_error       db "ERROR: Compilation failed at phase: ", 0
    msg_phase       db "unknown", 13, 10, 0
    msg_newline     db 13, 10, 0
    
    phase1          db "Arena Init", 0
    phase2          db "Lexer", 0
    phase3          db "Parser", 0
    phase4          db "Semantic", 0
    phase5          db "IR Gen", 0
    phase6          db "Optimize", 0
    phase7          db "Codegen", 0
    
section .bss
    stdout          resq 1
    bytes_written   resq 1
    lexer_ctx       resq 1
    parser_ctx      resq 1
    ast_program     resq 1
    ir_program      resq 1

section .text

global main

; Simple print helper
print_string:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rsi
    
    mov rsi, rcx        ; String
    xor rdx, rdx
.len_loop:
    cmp byte [rsi + rdx], 0
    je .len_done
    inc rdx
    jmp .len_loop
    
.len_done:
    mov rcx, [stdout]
    mov r8, rdx         ; Length
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0
    call WriteFile
    
    pop rsi
    add rsp, 32
    pop rbp
    ret

main:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    push rbx
    
    ; Get stdout
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout], rax
    
    ; Header
    lea rcx, [msg_start]
    call print_string
    lea rcx, [msg_newline]
    call print_string
    
    ; Phase 1: Arena
    lea rcx, [msg_arena]
    call print_string
    xor rcx, rcx
    call arena_init
    test rax, rax
    jz .error_phase1
    
    ; Phase 2: Lexer
    lea rcx, [msg_lexer]
    call print_string
    lea rcx, [test_program]
    call lexer_init
    test rax, rax
    jz .error_phase2
    mov [lexer_ctx], rax
    
    ; Phase 3: Parser
    lea rcx, [msg_parser]
    call print_string
    call parser_init
    test rax, rax
    jz .error_phase3
    mov [parser_ctx], rax
    call parser_parse_program
    test rax, rax
    jz .error_phase3
    mov [ast_program], rax
    
    ; Phase 4: Semantic Analysis
    lea rcx, [msg_semantic]
    call print_string
    mov rcx, [ast_program]
    call analyze_semantic_program
    test rax, rax
    jz .error_phase4
    
    ; Phase 5: IR Generation
    lea rcx, [msg_ir_gen]
    call print_string
    call ir_program_create
    test rax, rax
    jz .error_phase5
    mov [ir_program], rax
    
    mov rcx, [ast_program]
    mov rdx, [ir_program]
    call ir_generate_program
    test rax, rax
    jnz .error_phase5
    
    ; Phase 6: Optimization
    lea rcx, [msg_optimize]
    call print_string
    mov rcx, [ir_program]
    call optimize_ir_program
    test rax, rax
    jnz .error_phase6
    
    ; Phase 7: Code Generation
    lea rcx, [msg_codegen]
    call print_string
    mov rcx, [ir_program]
    call codegen_generate_program
    test rax, rax
    jnz .error_phase7
    
    ; Success
    lea rcx, [msg_success]
    call print_string
    
    xor rcx, rcx
    call ExitProcess
    jmp .exit
    
.error_phase1:
    lea rcx, [msg_error]
    call print_string
    lea rcx, [phase1]
    call print_string
    mov rcx, 1
    call ExitProcess
    
.error_phase2:
    lea rcx, [msg_error]
    call print_string
    lea rcx, [phase2]
    call print_string
    mov rcx, 2
    call ExitProcess
    
.error_phase3:
    lea rcx, [msg_error]
    call print_string
    lea rcx, [phase3]
    call print_string
    mov rcx, 3
    call ExitProcess
    
.error_phase4:
    lea rcx, [msg_error]
    call print_string
    lea rcx, [phase4]
    call print_string
    mov rcx, 4
    call ExitProcess
    
.error_phase5:
    lea rcx, [msg_error]
    call print_string
    lea rcx, [phase5]
    call print_string
    mov rcx, 5
    call ExitProcess
    
.error_phase6:
    lea rcx, [msg_error]
    call print_string
    lea rcx, [phase6]
    call print_string
    mov rcx, 6
    call ExitProcess
    
.error_phase7:
    lea rcx, [msg_error]
    call print_string
    lea rcx, [phase7]
    call print_string
    mov rcx, 7
    call ExitProcess
    
.exit:
    pop rbx
    add rsp, 64
    pop rbp
    ret
