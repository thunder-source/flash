; ============================================================================
; Flash Compiler - Parser (Syntax Analyzer)
; ============================================================================
; Recursive descent parser for the Flash programming language
; Builds an Abstract Syntax Tree (AST) from tokens
; ============================================================================

bits 64
default rel

extern lexer_next_token
extern arena_alloc

; Include token definitions from lexer
%define TOKEN_EOF           0
%define TOKEN_IDENTIFIER    1
%define TOKEN_NUMBER        2
%define TOKEN_STRING        3
%define TOKEN_CHAR          4
%define TOKEN_FN            5
%define TOKEN_LET           6
%define TOKEN_MUT           7
%define TOKEN_IF            8
%define TOKEN_ELSE          9
%define TOKEN_WHILE         10
%define TOKEN_FOR           11
%define TOKEN_IN            12
%define TOKEN_BREAK         13
%define TOKEN_CONTINUE      14
%define TOKEN_RETURN        15
%define TOKEN_STRUCT        16
%define TOKEN_ENUM          17
%define TOKEN_TRUE          18
%define TOKEN_FALSE         19
%define TOKEN_INLINE        20
%define TOKEN_ASM           21
%define TOKEN_SIZEOF        22
%define TOKEN_ALLOC         23
%define TOKEN_FREE          24
%define TOKEN_IMPORT        25
%define TOKEN_EXPORT        26
%define TOKEN_CCONST        27
%define TOKEN_FROM          28
%define TOKEN_I8            40
%define TOKEN_I16           41
%define TOKEN_I32           42
%define TOKEN_I64           43
%define TOKEN_U8            44
%define TOKEN_U16           45
%define TOKEN_U32           46
%define TOKEN_U64           47
%define TOKEN_F32           48
%define TOKEN_F64           49
%define TOKEN_BOOL          50
%define TOKEN_CHAR_TYPE     51
%define TOKEN_PTR           52
%define TOKEN_PLUS          60
%define TOKEN_MINUS         61
%define TOKEN_STAR          62
%define TOKEN_SLASH         63
%define TOKEN_PERCENT       64
%define TOKEN_ASSIGN        65
%define TOKEN_EQ            66
%define TOKEN_NEQ           67
%define TOKEN_LT            68
%define TOKEN_GT            69
%define TOKEN_LTE           70
%define TOKEN_GTE           71
%define TOKEN_AND           72
%define TOKEN_OR            73
%define TOKEN_NOT           74
%define TOKEN_BIT_AND       75
%define TOKEN_BIT_OR        76
%define TOKEN_BIT_XOR       77
%define TOKEN_BIT_NOT       78
%define TOKEN_LSHIFT        79
%define TOKEN_RSHIFT        80
%define TOKEN_LPAREN        91
%define TOKEN_RPAREN        92
%define TOKEN_LBRACE        93
%define TOKEN_RBRACE        94
%define TOKEN_LBRACKET      95
%define TOKEN_RBRACKET      96
%define TOKEN_SEMICOLON     97
%define TOKEN_COLON         98
%define TOKEN_COMMA         99
%define TOKEN_DOT           100
%define TOKEN_ARROW         101
%define TOKEN_RANGE         102

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
%define AST_TYPE_PRIMITIVE  100
%define AST_TYPE_POINTER    101
%define AST_TYPE_ARRAY      102
%define AST_IMPORT          5
%define AST_CONST_DEF       4

; Token structure
struc Token
    .type:      resq 1
    .start:     resq 1
    .length:    resq 1
    .line:      resq 1
endstruc

; ============================================================================
; Parser Structure
; ============================================================================
struc Parser
    .lexer:         resq 1      ; Pointer to lexer
    .current:       resb Token_size  ; Current token
    .previous:      resb Token_size  ; Previous token
    .had_error:     resq 1      ; Error flag
    .panic_mode:    resq 1      ; Panic mode flag
endstruc

; ============================================================================
; BSS Section
; ============================================================================
section .bss
    current_parser: resb Parser_size

; ============================================================================
; Data Section
; ============================================================================
section .data
    error_msg db "Parse error at line ", 0
    alloc_error_msg db "Memory allocation failed", 10, 0

; ============================================================================
; Code Section
; ============================================================================
section .text

global parser_init
global parser_parse
global parse_program
global parse_function
global parse_statement
global parse_expression
global parse_type

; ============================================================================
; parser_init - Initialize parser with lexer
; Parameters:
;   RCX = pointer to lexer
; Returns:
;   RAX = pointer to parser structure
; ============================================================================
parser_init:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    lea rax, [current_parser]
    mov [rax + Parser.lexer], rcx
    mov qword [rax + Parser.had_error], 0
    mov qword [rax + Parser.panic_mode], 0
    
    ; Get first token
    push rax
    mov rcx, [rax + Parser.lexer]
    mov rdx, rax
    add rdx, Parser.current
    call lexer_next_token
    pop rax
    
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; parser_advance - Move to next token
; Parameters:
;   RCX = pointer to parser
; ============================================================================
parser_advance:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    
    mov r12, rcx
    
    ; Copy current to previous
    mov rax, [r12 + Parser.current + Token.type]
    mov [r12 + Parser.previous + Token.type], rax
    mov rax, [r12 + Parser.current + Token.start]
    mov [r12 + Parser.previous + Token.start], rax
    mov rax, [r12 + Parser.current + Token.length]
    mov [r12 + Parser.previous + Token.length], rax
    mov rax, [r12 + Parser.current + Token.line]
    mov [r12 + Parser.previous + Token.line], rax
    
    ; Get next token
    mov rcx, [r12 + Parser.lexer]
    lea rdx, [r12 + Parser.current]
    call lexer_next_token
    
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; parser_check - Check if current token matches type
; Parameters:
;   RCX = pointer to parser
;   RDX = token type to check
; Returns:
;   AL = 1 if match, 0 otherwise
; ============================================================================
parser_check:
    mov rax, [rcx + Parser.current + Token.type]
    cmp rax, rdx
    je .match
    xor al, al
    ret
.match:
    mov al, 1
    ret

; ============================================================================
; parser_match - Check and consume token if it matches
; Parameters:
;   RCX = pointer to parser
;   RDX = token type to match
; Returns:
;   AL = 1 if matched and consumed, 0 otherwise
; ============================================================================
parser_match:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12
    push r13
    
    mov r12, rcx
    mov r13, rdx
    
    call parser_check
    test al, al
    jz .no_match
    
    mov rcx, r12
    call parser_advance
    mov al, 1
    
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret
    
.no_match:
    xor al, al
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; parser_consume - Consume token or report error
; Parameters:
;   RCX = pointer to parser
;   RDX = expected token type
; Returns:
;   AL = 1 if successful, 0 if error
; ============================================================================
parser_consume:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12
    push r13
    
    mov r12, rcx
    mov r13, rdx
    
    mov rax, [r12 + Parser.current + Token.type]
    cmp rax, r13
    jne .error
    
    mov rcx, r12
    call parser_advance
    mov al, 1
    
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret
    
.error:
    mov qword [r12 + Parser.had_error], 1
    xor al, al
    pop r13
    pop r12
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; alloc_node - Allocate memory for an AST node
; Parameters:
;   RCX = size in bytes
; Returns:
;   RAX = pointer to allocated memory (or 0 on failure)
; ============================================================================
alloc_node:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    call arena_alloc
    
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; parse_program - Parse entire program
; Parameters:
;   RCX = pointer to parser
; Returns:
;   RAX = pointer to program AST node
; ============================================================================
parse_program:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    push r14
    
    mov r12, rcx  ; Save parser pointer
    
    ; Allocate program node
    mov rcx, 64  ; Size for program node with arrays
    call alloc_node
    test rax, rax
    jz .error
    
    mov r13, rax  ; Save program node
    mov qword [r13], AST_PROGRAM  ; Set node type
    mov qword [r13 + 16], 0  ; declarations array
    mov qword [r13 + 24], 0  ; decl_count
    mov qword [r13 + 32], 0  ; decl_capacity
    
    ; Parse declarations until EOF
.parse_loop:
    mov rcx, r12
    mov rax, [rcx + Parser.current + Token.type]
    cmp rax, TOKEN_EOF
    je .done
    
    ; Check what kind of declaration
    cmp rax, TOKEN_FN
    je .parse_fn
    cmp rax, TOKEN_INLINE
    je .parse_fn
    cmp rax, TOKEN_EXPORT
    je .parse_export
    cmp rax, TOKEN_IMPORT
    je .parse_import
    cmp rax, TOKEN_STRUCT
    je .parse_struct
    cmp rax, TOKEN_CCONST
    je .parse_const
    
    ; Unknown token - error
    mov qword [r12 + Parser.had_error], 1
    jmp .done
    
.parse_fn:
    mov rcx, r12
    call parse_function
    test rax, rax
    jz .error
    
    ; Add to declarations array (simplified - just store pointer for now)
    mov qword [r13 + 24], 1  ; decl_count = 1 (simplified)
    jmp .parse_loop
    
.parse_export:
    ; Skip export token and parse what follows
    mov rcx, r12
    call parser_advance
    jmp .parse_loop
    
.parse_import:
    mov rcx, r12
    call parse_import
    test rax, rax
    jz .error
    jmp .parse_loop
    
.parse_struct:
    mov rcx, r12
    call parse_struct
    test rax, rax
    jz .error
    jmp .parse_loop
    
.parse_const:
    mov rcx, r12
    call parse_const_def
    test rax, rax
    jz .error
    jmp .parse_loop
    
.done:
    mov rax, r13
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret
    
.error:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; parse_function - Parse function definition
; Parameters:
;   RCX = pointer to parser
; Returns:
;   RAX = pointer to function AST node
; ============================================================================
parse_function:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    push r14
    
    mov r12, rcx  ; Save parser
    xor r14, r14  ; is_inline flag
    
    ; Check for inline keyword
    mov rdx, TOKEN_INLINE
    call parser_match
    test al, al
    jz .check_fn
    mov r14, 1
    
.check_fn:
    ; Expect 'fn' keyword
    mov rcx, r12
    mov rdx, TOKEN_FN
    call parser_consume
    test al, al
    jz .error
    
    ; Expect identifier (function name)
    mov rcx, r12
    mov rdx, TOKEN_IDENTIFIER
    call parser_consume
    test al, al
    jz .error
    
    ; Save function name from previous token
    mov r13, [r12 + Parser.previous + Token.start]
    mov rbx, [r12 + Parser.previous + Token.length]
    
    ; Allocate function node
    mov rcx, 96  ; Size for function node
    call alloc_node
    test rax, rax
    jz .error
    
    mov r14, rax  ; Save function node
    mov qword [r14], AST_FUNCTION
    mov [r14 + 16], r13  ; name
    mov [r14 + 24], rbx  ; name_len
    mov qword [r14 + 32], 0  ; params (simplified)
    mov qword [r14 + 40], 0  ; param_count
    mov qword [r14 + 48], 0  ; return_type
    mov qword [r14 + 56], 0  ; body
    
    ; Expect '('
    mov rcx, r12
    mov rdx, TOKEN_LPAREN
    call parser_consume
    test al, al
    jz .error
    
    ; Parse parameters (simplified - skip for now)
    ; TODO: Implement parameter parsing
    
    ; Expect ')'
    mov rcx, r12
    mov rdx, TOKEN_RPAREN
    call parser_consume
    test al, al
    jz .error
    
    ; Check for return type
    mov rcx, r12
    mov rdx, TOKEN_ARROW
    call parser_match
    test al, al
    jz .parse_body
    
    ; Parse return type
    mov rcx, r12
    call parse_type
    mov [r14 + 48], rax
    
.parse_body:
    ; Parse function body (block statement)
    mov rcx, r12
    call parse_block
    test rax, rax
    jz .error
    
    mov [r14 + 56], rax  ; Store body
    mov rax, r14
    
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret
    
.error:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; parse_block - Parse block statement
; Parameters:
;   RCX = pointer to parser
; Returns:
;   RAX = pointer to block AST node
; ============================================================================
parse_block:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    
    mov r12, rcx
    
    ; Expect '{'
    mov rdx, TOKEN_LBRACE
    call parser_consume
    test al, al
    jz .error
    
    ; Allocate block node
    mov rcx, 48
    call alloc_node
    test rax, rax
    jz .error
    
    mov r13, rax
    mov qword [r13], AST_BLOCK
    mov qword [r13 + 16], 0  ; statements
    mov qword [r13 + 24], 0  ; stmt_count
    
    ; Parse statements until '}'
.stmt_loop:
    mov rcx, r12
    mov rax, [rcx + Parser.current + Token.type]
    cmp rax, TOKEN_RBRACE
    je .end_block
    cmp rax, TOKEN_EOF
    je .error
    
    mov rcx, r12
    call parse_statement
    test rax, rax
    jz .error
    
    ; TODO: Add statement to array
    inc qword [r13 + 24]
    
    jmp .stmt_loop
    
.end_block:
    ; Consume '}'
    mov rcx, r12
    mov rdx, TOKEN_RBRACE
    call parser_consume
    
    mov rax, r13
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret
    
.error:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; parse_statement - Parse a statement
; Parameters:
;   RCX = pointer to parser
; Returns:
;   RAX = pointer to statement AST node
; ============================================================================
parse_statement:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push r12
    
    mov r12, rcx
    
    ; Check statement type
    mov rax, [r12 + Parser.current + Token.type]
    
    cmp rax, TOKEN_LET
    je .parse_let
    cmp rax, TOKEN_IF
    je .parse_if
    cmp rax, TOKEN_WHILE
    je .parse_while
    cmp rax, TOKEN_FOR
    je .parse_for
    cmp rax, TOKEN_RETURN
    je .parse_return
    cmp rax, TOKEN_BREAK
    je .parse_break
    cmp rax, TOKEN_CONTINUE
    je .parse_continue
    cmp rax, TOKEN_LBRACE
    je .parse_block_stmt
    
    ; Default: expression statement
    jmp .parse_expr_stmt
    
.parse_let:
    mov rcx, r12
    call parse_let_statement
    jmp .done
    
.parse_if:
    mov rcx, r12
    call parse_if_statement
    jmp .done
    
.parse_while:
    mov rcx, r12
    call parse_while_statement
    jmp .done
    
.parse_for:
    mov rcx, r12
    call parse_for_statement
    jmp .done
    
.parse_return:
    mov rcx, r12
    call parse_return_statement
    jmp .done
    
.parse_break:
    mov rcx, r12
    call parser_advance
    mov rdx, TOKEN_SEMICOLON
    call parser_consume
    
    mov rcx, 16
    call alloc_node
    mov qword [rax], AST_BREAK_STMT
    jmp .done
    
.parse_continue:
    mov rcx, r12
    call parser_advance
    mov rdx, TOKEN_SEMICOLON
    call parser_consume
    
    mov rcx, 16
    call alloc_node
    mov qword [rax], AST_CONTINUE_STMT
    jmp .done
    
.parse_block_stmt:
    mov rcx, r12
    call parse_block
    jmp .done
    
.parse_expr_stmt:
    mov rcx, r12
    call parse_expression
    test rax, rax
    jz .error
    
    push rax
    mov rcx, r12
    mov rdx, TOKEN_SEMICOLON
    call parser_consume
    pop rax
    
.done:
    pop r12
    add rsp, 32
    pop rbp
    ret
    
.error:
    xor rax, rax
    pop r12
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; parse_let_statement - Parse let statement
; Parameters:
;   RCX = pointer to parser
; Returns:
;   RAX = pointer to let statement AST node
; ============================================================================
parse_let_statement:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    push r14
    
    mov r12, rcx
    
    ; Consume 'let'
    call parser_advance
    
    ; Check for 'mut'
    xor r14, r14
    mov rcx, r12
    mov rdx, TOKEN_MUT
    call parser_match
    test al, al
    jz .get_name
    mov r14, 1
    
.get_name:
    ; Expect identifier
    mov rcx, r12
    mov rdx, TOKEN_IDENTIFIER
    call parser_consume
    test al, al
    jz .error
    
    ; Save variable name
    mov r13, [r12 + Parser.previous + Token.start]
    mov rbx, [r12 + Parser.previous + Token.length]
    
    ; Expect ':'
    mov rcx, r12
    mov rdx, TOKEN_COLON
    call parser_consume
    test al, al
    jz .error
    
    ; Parse type
    mov rcx, r12
    call parse_type
    test rax, rax
    jz .error
    push rax  ; Save type node
    
    ; Expect '='
    mov rcx, r12
    mov rdx, TOKEN_ASSIGN
    call parser_consume
    test al, al
    jz .error
    
    ; Parse initializer expression
    mov rcx, r12
    call parse_expression
    test rax, rax
    jz .error
    push rax  ; Save initializer
    
    ; Expect ';'
    mov rcx, r12
    mov rdx, TOKEN_SEMICOLON
    call parser_consume
    
    ; Allocate let statement node
    mov rcx, 64
    call alloc_node
    test rax, rax
    jz .error
    
    pop r8   ; initializer
    pop r9   ; type
    
    mov qword [rax], AST_LET_STMT
    mov [rax + 16], r13  ; name
    mov [rax + 24], rbx  ; name_len
    mov [rax + 32], r9   ; type
    mov [rax + 40], r8   ; initializer
    mov [rax + 48], r14  ; is_mutable
    
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret
    
.error:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; parse_if_statement - Parse if statement
; Parameters:
;   RCX = pointer to parser
; Returns:
;   RAX = pointer to if statement AST node
; ============================================================================
parse_if_statement:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    
    mov r12, rcx
    
    ; Consume 'if'
    call parser_advance
    
    ; Parse condition
    mov rcx, r12
    call parse_expression
    test rax, rax
    jz .error
    push rax
    
    ; Parse then block
    mov rcx, r12
    call parse_block
    test rax, rax
    jz .error
    push rax
    
    ; Check for else
    mov rcx, r12
    mov rdx, TOKEN_ELSE
    call parser_match
    test al, al
    jz .no_else
    
    ; Parse else block or else-if
    mov rcx, r12
    mov rax, [rcx + Parser.current + Token.type]
    cmp rax, TOKEN_IF
    je .else_if
    
    call parse_block
    jmp .create_node
    
.else_if:
    call parse_if_statement
    jmp .create_node
    
.no_else:
    xor rax, rax
    
.create_node:
    push rax  ; else block
    
    mov rcx, 48
    call alloc_node
    test rax, rax
    jz .error
    
    pop r8   ; else block
    pop r9   ; then block
    pop r10  ; condition
    
    mov qword [rax], AST_IF_STMT
    mov [rax + 16], r10  ; condition
    mov [rax + 24], r9   ; then_block
    mov [rax + 32], r8   ; else_block
    
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret
    
.error:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; parse_while_statement - Parse while statement
; Parameters:
;   RCX = pointer to parser
; Returns:
;   RAX = pointer to while statement AST node
; ============================================================================
parse_while_statement:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push r12
    
    mov r12, rcx
    
    ; Consume 'while'
    call parser_advance
    
    ; Parse condition
    mov rcx, r12
    call parse_expression
    test rax, rax
    jz .error
    push rax
    
    ; Parse body
    mov rcx, r12
    call parse_block
    test rax, rax
    jz .error
    push rax
    
    ; Create while node
    mov rcx, 32
    call alloc_node
    test rax, rax
    jz .error
    
    pop r9   ; body
    pop r8   ; condition
    
    mov qword [rax], AST_WHILE_STMT
    mov [rax + 16], r8
    mov [rax + 24], r9
    
    pop r12
    add rsp, 48
    pop rbp
    ret
    
.error:
    xor rax, rax
    pop r12
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; parse_for_statement - Parse for statement
; Parameters:
;   RCX = pointer to parser
; Returns:
;   RAX = pointer to for statement AST node
; ============================================================================
parse_for_statement:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    
    mov r12, rcx
    
    ; Consume 'for'
    call parser_advance
    
    ; Expect identifier (iterator variable)
    mov rcx, r12
    mov rdx, TOKEN_IDENTIFIER
    call parser_consume
    test al, al
    jz .error
    
    mov r13, [r12 + Parser.previous + Token.start]
    mov rbx, [r12 + Parser.previous + Token.length]
    
    ; Expect 'in'
    mov rcx, r12
    mov rdx, TOKEN_IN
    call parser_consume
    test al, al
    jz .error
    
    ; Parse start expression
    mov rcx, r12
    call parse_expression
    test rax, rax
    jz .error
    push rax
    
    ; Expect '..'
    mov rcx, r12
    mov rdx, TOKEN_RANGE
    call parser_consume
    test al, al
    jz .error
    
    ; Parse end expression
    mov rcx, r12
    call parse_expression
    test rax, rax
    jz .error
    push rax
    
    ; Parse body
    mov rcx, r12
    call parse_block
    test rax, rax
    jz .error
    push rax
    
    ; Create for node
    mov rcx, 64
    call alloc_node
    test rax, rax
    jz .error
    
    pop r10  ; body
    pop r9   ; end
    pop r8   ; start
    
    mov qword [rax], AST_FOR_STMT
    mov [rax + 16], r13  ; iterator name
    mov [rax + 24], rbx  ; iterator length
    mov [rax + 32], r8   ; start
    mov [rax + 40], r9   ; end
    mov [rax + 48], r10  ; body
    
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret
    
.error:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; parse_return_statement - Parse return statement
; Parameters:
;   RCX = pointer to parser
; Returns:
;   RAX = pointer to return statement AST node
; ============================================================================
parse_return_statement:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push r12
    
    mov r12, rcx
    
    ; Consume 'return'
    call parser_advance
    
    ; Check for semicolon (return with no value)
    mov rcx, r12
    mov rdx, TOKEN_SEMICOLON
    call parser_check
    test al, al
    jnz .no_value
    
    ; Parse return value
    mov rcx, r12
    call parse_expression
    test rax, rax
    jz .error
    push rax
    
    ; Expect semicolon
    mov rcx, r12
    mov rdx, TOKEN_SEMICOLON
    call parser_consume
    
    ; Create return node
    mov rcx, 24
    call alloc_node
    test rax, rax
    jz .error
    
    pop r8
    mov qword [rax], AST_RETURN_STMT
    mov [rax + 16], r8
    
    pop r12
    add rsp, 48
    pop rbp
    ret
    
.no_value:
    ; Consume semicolon
    mov rcx, r12
    call parser_advance
    
    mov rcx, 24
    call alloc_node
    test rax, rax
    jz .error
    
    mov qword [rax], AST_RETURN_STMT
    mov qword [rax + 16], 0
    
    pop r12
    add rsp, 48
    pop rbp
    ret
    
.error:
    xor rax, rax
    pop r12
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; parse_expression - Parse expression (simplified - just primary for now)
; Parameters:
;   RCX = pointer to parser
; Returns:
;   RAX = pointer to expression AST node
; ============================================================================
parse_expression:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; For now, just parse primary (literals, identifiers)
    call parse_primary
    
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; parse_primary - Parse primary expression
; Parameters:
;   RCX = pointer to parser
; Returns:
;   RAX = pointer to expression AST node
; ============================================================================
parse_primary:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push rbx
    push r12
    push r13
    
    mov r12, rcx
    
    mov rax, [r12 + Parser.current + Token.type]
    
    ; Check for number literal
    cmp rax, TOKEN_NUMBER
    je .number
    
    ; Check for identifier
    cmp rax, TOKEN_IDENTIFIER
    je .identifier
    
    ; Check for string
    cmp rax, TOKEN_STRING
    je .string
    
    ; Check for true/false
    cmp rax, TOKEN_TRUE
    je .bool_lit
    cmp rax, TOKEN_FALSE
    je .bool_lit
    
    ; Error - unexpected token
    jmp .error
    
.number:
    mov rcx, r12
    call parser_advance
    
    mov r13, [r12 + Parser.previous + Token.start]
    mov rbx, [r12 + Parser.previous + Token.length]
    
    mov rcx, 48
    call alloc_node
    test rax, rax
    jz .error
    
    mov qword [rax], AST_LITERAL_EXPR
    mov [rax + 16], r13
    mov [rax + 24], rbx
    mov qword [rax + 32], TOKEN_NUMBER
    jmp .done
    
.identifier:
    mov rcx, r12
    call parser_advance
    
    mov r13, [r12 + Parser.previous + Token.start]
    mov rbx, [r12 + Parser.previous + Token.length]
    
    mov rcx, 32
    call alloc_node
    test rax, rax
    jz .error
    
    mov qword [rax], AST_IDENTIFIER
    mov [rax + 16], r13
    mov [rax + 24], rbx
    jmp .done
    
.string:
    mov rcx, r12
    call parser_advance
    
    mov r13, [r12 + Parser.previous + Token.start]
    mov rbx, [r12 + Parser.previous + Token.length]
    
    mov rcx, 48
    call alloc_node
    test rax, rax
    jz .error
    
    mov qword [rax], AST_LITERAL_EXPR
    mov [rax + 16], r13
    mov [rax + 24], rbx
    mov qword [rax + 32], TOKEN_STRING
    jmp .done
    
.bool_lit:
    mov rcx, r12
    call parser_advance
    
    mov r13, [r12 + Parser.previous + Token.start]
    mov rbx, [r12 + Parser.previous + Token.length]
    
    mov rcx, 48
    call alloc_node
    test rax, rax
    jz .error
    
    mov qword [rax], AST_LITERAL_EXPR
    mov [rax + 16], r13
    mov [rax + 24], rbx
    mov qword [rax + 32], TOKEN_TRUE
    jmp .done
    
.done:
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret
    
.error:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; parse_type - Parse type annotation
; Parameters:
;   RCX = pointer to parser
; Returns:
;   RAX = pointer to type AST node
; ============================================================================
parse_type:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    push r12
    
    mov r12, rcx
    
    ; Check for pointer type
    mov rax, [r12 + Parser.current + Token.type]
    cmp rax, TOKEN_STAR
    je .pointer_type
    
    ; Check for primitive types
    cmp rax, TOKEN_I8
    jge .check_primitive_range
    jmp .named_type
    
.check_primitive_range:
    cmp rax, TOKEN_PTR
    jle .primitive_type
    jmp .named_type
    
.primitive_type:
    mov r8, rax
    mov rcx, r12
    call parser_advance
    
    mov rcx, 32
    call alloc_node
    test rax, rax
    jz .error
    
    mov qword [rax], AST_TYPE_PRIMITIVE
    mov [rax + 16], r8
    jmp .done
    
.pointer_type:
    mov rcx, r12
    call parser_advance
    
    ; Parse base type
    mov rcx, r12
    call parse_type
    test rax, rax
    jz .error
    push rax
    
    mov rcx, 32
    call alloc_node
    test rax, rax
    jz .error
    
    pop r8
    mov qword [rax], AST_TYPE_POINTER
    mov [rax + 16], r8
    jmp .done
    
.named_type:
    ; Expect identifier
    mov rcx, r12
    mov rdx, TOKEN_IDENTIFIER
    call parser_consume
    test al, al
    jz .error
    
    mov r13, [r12 + Parser.previous + Token.start]
    mov rbx, [r12 + Parser.previous + Token.length]
    
    mov rcx, 32
    call alloc_node
    test rax, rax
    jz .error
    
    mov qword [rax], AST_IDENTIFIER
    mov [rax + 16], r13
    mov [rax + 24], rbx
    
.done:
    pop r12
    add rsp, 48
    pop rbp
    ret
    
.error:
    xor rax, rax
    pop r12
    add rsp, 48
    pop rbp
    ret

; ============================================================================
; Stub functions for unimplemented features
; ============================================================================
parse_import:
    xor rax, rax
    ret

parse_struct:
    xor rax, rax
    ret

parse_const_def:
    xor rax, rax
    ret

; ============================================================================
; parser_parse - Main entry point for parsing
; Parameters:
;   RCX = pointer to parser
; Returns:
;   RAX = pointer to program AST node
; ============================================================================
parser_parse:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    call parse_program
    
    add rsp, 32
    pop rbp
    ret
