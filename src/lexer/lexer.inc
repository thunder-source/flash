%ifndef FLASH_LEXER_INC
%define FLASH_LEXER_INC

; Basic tokens
%define TOKEN_EOF           0
%define TOKEN_IDENTIFIER    1
%define TOKEN_NUMBER        2
%define TOKEN_STRING        3
%define TOKEN_CHAR          4
%define TOKEN_UNKNOWN       0xFFFF

; Keywords
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

; Type keywords
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

; Operators and punctuation
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
%define TOKEN_LSHIFT        72
%define TOKEN_RSHIFT        73
%define TOKEN_BIT_AND       74
%define TOKEN_BIT_OR        75
%define TOKEN_BIT_XOR       76
%define TOKEN_BIT_NOT       77
%define TOKEN_AND           78
%define TOKEN_OR            79
%define TOKEN_NOT           80
%define TOKEN_PLUS_ASSIGN   81
%define TOKEN_MINUS_ASSIGN  82
%define TOKEN_STAR_ASSIGN   83
%define TOKEN_SLASH_ASSIGN  84
%define TOKEN_PERCENT_ASSIGN 85
%define TOKEN_AND_ASSIGN    86
%define TOKEN_OR_ASSIGN     87
%define TOKEN_XOR_ASSIGN    88
%define TOKEN_LSHIFT_ASSIGN 89
%define TOKEN_RSHIFT_ASSIGN 90
%define TOKEN_ARROW         91
%define TOKEN_RANGE         92
%define TOKEN_DOT           93
%define TOKEN_COLON         94
%define TOKEN_SEMICOLON     95
%define TOKEN_COMMA         96
%define TOKEN_LPAREN        97
%define TOKEN_RPAREN        98
%define TOKEN_LBRACE        99
%define TOKEN_RBRACE        100
%define TOKEN_LBRACKET      101
%define TOKEN_RBRACKET      102
%define TOKEN_QUESTION      103
%define TOKEN_DOUBLE_COLON  104
%define TOKEN_ELLIPSIS      105
%define TOKEN_ERROR         255

struc Token
    .type       resd 1
    ._pad_type  resd 1
    .start      resq 1
    .length     resq 1
    .line       resd 1
    .column     resd 1
    .next       resq 1
endstruc

struc Lexer
    .source     resq 1
    .start      resq 1
    .current    resq 1
    .line       resd 1
    .column     resd 1
    .tokens     resq 1
    .tail       resq 1
    .error      resb 1
    ._pad_err   resb 7
    .error_msg  resq 1
endstruc

%endif
