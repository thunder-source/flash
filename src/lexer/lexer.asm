; ============================================================================
; Flash Compiler - Lexer (Tokenizer)
; ============================================================================
; Fast assembly-based lexer for the Flash programming language
; Target: x86-64 Windows
; Assembler: NASM
; ============================================================================

bits 64
default rel

%include "src/lexer/lexer.inc"

section .data

; Keyword table
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
    dq 4, TOKEN_TRUE
    
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
    
    db "const", 0
    dq 5, TOKEN_CCONST
    
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
    
    ; Null terminator for keyword table
    dq 0, 0, 0

section .text

; ============================================================================
; Initialize Lexer
; ============================================================================
; Input:  rcx - Pointer to source code
; Output: rax - Pointer to initialized Lexer structure
global lexer_init
extern malloc
lexer_init:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    mov rdx, rcx            ; Preserve source pointer
    
    ; Allocate memory for Lexer structure
    mov rcx, Lexer_size
    call malloc
    test rax, rax
    jz .error
    
    ; Initialize Lexer fields
    mov [rax + Lexer.source], rdx
    mov [rax + Lexer.start], rdx
    mov [rax + Lexer.current], rdx
    mov dword [rax + Lexer.line], 1
    mov dword [rax + Lexer.column], 1
    xor rdx, rdx
    mov [rax + Lexer.tokens], rdx
    mov [rax + Lexer.tail], rdx
    mov byte [rax + Lexer.error], 0
    mov [rax + Lexer.error_msg], rdx
    
    mov rsp, rbp
    pop rbp
    ret
    
.error:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

; ============================================================================
; Get next token from source
; ============================================================================
; Input:  rcx - Pointer to Lexer structure
; Output: rax - Pointer to new Token, or NULL on error/EOF
global lexer_next_token
extern malloc
lexer_next_token:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    ; Save Lexer pointer
    mov [rsp + 8], rcx
    
    ; Check for end of file
    mov r8, [rcx + Lexer.current]
    cmp byte [r8], 0
    je .eof
    
    ; Skip whitespace and comments
    call skip_whitespace_and_comments
    test al, al
    jnz .error
    
    ; Get current character
    mov rcx, [rsp + 8]
    mov rsi, [rcx + Lexer.current]
    movzx eax, byte [rsi]
    
    ; Handle identifiers and keywords
    call is_alpha
    test al, al
    jnz .identifier_or_keyword
    
    ; Handle numbers
    call is_digit
    test al, al
    jnz .number
    
    ; Handle strings
    cmp al, '"'
    je .string
    
    ; Handle characters
    cmp al, 39  ; Single quote character (escaped as ASCII value)
    je .char
    
    ; Handle operators and punctuation
    jmp .operator
    
.identifier_or_keyword:
    call scan_identifier_or_keyword
    jmp .done
    
.number:
    call scan_number
    jmp .done
    
.string:
    call scan_string
    jmp .done
    
.char:
    call scan_char
    jmp .done
    
.operator:
    call scan_operator
    jmp .done
    
.eof:
    ; Create EOF token
    mov rcx, [rsp + 8]
    mov rdx, [rcx + Lexer.current]
    call create_token
    mov [rax + Token.type], dword TOKEN_EOF
    jmp .done
    
.error:
    xor eax, eax
    
.done:
    mov rsp, rbp
    pop rbp
    ret

; ============================================================================
; Helper Functions
; ============================================================================

; Check if character is alphabetic or underscore
is_alpha:
    mov al, [rsi]
    cmp al, '_'
    je .true
    cmp al, 'A'
    jb .false
    cmp al, 'Z'
    jbe .true
    cmp al, 'a'
    jb .false
    cmp al, 'z'
    jbe .true
.false:
    xor eax, eax
    ret
.true:
    mov eax, 1
    ret

; Check if character is a digit
is_digit:
    mov al, [rsi]
    cmp al, '0'
    jb .false
    cmp al, '9'
    ja .false
.true:
    mov eax, 1
    ret
.false:
    xor eax, eax
    ret

; Skip whitespace and comments
skip_whitespace_and_comments:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    mov rcx, [rsp + 40]  ; Get Lexer pointer from stack
    
.skip_whitespace_loop:
    mov rsi, [rcx + Lexer.current]
    movzx eax, byte [rsi]
    
    ; Check for whitespace
    cmp al, ' '
    je .skip_char
    cmp al, 9
    je .skip_char
    cmp al, 13
    je .skip_char
    cmp al, 10
    je .newline
    
    ; Check for comments
    cmp al, '/'
    jne .done
    
    ; Check for line comment
    cmp byte [rsi + 1], '/'
    je .line_comment
    
    ; Check for block comment
    cmp byte [rsi + 1], '*'
    je .block_comment
    
    jmp .done
    
.skip_char:
    call lexer_advance
    jmp .skip_whitespace_loop
    
.newline:
    call lexer_advance
    inc dword [rcx + Lexer.line]
    mov dword [rcx + Lexer.column], 1
    jmp .skip_whitespace_loop
    
.line_comment:
    call lexer_advance
    call lexer_advance
    
.line_comment_loop:
    mov rsi, [rcx + Lexer.current]
    movzx eax, byte [rsi]
    test al, al
    jz .done
    cmp al, 10
    je .newline
    call lexer_advance
    jmp .line_comment_loop
    
.block_comment:
    call lexer_advance
    call lexer_advance
    
.block_comment_loop:
    mov rsi, [rcx + Lexer.current]
    movzx eax, byte [rsi]
    test al, al
    jz .unterminated_comment
    
    cmp al, '*'
    jne .not_star
    
    cmp byte [rsi + 1], '/'
    jne .not_star
    
    ; Found end of block comment
    call lexer_advance
    call lexer_advance
    jmp .skip_whitespace_loop
    
.not_star:
    cmp al, 10
    je .newline_in_comment
    
    call lexer_advance
    jmp .block_comment_loop
    
.newline_in_comment:
    call lexer_advance
    inc dword [rcx + Lexer.line]
    mov dword [rcx + Lexer.column], 1
    jmp .block_comment_loop
    
.unterminated_comment:
    mov byte [rcx + Lexer.error], 1
    lea rax, [.unterminated_comment_msg]
    mov [rcx + Lexer.error_msg], rax
    mov eax, 1
    jmp .done
    
.done:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
    
.unterminated_comment_msg: db "Unterminated block comment", 0

; Advance to next character in source
lexer_advance:
    mov rsi, [rcx + Lexer.current]
    inc rsi
    mov [rcx + Lexer.current], rsi
    inc dword [rcx + Lexer.column]
    ret

; Create a new token
create_token:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Allocate memory for Token
    mov rcx, Token_size
    call malloc
    test rax, rax
    jz .error
    
    ; Initialize Token fields
    mov r8, [rsp + 40]  ; Get Lexer pointer
    mov r9, [r8 + Lexer.start]
    mov [rax + Token.start], r9
    
    mov r10, [r8 + Lexer.current]
    sub r10, r9
    mov [rax + Token.length], r10
    
    mov edx, [r8 + Lexer.line]
    mov [rax + Token.line], edx
    
    mov edx, [r8 + Lexer.column]
    sub edx, r10d
    mov [rax + Token.column], edx
    
    ; Add to token list
    mov r9, [r8 + Lexer.tail]
    test r9, r9
    jz .first_token
    
    ; Link to previous token
    mov [r9 + Token.next], rax
    jmp .update_tail
    
.first_token:
    mov [r8 + Lexer.tokens], rax
    
.update_tail:
    mov [r8 + Lexer.tail], rax
    
    ; Update start position for next token
    mov r9, [r8 + Lexer.current]
    mov [r8 + Lexer.start], r9
    
    mov rsp, rbp
    pop rbp
    ret
    
.error:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

; Scan identifier or keyword
scan_identifier_or_keyword:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    mov [rsp + 8], rcx  ; Save Lexer pointer
    
    ; Get start of identifier
    mov rsi, [rcx + Lexer.current]
    
    ; Skip first character (already checked)
    call lexer_advance
    
.scan_loop:
    mov rcx, [rsp + 8]
    mov rsi, [rcx + Lexer.current]
    movzx eax, byte [rsi]
    
    call is_alpha
    test al, al
    jnz .continue
    
    call is_digit
    test al, al
    jnz .continue
    
    jmp .done
    
.continue:
    call lexer_advance
    jmp .scan_loop
    
.done:
    ; Create token
    mov rcx, [rsp + 8]
    call create_token
    
    ; Check if it's a keyword
    mov rcx, rax
    call check_keyword
    
    ; Set token type
    mov [rax + Token.type], edx
    
    mov rsp, rbp
    pop rbp
    ret

; Check if identifier is a keyword
check_keyword:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    mov [rsp + 8], rcx  ; Save Token pointer
    
    ; Get token text
    mov rsi, [rcx + Token.start]
    mov rcx, [rcx + Token.length]
    
    ; Search keyword table
    lea rdi, [keywords]
    
.keyword_loop:
    ; Check for end of table
    cmp qword [rdi], 0
    je .not_found
    
    ; Compare lengths
    mov rdx, [rdi + 8]
    cmp rcx, rdx
    jne .next_keyword
    
    ; Compare strings
    push rdi
    push rsi
    push rcx
    repe cmpsb
    pop rcx
    pop rsi
    pop rdi
    jne .next_keyword
    
    ; Found keyword
    mov edx, [rdi + 16]  ; Get token type
    jmp .done
    
.next_keyword:
    add rdi, 24  ; Move to next keyword entry
    jmp .keyword_loop
    
.not_found:
    mov edx, TOKEN_IDENTIFIER
    
.done:
    mov rax, [rsp + 8]  ; Return Token pointer
    mov rsp, rbp
    pop rbp
    ret

; Scan number literal
scan_number:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    mov [rsp + 8], rcx  ; Save Lexer pointer
    
    ; Check for hexadecimal
    mov rsi, [rcx + Lexer.current]
    cmp byte [rsi], '0'
    jne .decimal
    
    cmp byte [rsi + 1], 'x'
    jne .decimal
    
    ; Skip '0x' prefix
    call lexer_advance
    call lexer_advance
    jmp .hex_loop
    
.hex_loop:
    mov rcx, [rsp + 8]
    mov rsi, [rcx + Lexer.current]
    movzx eax, byte [rsi]
    
    ; Check for hex digit
    call is_hex_digit
    test al, al
    jz .hex_done
    
    call lexer_advance
    jmp .hex_loop
    
.hex_done:
    jmp .create_token
    
.decimal:
    ; Skip first digit (already checked)
    call lexer_advance
    
.decimal_loop:
    mov rcx, [rsp + 8]
    mov rsi, [rcx + Lexer.current]
    movzx eax, byte [rsi]
    
    call is_digit
    test al, al
    jz .decimal_done
    
    call lexer_advance
    jmp .decimal_loop
    
.decimal_done:
    ; Check for floating point
    cmp byte [rsi], '.'
    jne .check_exponent
    
    ; Skip decimal point
    call lexer_advance
    
.fraction_loop:
    mov rcx, [rsp + 8]
    mov rsi, [rcx + Lexer.current]
    movzx eax, byte [rsi]
    
    call is_digit
    test al, al
    jz .check_exponent
    
    call lexer_advance
    jmp .fraction_loop
    
.check_exponent:
    mov rsi, [rcx + Lexer.current]
    mov al, [rsi]
    or al, 0x20  ; Convert to lowercase
    
    cmp al, 'e'
    je .process_exponent
    
    jmp .create_token
    
.process_exponent:
    ; Skip 'e' or 'E'
    call lexer_advance
    
    ; Check for optional sign
    mov rsi, [rcx + Lexer.current]
    mov al, [rsi]
    
    cmp al, '+'
    je .skip_exponent_sign
    cmp al, '-'
    jne .exponent_digits
    
.skip_exponent_sign:
    call lexer_advance
    
.exponent_digits:
    mov rcx, [rsp + 8]
    mov rsi, [rcx + Lexer.current]
    movzx eax, byte [rsi]
    
    call is_digit
    test al, al
    jz .create_token
    
    call lexer_advance
    jmp .exponent_digits
    
.create_token:
    mov rcx, [rsp + 8]
    call create_token
    
    ; Set token type
    mov [rax + Token.type], dword TOKEN_NUMBER
    
    mov rsp, rbp
    pop rbp
    ret

; Check if character is a hexadecimal digit
is_hex_digit:
    mov al, [rsi]
    call is_digit
    test al, al
    jnz .true
    
    mov al, [rsi]
    or al, 0x20  ; Convert to lowercase
    
    cmp al, 'a'
    jb .false
    cmp al, 'f'
    ja .false
    
.true:
    mov eax, 1
    ret
    
.false:
    xor eax, eax
    ret

; Scan string literal
scan_string:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    mov [rsp + 8], rcx  ; Save Lexer pointer
    
    ; Skip opening quote
    call lexer_advance
    
.string_loop:
    mov rcx, [rsp + 8]
    mov rsi, [rcx + Lexer.current]
    movzx eax, byte [rsi]
    
    ; Check for end of string
    test al, al
    jz .unterminated_string
    
    cmp al, '"'
    je .end_string
    
    ; Handle escape sequences
    cmp al, 92
    jne .next_char
    
    ; Skip backslash
    call lexer_advance
    
    ; Check for valid escape sequence
    mov rsi, [rcx + Lexer.current]
    movzx eax, byte [rsi]
    
    ; TODO: Handle escape sequences (\n, \t, etc.)
    
.next_char:
    call lexer_advance
    jmp .string_loop
    
.end_string:
    ; Skip closing quote
    call lexer_advance
    
    ; Create token
    mov rcx, [rsp + 8]
    call create_token
    
    ; Set token type
    mov [rax + Token.type], dword TOKEN_STRING
    
    mov rsp, rbp
    pop rbp
    ret
    
.unterminated_string:
    mov rcx, [rsp + 8]
    mov byte [rcx + Lexer.error], 1
    lea rax, [.unterminated_string_msg]
    mov [rcx + Lexer.error_msg], rax
    xor eax, eax
    
    mov rsp, rbp
    pop rbp
    ret
    
.unterminated_string_msg: db "Unterminated string literal", 0

; Scan character literal
scan_char:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    mov [rsp + 8], rcx  ; Save Lexer pointer
    
    ; Skip opening quote
    call lexer_advance
    
    ; Check for empty character literal
    mov rcx, [rsp + 8]
    mov rsi, [rcx + Lexer.current]
    cmp byte [rsi], 39  ; Single quote character
    je .empty_char
    
    ; Handle escape sequences
    cmp byte [rsi], 92
    jne .next_char
    
    ; Skip backslash
    call lexer_advance
    
    ; Check for valid escape sequence
    mov rsi, [rcx + Lexer.current]
    movzx eax, byte [rsi]
    
    ; TODO: Handle escape sequences (\n, \t, etc.)
    
.next_char:
    call lexer_advance
    
    ; Check for closing quote
    mov rcx, [rsp + 8]
    mov rsi, [rcx + Lexer.current]
    cmp byte [rsi], 39  ; Single quote character
    jne .unterminated_char
    
    ; Skip closing quote
    call lexer_advance
    
    ; Create token
    mov rcx, [rsp + 8]
    call create_token
    
    ; Set token type
    mov [rax + Token.type], dword TOKEN_CHAR
    
    mov rsp, rbp
    pop rbp
    ret
    
.empty_char:
    mov rcx, [rsp + 8]
    mov byte [rcx + Lexer.error], 1
    lea rax, [.empty_char_msg]
    mov [rcx + Lexer.error_msg], rax
    xor eax, eax
    
    mov rsp, rbp
    pop rbp
    ret
    
.unterminated_char:
    mov rcx, [rsp + 8]
    mov byte [rcx + Lexer.error], 1
    lea rax, [.unterminated_char_msg]
    mov [rcx + Lexer.error_msg], rax
    xor eax, eax
    
    mov rsp, rbp
    pop rbp
    ret
    
.empty_char_msg: db "Empty character literal", 0
.unterminated_char_msg: db "Unterminated character literal", 0

; Scan operator or punctuation
scan_operator:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    mov [rsp + 8], rcx  ; Save Lexer pointer
    
    mov rcx, [rsp + 8]
    mov rsi, [rcx + Lexer.current]
    movzx eax, byte [rsi]
    mov rdx, rsi
    inc rdx
    
    cmp al, '='
    je .check_eq
    cmp al, '!'
    je .check_neq
    cmp al, '<'
    je .check_lte_or_lshift
    cmp al, '>'
    je .check_gte_or_rshift
    cmp al, '+'
    je .check_plus_assign
    cmp al, '-'
    je .check_minus_assign_or_arrow
    cmp al, '*'
    je .check_star_assign
    cmp al, '/'
    je .check_slash_assign
    cmp al, '%'
    je .check_percent_assign
    cmp al, '&'
    je .check_and_assign
    cmp al, '|'
    je .check_or_assign
    cmp al, '^'
    je .check_xor_assign
    cmp al, '~'
    je .bit_not
    cmp al, '.'
    je .dot
    cmp al, ';'
    je .semicolon
    cmp al, ':'
    je .colon
    cmp al, ','
    je .comma
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
    cmp al, '?'
    je .question
    
    jmp .assign_unknown
    
.check_eq:
    cmp byte [rdx], '='
    jne .assign
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_EQ
    jmp .done
    
.check_neq:
    cmp byte [rdx], '='
    jne .not
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_NEQ
    jmp .done
    
.check_lte_or_lshift:
    cmp byte [rdx], '='
    je .lte
    cmp byte [rdx], '<'
    jne .lt
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_LSHIFT
    jmp .done
    
.lte:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_LTE
    jmp .done
    
.lt:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_LT
    jmp .done
    
.check_gte_or_rshift:
    cmp byte [rdx], '='
    je .gte
    cmp byte [rdx], '>'
    jne .gt
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_RSHIFT
    jmp .done
    
.gte:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_GTE
    jmp .done
    
.gt:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_GT
    jmp .done
    
.check_plus_assign:
    cmp byte [rdx], '='
    jne .plus
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_PLUS_ASSIGN
    jmp .done
    
.plus:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_PLUS
    jmp .done
    
.check_minus_assign_or_arrow:
    cmp byte [rdx], '='
    je .minus_assign
    cmp byte [rdx], '>'
    je .arrow
    jmp .minus
    
.arrow:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_ARROW
    jmp .done
    
.minus_assign:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_MINUS_ASSIGN
    jmp .done
    
.minus:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_MINUS
    jmp .done
    
.check_star_assign:
    cmp byte [rdx], '='
    jne .star
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_STAR_ASSIGN
    jmp .done
    
.star:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_STAR
    jmp .done
    
.check_slash_assign:
    cmp byte [rdx], '='
    jne .slash
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_SLASH_ASSIGN
    jmp .done
    
.slash:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_SLASH
    jmp .done
    
.check_percent_assign:
    cmp byte [rdx], '='
    jne .percent
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_PERCENT_ASSIGN
    jmp .done
    
.percent:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_PERCENT
    jmp .done
    
.check_and_assign:
    cmp byte [rdx], '='
    je .and_assign
    cmp byte [rdx], '&'
    je .logical_and
    jmp .bit_and
    
.logical_and:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_AND
    jmp .done
    
.and_assign:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_AND_ASSIGN
    jmp .done
    
.bit_and:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_BIT_AND
    jmp .done
    
.check_or_assign:
    cmp byte [rdx], '='
    je .or_assign
    cmp byte [rdx], '|'
    je .logical_or
    jmp .bit_or
    
.logical_or:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_OR
    jmp .done
    
.or_assign:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_OR_ASSIGN
    jmp .done
    
.bit_or:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_BIT_OR
    jmp .done
    
.check_xor_assign:
    cmp byte [rdx], '='
    je .xor_assign
    jmp .bit_xor
    
.xor_assign:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_XOR_ASSIGN
    jmp .done
    
.bit_xor:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_BIT_XOR
    jmp .done
    
.bit_not:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_BIT_NOT
    jmp .done
    
.dot:
    cmp byte [rdx], '.'
    je .range
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_DOT
    jmp .done
    
.range:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_RANGE
    jmp .done
    
.semicolon:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_SEMICOLON
    jmp .done
    
.colon:
    cmp byte [rdx], ':'
    je .double_colon
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_COLON
    jmp .done
    
.double_colon:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_DOUBLE_COLON
    jmp .done
    
.comma:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_COMMA
    jmp .done
    
.lparen:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_LPAREN
    jmp .done
    
.rparen:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_RPAREN
    jmp .done
    
.lbrace:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_LBRACE
    jmp .done
    
.rbrace:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_RBRACE
    jmp .done
    
.lbracket:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_LBRACKET
    jmp .done
    
.rbracket:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_RBRACKET
    jmp .done
    
.question:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_QUESTION
    jmp .done
    
.assign:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_ASSIGN
    jmp .done
    
.assign_unknown:
    cmp al, '='
    je .assign
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_UNKNOWN
    jmp .done
    
.not:
    mov rcx, [rsp + 8]
    call lexer_advance
    mov rcx, [rsp + 8]
    call create_token
    mov [rax + Token.type], dword TOKEN_NOT
    jmp .done
    
.done:
    mov rsp, rbp
    pop rbp
    ret

