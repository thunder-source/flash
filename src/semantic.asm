; ============================================================================
; Flash Compiler - Semantic Analyzer
; ============================================================================
; Type checking, symbol resolution, and semantic validation
; ============================================================================

bits 64
default rel

extern symtable_init
extern symtable_insert
extern symtable_lookup
extern symtable_enter_scope
extern symtable_exit_scope
extern arena_alloc

; Include AST node type definitions
%define AST_PROGRAM         0
%define AST_FUNCTION        1
%define AST_STRUCT_DEF      2
%define AST_BLOCK           20
%define AST_LET_STMT        21
%define AST_ASSIGN_STMT     22
%define AST_IF_STMT         23
%define AST_WHILE_STMT      24
%define AST_FOR_STMT        25
%define AST_RETURN_STMT     26
%define AST_BREAK_STMT      27
%define AST_CONTINUE_STMT   28
%define AST_EXPR_STMT       29
%define AST_BINARY_EXPR     50
%define AST_UNARY_EXPR      51
%define AST_LITERAL_EXPR    52
%define AST_IDENTIFIER      53
%define AST_CALL_EXPR       54

; Symbol types
%define SYM_VARIABLE    0
%define SYM_FUNCTION    1
%define SYM_PARAMETER   2

; Type kinds
%define TYPE_I32        2
%define TYPE_VOID       13
%define TYPE_ERROR      255

; ============================================================================
; Symbol Structure (from symtable.asm)
; ============================================================================
struc Symbol
    .name:          resq 1
    .name_len:      resq 1
    .type:          resq 1
    .data_type:     resq 1
    .scope_level:   resq 1
    .is_mutable:    resq 1
    .next:          resq 1
    .value:         resq 1
endstruc

; ============================================================================
; Semantic Analyzer State
; ============================================================================
section .bss
    current_function:   resq 1      ; Current function being analyzed
    had_error:          resq 1      ; Error flag
    in_loop:            resq 1      ; Inside loop (for break/continue)

section .data
    msg_undefined db "Undefined symbol", 0
    msg_redefined db "Symbol already defined", 0
    msg_type_mismatch db "Type mismatch", 0
    msg_not_mutable db "Cannot assign to immutable variable", 0
    msg_break_outside_loop db "Break statement outside loop", 0
    msg_continue_outside_loop db "Continue statement outside loop", 0

; ============================================================================
; Code Section
; ============================================================================
section .text

global semantic_analyze
global semantic_analyze_program
global semantic_analyze_function
global semantic_analyze_statement
global semantic_analyze_expression

; ============================================================================
; semantic_analyze - Main entry point for semantic analysis
; Parameters:
;   RCX = pointer to AST root (program node)
; Returns:
;   RAX = 1 if success, 0 if errors
; ============================================================================
semantic_analyze:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    
    mov rbx, rcx        ; Save AST root
    
    ; Initialize symbol table
    call symtable_init
    
    ; Reset error flag
    mov qword [had_error], 0
    mov qword [in_loop], 0
    mov qword [current_function], 0
    
    ; Analyze program
    mov rcx, rbx
    call semantic_analyze_program
    
    ; Check if we had errors
    mov rax, [had_error]
    xor rax, 1          ; Return 1 if no errors
    
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; semantic_analyze_program - Analyze program node
; Parameters:
;   RCX = pointer to program AST node
; Returns:
;   Nothing (sets error flag on failure)
; ============================================================================
semantic_analyze_program:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    
    mov rbx, rcx
    
    ; Get first declaration
    mov r12, [rbx + 8]  ; Assuming declarations list at offset 8
    
.analyze_decl_loop:
    test r12, r12
    jz .done
    
    ; Get declaration node
    mov rax, [r12]      ; Get node pointer
    
    ; Check node type
    mov rcx, [rax]      ; Get node type
    cmp rcx, AST_FUNCTION
    je .analyze_function
    
    ; TODO: Handle other declaration types (struct, enum, const, import)
    jmp .next_decl
    
.analyze_function:
    mov rcx, rax
    call semantic_analyze_function
    
.next_decl:
    mov r12, [r12 + 8]  ; Next declaration
    jmp .analyze_decl_loop
    
.done:
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; semantic_analyze_function - Analyze function declaration
; Parameters:
;   RCX = pointer to function AST node
; Returns:
;   Nothing
; ============================================================================
semantic_analyze_function:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    
    mov rbx, rcx        ; Function node
    mov [current_function], rbx
    
    ; Enter new scope for function
    call symtable_enter_scope
    
    ; TODO: Add function parameters to symbol table
    ; TODO: Analyze function body
    
    ; Get function body (block statement)
    mov r12, [rbx + 32]  ; Assuming body at offset 32
    test r12, r12
    jz .no_body
    
    mov rcx, r12
    call semantic_analyze_statement
    
.no_body:
    ; Exit function scope
    call symtable_exit_scope
    
    mov qword [current_function], 0
    
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; semantic_analyze_statement - Analyze statement node
; Parameters:
;   RCX = pointer to statement AST node
; Returns:
;   Nothing
; ============================================================================
semantic_analyze_statement:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    
    mov rbx, rcx
    
    ; Get statement type
    mov rax, [rbx]
    
    ; Dispatch based on statement type
    cmp rax, AST_BLOCK
    je .block
    cmp rax, AST_LET_STMT
    je .let_stmt
    cmp rax, AST_RETURN_STMT
    je .return_stmt
    cmp rax, AST_BREAK_STMT
    je .break_stmt
    cmp rax, AST_CONTINUE_STMT
    je .continue_stmt
    
    ; TODO: Add more statement types
    jmp .done
    
.block:
    mov rcx, rbx
    call semantic_analyze_block
    jmp .done
    
.let_stmt:
    mov rcx, rbx
    call semantic_analyze_let
    jmp .done
    
.return_stmt:
    mov rcx, rbx
    call semantic_analyze_return
    jmp .done
    
.break_stmt:
    ; Check if inside loop
    mov rax, [in_loop]
    test rax, rax
    jnz .done
    ; Error: break outside loop
    mov qword [had_error], 1
    jmp .done
    
.continue_stmt:
    ; Check if inside loop
    mov rax, [in_loop]
    test rax, rax
    jnz .done
    ; Error: continue outside loop
    mov qword [had_error], 1
    jmp .done
    
.done:
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; semantic_analyze_block - Analyze block statement
; Parameters:
;   RCX = pointer to block AST node
; Returns:
;   Nothing
; ============================================================================
semantic_analyze_block:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    
    mov rbx, rcx
    
    ; Enter new scope
    call symtable_enter_scope
    
    ; Get statements list
    mov r12, [rbx + 8]
    
.analyze_stmt_loop:
    test r12, r12
    jz .done
    
    ; Analyze statement
    mov rcx, [r12]
    call semantic_analyze_statement
    
    ; Next statement
    mov r12, [r12 + 8]
    jmp .analyze_stmt_loop
    
.done:
    ; Exit scope
    call symtable_exit_scope
    
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; semantic_analyze_let - Analyze let statement
; Parameters:
;   RCX = pointer to let statement AST node
; Returns:
;   Nothing
; ============================================================================
semantic_analyze_let:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    
    mov rbx, rcx
    
    ; Create symbol for variable
    mov rcx, Symbol_size
    call arena_alloc
    mov r12, rax
    
    ; Fill in symbol information
    ; TODO: Extract name, type, mutability from AST node
    ; TODO: Insert into symbol table
    
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; semantic_analyze_return - Analyze return statement
; Parameters:
;   RCX = pointer to return statement AST node
; Returns:
;   Nothing
; ============================================================================
semantic_analyze_return:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    
    mov rbx, rcx
    
    ; TODO: Type check return expression against function return type
    
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; semantic_analyze_expression - Analyze expression and return its type
; Parameters:
;   RCX = pointer to expression AST node
; Returns:
;   RAX = type of expression (TYPE_I32, etc.)
; ============================================================================
semantic_analyze_expression:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    
    mov rbx, rcx
    
    ; Get expression type
    mov rax, [rbx]
    
    cmp rax, AST_LITERAL_EXPR
    je .literal
    cmp rax, AST_IDENTIFIER
    je .identifier
    cmp rax, AST_BINARY_EXPR
    je .binary
    
    ; Unknown expression type
    mov rax, TYPE_ERROR
    jmp .done
    
.literal:
    ; Return literal type
    ; TODO: Extract type from literal node
    mov rax, TYPE_I32
    jmp .done
    
.identifier:
    ; Lookup identifier in symbol table
    ; TODO: Implement identifier lookup
    mov rax, TYPE_I32
    jmp .done
    
.binary:
    ; Type check binary expression
    ; TODO: Check both operands and ensure types match
    mov rax, TYPE_I32
    jmp .done
    
.done:
    pop rbx
    add rsp, 32
    pop rbp
    ret
