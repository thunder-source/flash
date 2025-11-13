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
extern current_scope

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
%define AST_INDEX_EXPR      55
%define AST_FIELD_EXPR      56

; Symbol types
%define SYM_VARIABLE    0
%define SYM_FUNCTION    1
%define SYM_PARAMETER   2

; Type kinds
%define TYPE_I8         0
%define TYPE_I16        1
%define TYPE_I32        2
%define TYPE_I64        3
%define TYPE_U8         4
%define TYPE_U16        5
%define TYPE_U32        6
%define TYPE_U64        7
%define TYPE_F32        8
%define TYPE_F64        9
%define TYPE_BOOL       10
%define TYPE_CHAR       11
%define TYPE_PTR        12
%define TYPE_VOID       13
%define TYPE_ARRAY      14
%define TYPE_STRUCT     15
%define TYPE_ENUM       16
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
    msg_return_type_mismatch db "Return type mismatch", 0
    msg_wrong_arg_count db "Wrong number of arguments", 0
    msg_invalid_arg_type db "Invalid argument type", 0
    msg_return_outside_func db "Return statement outside function", 0
    msg_missing_return_value db "Missing return value", 0
    msg_condition_not_bool db "Condition must be boolean", 0
    msg_line_prefix db "Line ", 0
    msg_colon db ": ", 0

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
    push r13
    
    mov rbx, rcx
    
    ; First pass: Register all function names in symbol table
    mov r12, [rbx + 8]  ; declarations list
    
.register_funcs:
    test r12, r12
    jz .register_done
    
    mov rax, [r12]      ; Get node pointer
    mov rcx, [rax]      ; Get node type
    cmp rcx, AST_FUNCTION
    jne .next_register
    
    ; Register function
    mov rcx, rax
    call register_function
    
.next_register:
    mov r12, [r12 + 8]
    jmp .register_funcs
    
.register_done:
    ; Second pass: Analyze function bodies
    mov r12, [rbx + 8]  ; declarations list
    
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
    pop r13
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; register_function - Register function in global symbol table
; Parameters:
;   RCX = pointer to function AST node
; Returns:
;   Nothing
; ============================================================================
register_function:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    
    mov rbx, rcx        ; Function node
    
    ; Create function symbol
    mov rcx, Symbol_size
    call arena_alloc
    test rax, rax
    jz .error
    
    mov r12, rax        ; Symbol pointer
    
    ; Fill in symbol info
    mov rax, [rbx + 16]     ; function name
    mov [r12 + Symbol.name], rax
    mov rax, [rbx + 24]     ; function name length
    mov [r12 + Symbol.name_len], rax
    mov qword [r12 + Symbol.type], SYM_FUNCTION
    
    ; Store return type
    mov rax, [rbx + 48]     ; return_type node
    test rax, rax
    jz .void_return
    mov rax, [rax + 16]     ; extract type kind
    jmp .store_return_type
    
.void_return:
    mov rax, TYPE_VOID
    
.store_return_type:
    mov [r12 + Symbol.data_type], rax
    
    ; Store function node pointer in value field for later parameter validation
    mov [r12 + Symbol.value], rbx
    
    ; Insert into global symbol table (current_scope at this point is global)
    mov rcx, [current_scope]
    mov rdx, r12
    call symtable_insert
    
.error:
    pop r12
    pop rbx
    add rsp, 48
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
    sub rsp, 64
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    mov rbx, rcx        ; Function node
    mov [current_function], rbx
    
    ; Enter new scope for function
    call symtable_enter_scope
    
    ; Add function parameters to symbol table
    ; ASTFunctionNode layout (after 16-byte base):
    ; +16: name, +24: name_len, +32: params, +40: param_count, +48: return_type, +56: body
    mov r12, [rbx + 32]     ; params array
    mov r13, [rbx + 40]     ; param_count
    
    test r13, r13
    jz .no_params
    
    xor r14, r14            ; index = 0
    
.param_loop:
    cmp r14, r13
    jge .params_done
    
    ; Get parameter node (ASTParamNode)
    mov r15, [r12 + r14 * 8]
    test r15, r15
    jz .next_param
    
    ; Create symbol for parameter
    push rcx
    push rdx
    push r8
    mov rcx, Symbol_size
    call arena_alloc
    pop r8
    pop rdx
    pop rcx
    test rax, rax
    jz .next_param
    
    mov r8, rax             ; Symbol pointer
    
    ; Fill in symbol info
    mov rax, [r15]          ; param name
    mov [r8 + Symbol.name], rax
    mov rax, [r15 + 8]      ; param name_len
    mov [r8 + Symbol.name_len], rax
    mov qword [r8 + Symbol.type], SYM_PARAMETER
    
    ; Get parameter type from type node
    mov rax, [r15 + 16]     ; type node
    test rax, rax
    jz .param_no_type
    ; Extract type kind from type node (simplified - assumes primitive type)
    mov rax, [rax + 16]     ; type kind at offset 16 in type node
    
.param_no_type:
    mov [r8 + Symbol.data_type], rax
    mov qword [r8 + Symbol.is_mutable], 1  ; Parameters are mutable by default
    
    ; Insert parameter into symbol table
    push r12
    push r13
    push r14
    push r15
    mov rcx, [current_scope]
    mov rdx, r8              ; symbol (already in r8)
    call symtable_insert
    pop r15
    pop r14
    pop r13
    pop r12
    
.next_param:
    inc r14
    jmp .param_loop
    
.params_done:
.no_params:
    
    ; Get function body (block statement)
    mov r12, [rbx + 56]     ; body at offset 56
    test r12, r12
    jz .no_body
    
    mov rcx, r12
    call semantic_analyze_statement
    
.no_body:
    ; Exit function scope
    call symtable_exit_scope
    
    mov qword [current_function], 0
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 64
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
    cmp rax, AST_ASSIGN_STMT
    je .assign_stmt
    cmp rax, AST_RETURN_STMT
    je .return_stmt
    cmp rax, AST_IF_STMT
    je .if_stmt
    cmp rax, AST_WHILE_STMT
    je .while_stmt
    cmp rax, AST_FOR_STMT
    je .for_stmt
    cmp rax, AST_EXPR_STMT
    je .expr_stmt
    cmp rax, AST_BREAK_STMT
    je .break_stmt
    cmp rax, AST_CONTINUE_STMT
    je .continue_stmt
    
    ; Unknown statement type
    jmp .done
    
.block:
    mov rcx, rbx
    call semantic_analyze_block
    jmp .done
    
.let_stmt:
    mov rcx, rbx
    call semantic_analyze_let
    jmp .done
    
.assign_stmt:
    mov rcx, rbx
    call semantic_analyze_assign
    jmp .done
    
.return_stmt:
    mov rcx, rbx
    call semantic_analyze_return
    jmp .done
    
.if_stmt:
    mov rcx, rbx
    call semantic_analyze_if
    jmp .done
    
.while_stmt:
    mov rcx, rbx
    call semantic_analyze_while
    jmp .done
    
.for_stmt:
    mov rcx, rbx
    call semantic_analyze_for
    jmp .done
    
.expr_stmt:
    ; Just analyze the expression
    mov rcx, [rbx + 16]
    call semantic_analyze_expression
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
    sub rsp, 64
    push rbx
    push r12
    push r13
    push r14
    
    mov rbx, rcx
    
    ; Get variable name (at offset 16)
    mov r12, [rbx + 16]     ; name pointer
    mov r13, [rbx + 24]     ; name length
    
    ; Get mutability flag (at offset 32)
    mov r14, [rbx + 32]
    
    ; Check if initializer exists (at offset 48)
    mov rcx, [rbx + 48]
    test rcx, rcx
    jz .no_init
    
    ; Type check initializer expression
    call semantic_analyze_expression
    mov [rbp - 8], rax      ; Save init type
    
    ; Get declared type (at offset 40)
    mov rcx, [rbx + 40]
    test rcx, rcx
    jz .infer_type
    
    ; Extract type from type node (simplified - just get type kind)
    mov rcx, [rcx + 16]
    
    ; Check if init type matches declared type
    cmp rax, rcx
    jne .type_mismatch
    jmp .create_symbol
    
.infer_type:
    ; Use initializer type as variable type
    mov rcx, rax
    jmp .create_symbol
    
.no_init:
    ; Must have explicit type if no initializer
    mov rcx, [rbx + 40]
    test rcx, rcx
    jz .missing_type
    ; Extract type
    mov rcx, [rcx + 16]
    
.create_symbol:
    ; Create symbol for variable
    push rcx                ; Save type
    mov rcx, Symbol_size
    call arena_alloc
    mov r12, rax
    pop rcx                 ; Restore type
    
    ; Fill in symbol information
    mov rax, [rbx + 16]
    mov [r12 + Symbol.name], rax
    mov rax, [rbx + 24]
    mov [r12 + Symbol.name_len], rax
    mov qword [r12 + Symbol.type], SYM_VARIABLE
    mov [r12 + Symbol.data_type], rcx
    mov rax, [rbx + 32]
    mov [r12 + Symbol.is_mutable], rax
    
    ; Insert into symbol table
    mov rcx, [current_scope]
    mov rdx, r12             ; symbol
    call symtable_insert
    jmp .done
    
.type_mismatch:
    mov qword [had_error], 1
    jmp .done
    
.missing_type:
    mov qword [had_error], 1
    
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 64
    pop rbp
    ret

; ============================================================================
; semantic_analyze_assign - Analyze assignment statement
; Parameters:
;   RCX = pointer to assignment AST node
; Returns:
;   Nothing
; ============================================================================
semantic_analyze_assign:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    
    mov rbx, rcx
    
    ; Get target (left side) - should be identifier or field access
    mov rcx, [rbx + 16]
    mov r12, rcx
    
    ; Check if target is identifier
    mov rax, [rcx]
    cmp rax, AST_IDENTIFIER
    jne .not_simple_assign
    
    ; Lookup identifier to check mutability
    mov rcx, [current_scope]
    mov rdx, [r12 + 16]     ; name
    mov r8, [r12 + 24]      ; length
    call symtable_lookup
    test rax, rax
    jz .undefined
    
    mov r13, rax            ; Save symbol
    
    ; Check if variable is mutable
    mov rax, [r13 + Symbol.is_mutable]
    test rax, rax
    jz .not_mutable
    
    ; Get variable type
    mov r12, [r13 + Symbol.data_type]
    
    ; Analyze value expression (right side at offset 24)
    mov rcx, [rbx + 24]
    call semantic_analyze_expression
    
    ; Check if types match
    cmp rax, r12
    jne .type_mismatch
    jmp .done
    
.not_simple_assign:
    ; TODO: Handle field access and array index assignments
    ; For now, just analyze the value
    mov rcx, [rbx + 24]
    call semantic_analyze_expression
    jmp .done
    
.undefined:
    mov qword [had_error], 1
    jmp .done
    
.not_mutable:
    mov qword [had_error], 1
    jmp .done
    
.type_mismatch:
    mov qword [had_error], 1
    
.done:
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; semantic_analyze_if - Analyze if statement
; Parameters:
;   RCX = pointer to if statement AST node
; Returns:
;   Nothing
; ============================================================================
semantic_analyze_if:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    
    mov rbx, rcx
    
    ; Analyze condition (at offset 16)
    mov rcx, [rbx + 16]
    call semantic_analyze_expression
    mov r12, rax        ; Save condition type
    
    ; Check if condition type is valid (not error)
    cmp r12, TYPE_ERROR
    je .condition_error
    
    ; In a full implementation, check for TYPE_BOOL
    ; For now, accept any valid type (implicit boolean conversion)
    
    ; Analyze then branch (at offset 24)
    mov rcx, [rbx + 24]
    call semantic_analyze_statement
    
    ; Check if else branch exists (at offset 32)
    mov rcx, [rbx + 32]
    test rcx, rcx
    jz .done
    
    ; Analyze else branch
    call semantic_analyze_statement
    jmp .done
    
.condition_error:
    mov qword [had_error], 1
    
.done:
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; semantic_analyze_while - Analyze while loop
; Parameters:
;   RCX = pointer to while statement AST node
; Returns:
;   Nothing
; ============================================================================
semantic_analyze_while:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    
    mov rbx, rcx
    
    ; Analyze condition (at offset 16)
    mov rcx, [rbx + 16]
    call semantic_analyze_expression
    mov r12, rax        ; Save condition type
    
    ; Check if condition type is valid (not error)
    cmp r12, TYPE_ERROR
    je .condition_error
    
    ; In a full implementation, check for TYPE_BOOL
    ; For now, accept any valid type
    
    ; Set in_loop flag
    mov qword [in_loop], 1
    
    ; Analyze body (at offset 24)
    mov rcx, [rbx + 24]
    call semantic_analyze_statement
    
    ; Clear in_loop flag
    mov qword [in_loop], 0
    jmp .done
    
.condition_error:
    mov qword [had_error], 1
    mov qword [in_loop], 0
    
.done:
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; semantic_analyze_for - Analyze for loop
; Parameters:
;   RCX = pointer to for statement AST node
; Returns:
;   Nothing
; ============================================================================
semantic_analyze_for:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    push rbx
    push r12
    push r13
    push r14
    
    mov rbx, rcx
    
    ; Enter scope for loop variable
    call symtable_enter_scope
    
    ; ASTForStmtNode structure (after 16-byte base):
    ; +16: iterator name pointer
    ; +24: iterator name length
    ; +32: start expression
    ; +40: end expression
    ; +48: body statement
    
    ; Analyze start expression (at offset 32)
    mov rcx, [rbx + 32]
    test rcx, rcx
    jz .no_start
    call semantic_analyze_expression
    mov r12, rax            ; Save start type
    
.no_start:
    ; Analyze end expression (at offset 40)
    mov rcx, [rbx + 40]
    test rcx, rcx
    jz .no_end
    call semantic_analyze_expression
    mov r13, rax            ; Save end type
    
    ; Check if start and end types match
    cmp r13, r12
    jne .type_mismatch
    
.no_end:
    ; Create symbol for loop iterator variable (implicit let)
    mov rcx, Symbol_size
    call arena_alloc
    test rax, rax
    jz .no_iterator_symbol
    
    mov r14, rax            ; Save symbol pointer
    
    ; Fill in symbol info
    mov rax, [rbx + 16]     ; iterator name
    mov [r14 + Symbol.name], rax
    mov rax, [rbx + 24]     ; iterator name length
    mov [r14 + Symbol.name_len], rax
    mov qword [r14 + Symbol.type], SYM_VARIABLE
    mov [r14 + Symbol.data_type], r12   ; Use range type (from start expression)
    mov qword [r14 + Symbol.is_mutable], 0  ; Loop iterator is immutable
    
    ; Insert iterator into symbol table
    mov rcx, [current_scope]
    mov rdx, r14             ; symbol
    call symtable_insert
    
.no_iterator_symbol:
    ; Set in_loop flag
    mov qword [in_loop], 1
    
    ; Analyze body (at offset 48)
    mov rcx, [rbx + 48]
    test rcx, rcx
    jz .no_body
    call semantic_analyze_statement
    
.no_body:
    ; Clear in_loop flag
    mov qword [in_loop], 0
    
    ; Exit loop scope
    call symtable_exit_scope
    jmp .done
    
.type_mismatch:
    mov qword [had_error], 1
    mov qword [in_loop], 0
    call symtable_exit_scope
    
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 64
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
    sub rsp, 48
    push rbx
    push r12
    push r13
    
    mov rbx, rcx
    
    ; Get current function's return type
    mov r13, [current_function]
    test r13, r13
    jz .no_function_context
    
    ; Get function return type (at offset 40 in ASTFunctionNode)
    mov r13, [r13 + 40]
    test r13, r13
    jz .void_return_type
    
    ; Extract type from type node
    mov r13, [r13 + 16]
    jmp .check_expr
    
.void_return_type:
    mov r13, TYPE_VOID
    
.check_expr:
    ; Check if there's a return expression (at offset 16)
    mov rcx, [rbx + 16]
    test rcx, rcx
    jz .no_expr
    
    ; Analyze return expression
    call semantic_analyze_expression
    mov r12, rax            ; Save return type
    
    ; Check if return type matches function return type
    cmp r12, r13
    jne .type_mismatch
    jmp .done
    
.no_expr:
    ; Return with no value (void return)
    ; Check if function return type is void
    cmp r13, TYPE_VOID
    jne .missing_return_value
    jmp .done
    
.type_mismatch:
    mov qword [had_error], 1
    jmp .done
    
.missing_return_value:
    mov qword [had_error], 1
    jmp .done
    
.no_function_context:
    ; Return outside function - error
    mov qword [had_error], 1
    
.done:
    pop r13
    pop r12
    pop rbx
    add rsp, 48
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
    test rbx, rbx
    jz .error
    
    ; Get expression type
    mov rax, [rbx]
    
    cmp rax, AST_LITERAL_EXPR
    je .literal
    cmp rax, AST_IDENTIFIER
    je .identifier
    cmp rax, AST_BINARY_EXPR
    je .binary
    cmp rax, AST_UNARY_EXPR
    je .unary
    cmp rax, AST_CALL_EXPR
    je .call
    cmp rax, AST_INDEX_EXPR
    je .index
    cmp rax, AST_FIELD_EXPR
    je .field
    
    ; Unknown expression type
.error:
    mov rax, TYPE_ERROR
    mov qword [had_error], 1
    jmp .done
    
.literal:
    mov rcx, rbx
    call semantic_analyze_literal
    jmp .done
    
.identifier:
    mov rcx, rbx
    call semantic_analyze_identifier
    jmp .done
    
.binary:
    mov rcx, rbx
    call semantic_analyze_binary
    jmp .done
    
.unary:
    mov rcx, rbx
    call semantic_analyze_unary
    jmp .done
    
.call:
    mov rcx, rbx
    call semantic_analyze_call
    jmp .done
    
.index:
    mov rcx, rbx
    call semantic_analyze_index
    jmp .done
    
.field:
    mov rcx, rbx
    call semantic_analyze_field
    jmp .done
    
.done:
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; semantic_analyze_literal - Get type of literal expression
; Parameters:
;   RCX = pointer to literal AST node
; Returns:
;   RAX = type of literal
; ============================================================================
semantic_analyze_literal:
    push rbp
    mov rbp, rsp
    
    ; Literal type is stored at offset 16 (after ASTNode header)
    mov rax, [rcx + 16]
    
    pop rbp
    ret

; ============================================================================
; semantic_analyze_identifier - Lookup identifier and return type
; Parameters:
;   RCX = pointer to identifier AST node
; Returns:
;   RAX = type of identifier (or TYPE_ERROR if not found)
; ============================================================================
semantic_analyze_identifier:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    
    mov rbx, rcx
    
    ; Get identifier name and length
    ; Name is at offset 16, length at offset 24 (after ASTNode header)
    mov rcx, [current_scope]
    mov rdx, [rbx + 16]     ; name pointer
    mov r8, [rbx + 24]      ; name length
    
    ; Lookup in symbol table
    call symtable_lookup
    test rax, rax
    jz .not_found
    
    ; Get data type from symbol
    mov rax, [rax + Symbol.data_type]
    jmp .done
    
.not_found:
    ; Error: undefined symbol
    mov qword [had_error], 1
    mov rax, TYPE_ERROR
    
.done:
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; semantic_analyze_binary - Type check binary expression
; Parameters:
;   RCX = pointer to binary expression AST node
; Returns:
;   RAX = result type (or TYPE_ERROR if type mismatch)
; ============================================================================
semantic_analyze_binary:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    
    mov rbx, rcx
    
    ; Get left operand (at offset 16)
    mov rcx, [rbx + 16]
    call semantic_analyze_expression
    mov r12, rax        ; Save left type
    
    ; Get right operand (at offset 24)
    mov rcx, [rbx + 24]
    call semantic_analyze_expression
    mov r13, rax        ; Save right type
    
    ; Check for errors
    cmp r12, TYPE_ERROR
    je .error
    cmp r13, TYPE_ERROR
    je .error
    
    ; Get operator (at offset 32)
    mov rax, [rbx + 32]
    
    ; For now, simple type checking: both operands must match
    cmp r12, r13
    jne .type_mismatch
    
    ; Return the common type (works for arithmetic)
    mov rax, r12
    jmp .done
    
.type_mismatch:
    mov qword [had_error], 1
    mov rax, TYPE_ERROR
    jmp .done
    
.error:
    mov rax, TYPE_ERROR
    
.done:
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; semantic_analyze_unary - Type check unary expression
; Parameters:
;   RCX = pointer to unary expression AST node
; Returns:
;   RAX = result type
; ============================================================================
semantic_analyze_unary:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    
    mov rbx, rcx
    
    ; Get operand (at offset 16)
    mov rcx, [rbx + 16]
    call semantic_analyze_expression
    
    ; For most unary operators, type is preserved
    ; (negation, not, etc.)
    
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; semantic_analyze_call - Type check function call
; Parameters:
;   RCX = pointer to call expression AST node
; Returns:
;   RAX = return type of function (or TYPE_ERROR)
; ============================================================================
semantic_analyze_call:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    mov rbx, rcx
    
    ; Get function name from function expression (usually identifier)
    mov r15, [rbx + 16]     ; function expression node
    
    ; Extract name from identifier node
    mov rcx, [current_scope]
    mov rdx, [r15 + 16]     ; name from identifier node
    mov r8, [r15 + 24]      ; length from identifier node
    
    ; Lookup function in symbol table
    call symtable_lookup
    test rax, rax
    jz .not_found
    
    mov r12, rax        ; Save symbol
    
    ; Check if it's actually a function
    mov rax, [r12 + Symbol.type]
    cmp rax, SYM_FUNCTION
    jne .not_function
    
    ; Get arguments list (at offset 32)
    mov r13, [rbx + 32]     ; Arguments array/list
    mov r14, [rbx + 40]     ; Argument count
    
    ; Validate argument count and types
    ; For now, just analyze each argument expression
    test r13, r13
    jz .no_args
    
    ; Loop through arguments
    xor r15, r15            ; Counter
    
.arg_loop:
    cmp r15, r14
    jge .args_done
    
    ; Get argument expression
    mov rcx, [r13 + r15 * 8]
    test rcx, rcx
    jz .next_arg
    
    ; Analyze argument expression
    push r13
    push r14
    push r15
    call semantic_analyze_expression
    pop r15
    pop r14
    pop r13
    
    ; Check if argument type is valid (not TYPE_ERROR)
    cmp rax, TYPE_ERROR
    je .arg_error
    
    ; TODO: Compare with expected parameter type
    
.next_arg:
    inc r15
    jmp .arg_loop
    
.args_done:
.no_args:
    ; Return the function's return type
    mov rax, [r12 + Symbol.data_type]
    jmp .done
    
.arg_error:
    mov qword [had_error], 1
    mov rax, TYPE_ERROR
    jmp .done
    
.not_found:
    mov qword [had_error], 1
    mov rax, TYPE_ERROR
    jmp .done
    
.not_function:
    mov qword [had_error], 1
    mov rax, TYPE_ERROR
    
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 64
    pop rbp
    ret

; ============================================================================
; semantic_analyze_index - Type check array index expression
; Parameters:
;   RCX = pointer to index expression AST node
; Returns:
;   RAX = element type (or TYPE_ERROR)
; ============================================================================
semantic_analyze_index:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    
    mov rbx, rcx
    
    ; Analyze array expression (at offset 16)
    mov rcx, [rbx + 16]
    call semantic_analyze_expression
    mov r12, rax        ; Save array type
    
    ; Check if it's an array type (TYPE_ARRAY or pointer)
    cmp r12, TYPE_ARRAY
    je .valid_array
    cmp r12, TYPE_PTR
    je .valid_array
    
    ; Not an indexable type
    mov qword [had_error], 1
    mov rax, TYPE_ERROR
    jmp .done
    
.valid_array:
    ; Analyze index expression (at offset 24)
    mov rcx, [rbx + 24]
    call semantic_analyze_expression
    mov r13, rax        ; Save index type
    
    ; Check if index is integer type
    cmp r13, TYPE_I32
    je .valid_index
    cmp r13, TYPE_I64
    je .valid_index
    cmp r13, TYPE_U32
    je .valid_index
    cmp r13, TYPE_U64
    je .valid_index
    
    ; Invalid index type
    mov qword [had_error], 1
    mov rax, TYPE_ERROR
    jmp .done
    
.valid_index:
    ; For arrays, return element type
    ; For now, just return i32 (simplified)
    mov rax, TYPE_I32
    
.done:
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; semantic_analyze_field - Type check field access expression
; Parameters:
;   RCX = pointer to field expression AST node
; Returns:
;   RAX = field type (or TYPE_ERROR)
; ============================================================================
semantic_analyze_field:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    
    mov rbx, rcx
    
    ; Analyze object expression (at offset 16)
    mov rcx, [rbx + 16]
    call semantic_analyze_expression
    mov r12, rax        ; Save object type
    
    ; Check if it's a struct type
    cmp r12, TYPE_STRUCT
    je .valid_struct
    
    ; Not a struct type
    mov qword [had_error], 1
    mov rax, TYPE_ERROR
    jmp .done
    
.valid_struct:
    ; Field name is at offset 24
    ; In a full implementation, lookup field in struct definition
    ; For now, return i32 (simplified)
    mov rax, TYPE_I32
    
.done:
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret
