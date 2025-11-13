; ============================================================================
; Flash Compiler - Lexer (Tokenizer)
; ============================================================================
; Fast assembly-based lexer for the Flash programming language
; Target: x86-64 Windows
; Assembler: NASM
; ============================================================================

bits 64
default rel

; ============================================================================
; Token Type Constants
; ============================================================================
%define TOKEN_EOF           0
%define TOKEN_IDENTIFIER    1
%define TOKEN_NUMBER        2
%define TOKEN_STRING        3
%define TOKEN_CHAR          4

; Keywords (5-40)
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

; Type keywords (40-50)
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

; Operators and Punctuation (60-120)
%define TOKEN_PLUS          60   ; +
%define TOKEN_MINUS         61   ; -
%define TOKEN_STAR          62   ; *
%define TOKEN_SLASH         63   ; /
%define TOKEN_PERCENT       64   ; %
%define TOKEN_ASSIGN        65   ; =
%define TOKEN_EQ            66   ; ==
%define TOKEN_NEQ           67   ; !=
%define TOKEN_LT            68   ; <
%define TOKEN_GT            69   ; >
%define TOKEN_LTE           70   ; <=
%define TOKEN_GTE           71   ; >=
%define TOKEN_AND           72   ; &&
%define TOKEN_OR            73   ; ||
%define TOKEN_NOT           74   ; !
%define TOKEN_BIT_AND       75   ; &
%define TOKEN_BIT_OR        76   ; |
%define TOKEN_BIT_XOR       77   ; ^
%define TOKEN_BIT_NOT       78   ; ~
%define TOKEN_LSHIFT        79   ; <<
%define TOKEN_RSHIFT        80   ; >>
%define TOKEN_PLUS_ASSIGN   81   ; +=
%define TOKEN_MINUS_ASSIGN  82   ; -=
%define TOKEN_STAR_ASSIGN   83   ; *=
%define TOKEN_SLASH_ASSIGN  84   ; /=
%define TOKEN_PERCENT_ASSIGN 85  ; %=
%define TOKEN_AND_ASSIGN    86   ; &=
%define TOKEN_OR_ASSIGN     87   ; |=
%define TOKEN_XOR_ASSIGN    88   ; ^=
%define TOKEN_LSHIFT_ASSIGN 89   ; <<=
%define TOKEN_RSHIFT_ASSIGN 90   ; >>=
%define TOKEN_LPAREN        91   ; (
%define TOKEN_RPAREN        92   ; )
%define TOKEN_LBRACE        93   ; {
%define TOKEN_RBRACE        94   ; }
%define TOKEN_LBRACKET      95   ; [
%define TOKEN_RBRACKET      96   ; ]
%define TOKEN_SEMICOLON     97   ; ;
%define TOKEN_COLON         98   ; :
%define TOKEN_COMMA         99   ; ,
%define TOKEN_DOT           100  ; .
%define TOKEN_ARROW         101  ; ->
%define TOKEN_RANGE         102  ; ..

%define TOKEN_ERROR         255  ; Error token

; ============================================================================
; Token Structure (32 bytes)
; ============================================================================
struc Token
    .type:      resq 1      ; Token type (8 bytes)
    .start:     resq 1      ; Pointer to start of token in source
    .length:    resq 1      ; Length of token
    .line:      resq 1      ; Line number
endstruc

; ============================================================================
; Lexer Structure
; ============================================================================
struc Lexer
    .source:    resq 1      ; Pointer to source code
    .current:   resq 1      ; Current position in source
    .line:      resq 1      ; Current line number
    .start:     resq 1      ; Start of current token
endstruc

; ============================================================================
; Data Section
; ============================================================================
section .data

; Keyword lookup table (keyword, length, token_type)
keywords:
    db "fn", 0
    dq 2, TOKEN_FN
    
    db "let", 0
    dq 3, TOKEN_LET
    
    db "mut", 0
    dq 3, TOKEN_MUT
    
    db "if", 0
    dq 2, TOKEN_IF
    
    db "else", 0
    dq 4, TOKEN_ELSE
    
    db "while", 0
    dq 5, TOKEN_WHILE
    
    db "for", 0
    dq 3, TOKEN_FOR
    
    db "in", 0
    dq 2, TOKEN_IN
    
    db "break", 0
    dq 5, TOKEN_BREAK
    
    db "continue", 0
    dq 8, TOKEN_CONTINUE
    
    db "return", 0
    dq 6, TOKEN_RETURN
    
    db "struct", 0
    dq 6, TOKEN_STRUCT
    
    db "enum", 0
    dq 4, TOKEN_ENUM
    
    db "true", 0
    dq 5, TOKEN_TRUE
    
    db "false", 0
    dq 5, TOKEN_FALSE
    
    db "inline", 0
    dq 6, TOKEN_INLINE
    
    db "asm", 0
    dq 3, TOKEN_ASM
    
    db "sizeof", 0
    dq 6, TOKEN_SIZEOF
    
    db "alloc", 0
    dq 5, TOKEN_ALLOC
    
    db "free", 0
    dq 4, TOKEN_FREE
    
    db "import", 0
    dq 6, TOKEN_IMPORT
    
    db "export", 0
    dq 6, TOKEN_EXPORT
    
    db "cconst", 0
    dq 6, TOKEN_CCONST
    
    db "from", 0
    dq 4, TOKEN_FROM
    
    ; Type keywords
    db "i8", 0
    dq 2, TOKEN_I8
    
    db "i16", 0
    dq 3, TOKEN_I16
    
    db "i32", 0
    dq 3, TOKEN_I32
    
    db "i64", 0
    dq 3, TOKEN_I64
    
    db "u8", 0
    dq 2, TOKEN_U8
    
    db "u16", 0
    dq 3, TOKEN_U16
    
    db "u32", 0
    dq 3, TOKEN_U32
    
    db "u64", 0
    dq 3, TOKEN_U64
    
    db "f32", 0
    dq 3, TOKEN_F32
    
    db "f64", 0
    dq 3, TOKEN_F64
    
    db "bool", 0
    dq 4, TOKEN_BOOL
    
    db "char", 0
    dq 4, TOKEN_CHAR_TYPE
    
    db "ptr", 0
    dq 3, TOKEN_PTR
    
    dq 0  ; End marker

; ============================================================================
; BSS Section (Uninitialized Data)
; ============================================================================
section .bss
    current_lexer: resb Lexer_size

; ============================================================================
; Code Section
; ============================================================================
section .text

global lexer_init
global lexer_next_token
global lexer_peek_char
global lexer_advance
global is_digit
global is_alpha
global is_alnum

; ============================================================================
; lexer_init - Initialize lexer with source code
; Parameters:
;   RCX = pointer to source code string
; Returns:
;   RAX = pointer to lexer structure
; ============================================================================
lexer_init:
    push rbp
    mov rbp, rsp
    
    lea rax, [current_lexer]
    mov [rax + Lexer.source], rcx
    mov [rax + Lexer.current], rcx
    mov qword [rax + Lexer.line], 1
    mov [rax + Lexer.start], rcx
    
    pop rbp
    ret

; ============================================================================
; lexer_peek_char - Look at current character without advancing
; Parameters:
;   RCX = pointer to lexer
; Returns:
;   AL = current character (0 if EOF)
; ============================================================================
lexer_peek_char:
    mov rax, [rcx + Lexer.current]
    movzx rax, byte [rax]
    ret

; ============================================================================
; lexer_advance - Move to next character
; Parameters:
;   RCX = pointer to lexer
; Returns:
;   AL = character that was advanced over
; ============================================================================
lexer_advance:
    push rbp
    mov rbp, rsp
    
    mov rax, [rcx + Lexer.current]
    movzx rdx, byte [rax]
    
    test dl, dl
    jz .eof
    
    inc qword [rcx + Lexer.current]
    
    cmp dl, 10  ; Check for newline
    jne .done
    inc qword [rcx + Lexer.line]
    
.done:
    mov rax, rdx
    pop rbp
    ret
    
.eof:
    xor rax, rax
    pop rbp
    ret

; ============================================================================
; skip_whitespace - Skip whitespace and comments
; Parameters:
;   RCX = pointer to lexer
; ============================================================================
skip_whitespace:
    push rbp
    mov rbp, rsp
    push rcx
    
.loop:
    mov rcx, [rsp]
    call lexer_peek_char
    
    cmp al, ' '
    je .skip
    cmp al, 9   ; tab
    je .skip
    cmp al, 13  ; carriage return
    je .skip
    cmp al, 10  ; newline
    je .skip
    
    ; Check for single-line comment
    cmp al, '/'
    jne .done
    
    mov rcx, [rsp]
    mov rax, [rcx + Lexer.current]
    cmp byte [rax + 1], '/'
    je .skip_line_comment
    
    cmp byte [rax + 1], '*'
    je .skip_block_comment
    
    jmp .done
    
.skip:
    mov rcx, [rsp]
    call lexer_advance
    jmp .loop
    
.skip_line_comment:
    mov rcx, [rsp]
    call lexer_advance
    call lexer_advance
    
.skip_line_loop:
    mov rcx, [rsp]
    call lexer_peek_char
    test al, al
    jz .done
    cmp al, 10
    je .done
    
    mov rcx, [rsp]
    call lexer_advance
    jmp .skip_line_loop
    
.skip_block_comment:
    mov rcx, [rsp]
    call lexer_advance
    call lexer_advance
    
.skip_block_loop:
    mov rcx, [rsp]
    call lexer_peek_char
    test al, al
    jz .done
    
    cmp al, '*'
    jne .skip_block_next
    
    mov rcx, [rsp]
    mov rax, [rcx + Lexer.current]
    cmp byte [rax + 1], '/'
    jne .skip_block_next
    
    mov rcx, [rsp]
    call lexer_advance
    call lexer_advance
    jmp .loop
    
.skip_block_next:
    mov rcx, [rsp]
    call lexer_advance
    jmp .skip_block_loop
    
.done:
    pop rcx
    pop rbp
    ret

; ============================================================================
; is_digit - Check if character is a digit
; Parameters:
;   CL = character to check
; Returns:
;   AL = 1 if digit, 0 otherwise
; ============================================================================
is_digit:
    cmp cl, '0'
    jb .not_digit
    cmp cl, '9'
    ja .not_digit
    mov al, 1
    ret
.not_digit:
    xor al, al
    ret

; ============================================================================
; is_alpha - Check if character is alphabetic or underscore
; Parameters:
;   CL = character to check
; Returns:
;   AL = 1 if alpha, 0 otherwise
; ============================================================================
is_alpha:
    cmp cl, 'a'
    jb .check_upper
    cmp cl, 'z'
    ja .check_underscore
    mov al, 1
    ret
    
.check_upper:
    cmp cl, 'A'
    jb .not_alpha
    cmp cl, 'Z'
    ja .not_alpha
    mov al, 1
    ret
    
.check_underscore:
    cmp cl, '_'
    je .is_alpha
    
.not_alpha:
    xor al, al
    ret
    
.is_alpha:
    mov al, 1
    ret

; ============================================================================
; is_alnum - Check if character is alphanumeric or underscore
; Parameters:
;   CL = character to check
; Returns:
;   AL = 1 if alnum, 0 otherwise
; ============================================================================
is_alnum:
    call is_alpha
    test al, al
    jnz .yes
    call is_digit
.yes:
    ret

; ============================================================================
; scan_identifier - Scan identifier or keyword
; Parameters:
;   RCX = pointer to lexer
;   RDX = pointer to token structure
; ============================================================================
scan_identifier:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    mov r12, rcx  ; Save lexer pointer
    mov r13, rdx  ; Save token pointer
    
    ; Advance while alphanumeric
.loop:
    mov rcx, r12
    call lexer_peek_char
    mov cl, al
    call is_alnum
    test al, al
    jz .done_scanning
    
    mov rcx, r12
    call lexer_advance
    jmp .loop
    
.done_scanning:
    ; Calculate token length
    mov rax, [r12 + Lexer.current]
    mov rbx, [r12 + Lexer.start]
    sub rax, rbx
    mov [r13 + Token.length], rax
    mov rbx, [r12 + Lexer.start]
    mov [r13 + Token.start], rbx
    
    ; Check if it's a keyword
    mov rcx, r12
    mov rdx, r13
    call check_keyword
    
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; ============================================================================
; check_keyword - Check if identifier is a keyword
; Parameters:
;   RCX = pointer to lexer
;   RDX = pointer to token structure
; ============================================================================
check_keyword:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    
    mov r12, rdx  ; Token pointer
    mov r13, [rdx + Token.start]
    mov r14, [rdx + Token.length]
    
    lea rbx, [keywords]
    
.loop:
    mov rax, [rbx + 16]  ; Check end marker
    test rax, rax
    jz .not_keyword
    
    mov r8, [rbx + 8]  ; Keyword length
    cmp r8, r14
    jne .next
    
    ; Compare strings
    mov rcx, r13
    mov rdx, rbx
    mov r8, r14
    call compare_strings
    test al, al
    jnz .found
    
.next:
    ; Move to next keyword entry
    ; Skip string (find null terminator)
    mov rdi, rbx
    xor al, al
    mov rcx, 100
    repne scasb
    mov rbx, rdi
    add rbx, 16  ; Skip length and token type
    jmp .loop
    
.found:
    mov rax, [rbx + 8 + r14 + 1]  ; Get token type
    mov [r12 + Token.type], rax
    jmp .done
    
.not_keyword:
    mov qword [r12 + Token.type], TOKEN_IDENTIFIER
    
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; ============================================================================
; compare_strings - Compare two strings
; Parameters:
;   RCX = string 1
;   RDX = string 2
;   R8 = length
; Returns:
;   AL = 1 if equal, 0 otherwise
; ============================================================================
compare_strings:
    push rbp
    mov rbp, rsp
    
    test r8, r8
    jz .equal
    
.loop:
    movzx rax, byte [rcx]
    movzx r9, byte [rdx]
    cmp al, r9b
    jne .not_equal
    
    inc rcx
    inc rdx
    dec r8
    jnz .loop
    
.equal:
    mov al, 1
    pop rbp
    ret
    
.not_equal:
    xor al, al
    pop rbp
    ret

; ============================================================================
; scan_number - Scan numeric literal
; Parameters:
;   RCX = pointer to lexer
;   RDX = pointer to token structure
; ============================================================================
scan_number:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    
    mov r12, rcx
    mov r13, rdx
    
.loop:
    mov rcx, r12
    call lexer_peek_char
    mov cl, al
    call is_digit
    test al, al
    jz .check_dot
    
    mov rcx, r12
    call lexer_advance
    jmp .loop
    
.check_dot:
    mov rcx, r12
    call lexer_peek_char
    cmp al, '.'
    jne .done
    
    ; Check if next char is also a dot (range operator)
    mov rax, [r12 + Lexer.current]
    cmp byte [rax + 1], '.'
    je .done
    
    ; Consume the dot
    mov rcx, r12
    call lexer_advance
    
.decimal_loop:
    mov rcx, r12
    call lexer_peek_char
    mov cl, al
    call is_digit
    test al, al
    jz .done
    
    mov rcx, r12
    call lexer_advance
    jmp .decimal_loop
    
.done:
    mov qword [r13 + Token.type], TOKEN_NUMBER
    mov rax, [r12 + Lexer.current]
    mov rbx, [r12 + Lexer.start]
    sub rax, rbx
    mov [r13 + Token.length], rax
    mov rbx, [r12 + Lexer.start]
    mov [r13 + Token.start], rbx
    
    pop r13
    pop r12
    pop rbp
    ret

; ============================================================================
; scan_string - Scan string literal
; Parameters:
;   RCX = pointer to lexer
;   RDX = pointer to token structure
; ============================================================================
scan_string:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    
    mov r12, rcx
    mov r13, rdx
    
    ; Skip opening quote
    mov rcx, r12
    call lexer_advance
    
.loop:
    mov rcx, r12
    call lexer_peek_char
    test al, al
    jz .error
    
    cmp al, '"'
    je .done
    
    cmp al, '\'
    je .escape
    
    mov rcx, r12
    call lexer_advance
    jmp .loop
    
.escape:
    mov rcx, r12
    call lexer_advance
    call lexer_advance
    jmp .loop
    
.done:
    ; Skip closing quote
    mov rcx, r12
    call lexer_advance
    
    mov qword [r13 + Token.type], TOKEN_STRING
    mov rax, [r12 + Lexer.current]
    mov rbx, [r12 + Lexer.start]
    sub rax, rbx
    mov [r13 + Token.length], rax
    mov rbx, [r12 + Lexer.start]
    mov [r13 + Token.start], rbx
    
    pop r13
    pop r12
    pop rbp
    ret
    
.error:
    mov qword [r13 + Token.type], TOKEN_ERROR
    pop r13
    pop r12
    pop rbp
    ret

; ============================================================================
; lexer_next_token - Get next token from source
; Parameters:
;   RCX = pointer to lexer
;   RDX = pointer to token structure to fill
; Returns:
;   Token structure filled with next token
; ============================================================================
lexer_next_token:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    mov r12, rcx  ; Lexer pointer
    mov r13, rdx  ; Token pointer
    
    ; Skip whitespace and comments
    mov rcx, r12
    call skip_whitespace
    
    ; Mark start of token
    mov rcx, r12
    mov rax, [rcx + Lexer.current]
    mov [rcx + Lexer.start], rax
    
    ; Store line number in token
    mov rax, [rcx + Lexer.line]
    mov [r13 + Token.line], rax
    
    ; Get current character
    call lexer_peek_char
    
    ; Check for EOF
    test al, al
    jz .eof
    
    ; Check for identifier or keyword
    mov cl, al
    call is_alpha
    test al, al
    jnz .identifier
    
    ; Check for number
    mov rcx, r12
    call lexer_peek_char
    mov cl, al
    call is_digit
    test al, al
    jnz .number
    
    ; Check for string
    mov rcx, r12
    call lexer_peek_char
    cmp al, '"'
    je .string
    
    ; Check for char literal
    cmp al, 39  ; single quote
    je .char_literal
    
    ; Check for operators and punctuation
    jmp .operator
    
.eof:
    mov qword [r13 + Token.type], TOKEN_EOF
    mov qword [r13 + Token.length], 0
    mov rax, [r12 + Lexer.current]
    mov [r13 + Token.start], rax
    jmp .done
    
.identifier:
    mov rcx, r12
    mov rdx, r13
    call scan_identifier
    jmp .done
    
.number:
    mov rcx, r12
    mov rdx, r13
    call scan_number
    jmp .done
    
.string:
    mov rcx, r12
    mov rdx, r13
    call scan_string
    jmp .done
    
.char_literal:
    mov rcx, r12
    call lexer_advance  ; Skip opening quote
    call lexer_advance  ; Get character
    mov bl, al
    call lexer_peek_char
    cmp al, 39  ; Check for closing quote
    jne .error
    call lexer_advance  ; Skip closing quote
    
    mov qword [r13 + Token.type], TOKEN_CHAR
    mov qword [r13 + Token.length], 3
    mov rax, [r12 + Lexer.start]
    mov [r13 + Token.start], rax
    jmp .done
    
.operator:
    mov rcx, r12
    mov rdx, r13
    call scan_operator
    jmp .done
    
.error:
    mov qword [r13 + Token.type], TOKEN_ERROR
    mov qword [r13 + Token.length], 1
    mov rax, [r12 + Lexer.start]
    mov [r13 + Token.start], rax
    
.done:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; ============================================================================
; scan_operator - Scan operator or punctuation token
; Parameters:
;   RCX = pointer to lexer
;   RDX = pointer to token structure
; ============================================================================
scan_operator:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    
    mov r12, rcx
    mov r13, rdx
    
    call lexer_peek_char
    
    ; Single character operators
    cmp al, '+'
    je .plus
    cmp al, '-'
    je .minus
    cmp al, '*'
    je .star
    cmp al, '/'
    je .slash
    cmp al, '%'
    je .percent
    cmp al, '='
    je .assign
    cmp al, '!'
    je .not
    cmp al, '<'
    je .lt
    cmp al, '>'
    je .gt
    cmp al, '&'
    je .and
    cmp al, '|'
    je .or
    cmp al, '^'
    je .xor
    cmp al, '~'
    je .bit_not
    cmp al, '('
    je .lparen
    cmp al, ')'
    je .rparen
    cmp al, '{'
    je .lbrace
    cmp al, '}'
    je .rbrace
    cmp al, '['
    je .lbracket
    cmp al, ']'
    je .rbracket
    cmp al, ';'
    je .semicolon
    cmp al, ':'
    je .colon
    cmp al, ','
    je .comma
    cmp al, '.'
    je .dot
    
    jmp .unknown
    
.plus:
    mov rcx, r12
    call lexer_advance
    call lexer_peek_char
    cmp al, '='
    je .plus_assign
    mov qword [r13 + Token.type], TOKEN_PLUS
    jmp .finish_single
.plus_assign:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_PLUS_ASSIGN
    jmp .finish_double
    
.minus:
    mov rcx, r12
    call lexer_advance
    call lexer_peek_char
    cmp al, '='
    je .minus_assign
    cmp al, '>'
    je .arrow
    mov qword [r13 + Token.type], TOKEN_MINUS
    jmp .finish_single
.minus_assign:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_MINUS_ASSIGN
    jmp .finish_double
.arrow:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_ARROW
    jmp .finish_double
    
.star:
    mov rcx, r12
    call lexer_advance
    call lexer_peek_char
    cmp al, '='
    je .star_assign
    mov qword [r13 + Token.type], TOKEN_STAR
    jmp .finish_single
.star_assign:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_STAR_ASSIGN
    jmp .finish_double
    
.slash:
    mov rcx, r12
    call lexer_advance
    call lexer_peek_char
    cmp al, '='
    je .slash_assign
    mov qword [r13 + Token.type], TOKEN_SLASH
    jmp .finish_single
.slash_assign:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_SLASH_ASSIGN
    jmp .finish_double
    
.percent:
    mov rcx, r12
    call lexer_advance
    call lexer_peek_char
    cmp al, '='
    je .percent_assign
    mov qword [r13 + Token.type], TOKEN_PERCENT
    jmp .finish_single
.percent_assign:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_PERCENT_ASSIGN
    jmp .finish_double
    
.assign:
    mov rcx, r12
    call lexer_advance
    call lexer_peek_char
    cmp al, '='
    je .eq
    mov qword [r13 + Token.type], TOKEN_ASSIGN
    jmp .finish_single
.eq:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_EQ
    jmp .finish_double
    
.not:
    mov rcx, r12
    call lexer_advance
    call lexer_peek_char
    cmp al, '='
    je .neq
    mov qword [r13 + Token.type], TOKEN_NOT
    jmp .finish_single
.neq:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_NEQ
    jmp .finish_double
    
.lt:
    mov rcx, r12
    call lexer_advance
    call lexer_peek_char
    cmp al, '='
    je .lte
    cmp al, '<'
    je .lshift
    mov qword [r13 + Token.type], TOKEN_LT
    jmp .finish_single
.lte:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_LTE
    jmp .finish_double
.lshift:
    call lexer_advance
    call lexer_peek_char
    cmp al, '='
    je .lshift_assign
    mov qword [r13 + Token.type], TOKEN_LSHIFT
    jmp .finish_double
.lshift_assign:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_LSHIFT_ASSIGN
    jmp .finish_triple
    
.gt:
    mov rcx, r12
    call lexer_advance
    call lexer_peek_char
    cmp al, '='
    je .gte
    cmp al, '>'
    je .rshift
    mov qword [r13 + Token.type], TOKEN_GT
    jmp .finish_single
.gte:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_GTE
    jmp .finish_double
.rshift:
    call lexer_advance
    call lexer_peek_char
    cmp al, '='
    je .rshift_assign
    mov qword [r13 + Token.type], TOKEN_RSHIFT
    jmp .finish_double
.rshift_assign:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_RSHIFT_ASSIGN
    jmp .finish_triple
    
.and:
    mov rcx, r12
    call lexer_advance
    call lexer_peek_char
    cmp al, '&'
    je .logical_and
    cmp al, '='
    je .and_assign
    mov qword [r13 + Token.type], TOKEN_BIT_AND
    jmp .finish_single
.logical_and:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_AND
    jmp .finish_double
.and_assign:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_AND_ASSIGN
    jmp .finish_double
    
.or:
    mov rcx, r12
    call lexer_advance
    call lexer_peek_char
    cmp al, '|'
    je .logical_or
    cmp al, '='
    je .or_assign
    mov qword [r13 + Token.type], TOKEN_BIT_OR
    jmp .finish_single
.logical_or:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_OR
    jmp .finish_double
.or_assign:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_OR_ASSIGN
    jmp .finish_double
    
.xor:
    mov rcx, r12
    call lexer_advance
    call lexer_peek_char
    cmp al, '='
    je .xor_assign
    mov qword [r13 + Token.type], TOKEN_BIT_XOR
    jmp .finish_single
.xor_assign:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_XOR_ASSIGN
    jmp .finish_double
    
.bit_not:
    mov rcx, r12
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_BIT_NOT
    jmp .finish_single
    
.lparen:
    mov rcx, r12
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_LPAREN
    jmp .finish_single
    
.rparen:
    mov rcx, r12
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_RPAREN
    jmp .finish_single
    
.lbrace:
    mov rcx, r12
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_LBRACE
    jmp .finish_single
    
.rbrace:
    mov rcx, r12
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_RBRACE
    jmp .finish_single
    
.lbracket:
    mov rcx, r12
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_LBRACKET
    jmp .finish_single
    
.rbracket:
    mov rcx, r12
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_RBRACKET
    jmp .finish_single
    
.semicolon:
    mov rcx, r12
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_SEMICOLON
    jmp .finish_single
    
.colon:
    mov rcx, r12
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_COLON
    jmp .finish_single
    
.comma:
    mov rcx, r12
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_COMMA
    jmp .finish_single
    
.dot:
    mov rcx, r12
    call lexer_advance
    call lexer_peek_char
    cmp al, '.'
    je .range
    mov qword [r13 + Token.type], TOKEN_DOT
    jmp .finish_single
.range:
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_RANGE
    jmp .finish_double
    
.finish_single:
    mov qword [r13 + Token.length], 1
    jmp .finish
    
.finish_double:
    mov qword [r13 + Token.length], 2
    jmp .finish
    
.finish_triple:
    mov qword [r13 + Token.length], 3
    jmp .finish
    
.unknown:
    mov rcx, r12
    call lexer_advance
    mov qword [r13 + Token.type], TOKEN_ERROR
    mov qword [r13 + Token.length], 1
    
.finish:
    mov rax, [r12 + Lexer.start]
    mov [r13 + Token.start], rax
    
    pop r13
    pop r12
    pop rbp
    ret
