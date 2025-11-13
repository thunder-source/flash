; ============================================================================
; Flash Compiler - AST (Abstract Syntax Tree) Definitions
; ============================================================================
; AST node structures for the Flash programming language
; ============================================================================

bits 64
default rel

; ============================================================================
; AST Node Type Constants
; ============================================================================
%define AST_PROGRAM         0
%define AST_FUNCTION        1
%define AST_STRUCT_DEF      2
%define AST_ENUM_DEF        3
%define AST_CONST_DEF       4
%define AST_IMPORT          5

; Statement types (20-40)
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

; Expression types (50-100)
%define AST_BINARY_EXPR     50
%define AST_UNARY_EXPR      51
%define AST_LITERAL_EXPR    52
%define AST_IDENTIFIER      53
%define AST_CALL_EXPR       54
%define AST_INDEX_EXPR      55
%define AST_FIELD_EXPR      56
%define AST_CAST_EXPR       57
%define AST_SIZEOF_EXPR     58
%define AST_ALLOC_EXPR      59
%define AST_FREE_EXPR       60
%define AST_ARRAY_LITERAL   61
%define AST_STRUCT_LITERAL  62

; Type nodes (100-110)
%define AST_TYPE_PRIMITIVE  100
%define AST_TYPE_POINTER    101
%define AST_TYPE_ARRAY      102
%define AST_TYPE_NAMED      103

; ============================================================================
; Base AST Node Structure (16 bytes header)
; ============================================================================
struc ASTNode
    .type:      resq 1      ; Node type
    .line:      resq 1      ; Line number for error reporting
endstruc

; ============================================================================
; Program Node - Root of AST
; ============================================================================
struc ASTProgramNode
    .base:          resb ASTNode_size
    .declarations:  resq 1      ; Pointer to array of declaration nodes
    .decl_count:    resq 1      ; Number of declarations
    .decl_capacity: resq 1      ; Capacity of declarations array
endstruc

; ============================================================================
; Function Node
; ============================================================================
struc ASTFunctionNode
    .base:          resb ASTNode_size
    .name:          resq 1      ; Function name (string pointer)
    .name_len:      resq 1      ; Name length
    .params:        resq 1      ; Array of parameter nodes
    .param_count:   resq 1      ; Number of parameters
    .return_type:   resq 1      ; Return type node (or 0 for void)
    .body:          resq 1      ; Block statement node
    .is_inline:     resq 1      ; 1 if inline, 0 otherwise
    .is_export:     resq 1      ; 1 if exported, 0 otherwise
endstruc

; ============================================================================
; Parameter Node
; ============================================================================
struc ASTParamNode
    .name:          resq 1      ; Parameter name
    .name_len:      resq 1      ; Name length
    .type:          resq 1      ; Type node
endstruc

; ============================================================================
; Struct Definition Node
; ============================================================================
struc ASTStructDefNode
    .base:          resb ASTNode_size
    .name:          resq 1      ; Struct name
    .name_len:      resq 1      ; Name length
    .fields:        resq 1      ; Array of field nodes
    .field_count:   resq 1      ; Number of fields
    .is_export:     resq 1      ; 1 if exported, 0 otherwise
endstruc

; ============================================================================
; Field Node
; ============================================================================
struc ASTFieldNode
    .name:          resq 1      ; Field name
    .name_len:      resq 1      ; Name length
    .type:          resq 1      ; Type node
endstruc

; ============================================================================
; Block Statement Node
; ============================================================================
struc ASTBlockNode
    .base:          resb ASTNode_size
    .statements:    resq 1      ; Array of statement nodes
    .stmt_count:    resq 1      ; Number of statements
    .stmt_capacity: resq 1      ; Capacity
endstruc

; ============================================================================
; Let Statement Node
; ============================================================================
struc ASTLetStmtNode
    .base:          resb ASTNode_size
    .name:          resq 1      ; Variable name
    .name_len:      resq 1      ; Name length
    .type:          resq 1      ; Type node
    .initializer:   resq 1      ; Expression node
    .is_mutable:    resq 1      ; 1 if mutable, 0 otherwise
endstruc

; ============================================================================
; Assignment Statement Node
; ============================================================================
struc ASTAssignStmtNode
    .base:          resb ASTNode_size
    .target:        resq 1      ; Target expression (identifier, index, field)
    .operator:      resq 1      ; Assignment operator token type
    .value:         resq 1      ; Value expression
endstruc

; ============================================================================
; If Statement Node
; ============================================================================
struc ASTIfStmtNode
    .base:          resb ASTNode_size
    .condition:     resq 1      ; Condition expression
    .then_block:    resq 1      ; Then block statement
    .else_block:    resq 1      ; Else block (or 0 if no else)
endstruc

; ============================================================================
; While Statement Node
; ============================================================================
struc ASTWhileStmtNode
    .base:          resb ASTNode_size
    .condition:     resq 1      ; Condition expression
    .body:          resq 1      ; Body block statement
endstruc

; ============================================================================
; For Statement Node
; ============================================================================
struc ASTForStmtNode
    .base:          resb ASTNode_size
    .iterator:      resq 1      ; Iterator variable name
    .iter_len:      resq 1      ; Iterator name length
    .start:         resq 1      ; Start expression
    .end:           resq 1      ; End expression
    .body:          resq 1      ; Body block statement
endstruc

; ============================================================================
; Return Statement Node
; ============================================================================
struc ASTReturnStmtNode
    .base:          resb ASTNode_size
    .value:         resq 1      ; Return value expression (or 0 for void)
endstruc

; ============================================================================
; Binary Expression Node
; ============================================================================
struc ASTBinaryExprNode
    .base:          resb ASTNode_size
    .left:          resq 1      ; Left operand
    .operator:      resq 1      ; Operator token type
    .right:         resq 1      ; Right operand
endstruc

; ============================================================================
; Unary Expression Node
; ============================================================================
struc ASTUnaryExprNode
    .base:          resb ASTNode_size
    .operator:      resq 1      ; Operator token type
    .operand:       resq 1      ; Operand expression
endstruc

; ============================================================================
; Literal Expression Node
; ============================================================================
struc ASTLiteralNode
    .base:          resb ASTNode_size
    .value:         resq 1      ; Pointer to literal value
    .length:        resq 1      ; Length of literal
    .literal_type:  resq 1      ; Type of literal (number, string, char, bool)
endstruc

; ============================================================================
; Identifier Expression Node
; ============================================================================
struc ASTIdentifierNode
    .base:          resb ASTNode_size
    .name:          resq 1      ; Identifier name
    .length:        resq 1      ; Name length
endstruc

; ============================================================================
; Function Call Expression Node
; ============================================================================
struc ASTCallExprNode
    .base:          resb ASTNode_size
    .function:      resq 1      ; Function expression (usually identifier)
    .arguments:     resq 1      ; Array of argument expressions
    .arg_count:     resq 1      ; Number of arguments
endstruc

; ============================================================================
; Array Index Expression Node
; ============================================================================
struc ASTIndexExprNode
    .base:          resb ASTNode_size
    .array:         resq 1      ; Array expression
    .index:         resq 1      ; Index expression
endstruc

; ============================================================================
; Field Access Expression Node
; ============================================================================
struc ASTFieldExprNode
    .base:          resb ASTNode_size
    .object:        resq 1      ; Object expression
    .field:         resq 1      ; Field name
    .field_len:     resq 1      ; Field name length
endstruc

; ============================================================================
; Type Nodes
; ============================================================================
struc ASTTypeNode
    .base:          resb ASTNode_size
    .type_kind:     resq 1      ; Type kind (primitive, pointer, array, named)
    .data:          resq 1      ; Type-specific data
endstruc

; ============================================================================
; Primitive Type Data
; ============================================================================
struc ASTPrimitiveType
    .token_type:    resq 1      ; Token type (TOKEN_I32, TOKEN_U64, etc.)
endstruc

; ============================================================================
; Pointer Type Data
; ============================================================================
struc ASTPointerType
    .base_type:     resq 1      ; Pointer to base type node
endstruc

; ============================================================================
; Array Type Data
; ============================================================================
struc ASTArrayType
    .element_type:  resq 1      ; Pointer to element type node
    .size:          resq 1      ; Array size expression
endstruc

; ============================================================================
; Import Node
; ============================================================================
struc ASTImportNode
    .base:          resb ASTNode_size
    .module_name:   resq 1      ; Module name
    .module_len:    resq 1      ; Module name length
    .symbols:       resq 1      ; Array of symbol names (or 0 for all)
    .symbol_count:  resq 1      ; Number of symbols
    .alias:         resq 1      ; Alias name (or 0)
    .alias_len:     resq 1      ; Alias length
endstruc

; ============================================================================
; Const Definition Node
; ============================================================================
struc ASTConstDefNode
    .base:          resb ASTNode_size
    .name:          resq 1      ; Constant name
    .name_len:      resq 1      ; Name length
    .type:          resq 1      ; Type node
    .value:         resq 1      ; Value expression
    .is_export:     resq 1      ; 1 if exported
endstruc

section .text

; Export structure sizes for use in parser
global ASTNode_size
global ASTProgramNode_size
global ASTFunctionNode_size
global ASTBlockNode_size
global ASTLetStmtNode_size
global ASTAssignStmtNode_size
global ASTIfStmtNode_size
global ASTWhileStmtNode_size
global ASTForStmtNode_size
global ASTReturnStmtNode_size
global ASTBinaryExprNode_size
global ASTUnaryExprNode_size
global ASTLiteralNode_size
global ASTIdentifierNode_size
global ASTCallExprNode_size
global ASTIndexExprNode_size
global ASTFieldExprNode_size
global ASTTypeNode_size
