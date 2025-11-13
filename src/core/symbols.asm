; ============================================================================
; Flash Compiler - Symbol Table
; ============================================================================
; Hash-based symbol table for fast name lookups
; Supports scoped symbols with shadowing
; ============================================================================

bits 64
default rel

extern arena_alloc
extern arena_reset

; ============================================================================
; Symbol Types
; ============================================================================
%define SYM_VARIABLE    0
%define SYM_FUNCTION    1
%define SYM_PARAMETER   2
%define SYM_STRUCT      3
%define SYM_ENUM        4
%define SYM_CONST       5

; ============================================================================
; Type Kinds (matching AST type nodes)
; ============================================================================
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

; ============================================================================
; Symbol Structure
; ============================================================================
struc Symbol
    .name:          resq 1      ; Pointer to name string
    .name_len:      resq 1      ; Length of name
    .type:          resq 1      ; Symbol type (SYM_VARIABLE, etc.)
    .data_type:     resq 1      ; Data type (TYPE_I32, etc.) or pointer to type node
    .scope_level:   resq 1      ; Scope depth (0 = global)
    .is_mutable:    resq 1      ; 1 if mutable, 0 if immutable
    .next:          resq 1      ; Next symbol in hash chain
    .value:         resq 1      ; For constants or function pointer
endstruc

; ============================================================================
; Symbol Table Structure (Hash Table)
; ============================================================================
%define SYMTABLE_SIZE 256       ; Power of 2 for fast modulo

struc SymTable
    .buckets:       resq SYMTABLE_SIZE  ; Hash buckets
    .scope_level:   resq 1              ; Current scope depth
    .parent:        resq 1              ; Parent symbol table (for nested scopes)
endstruc

; ============================================================================
; Data Section
; ============================================================================
section .data
    ; Error messages
    msg_sym_exists db "Symbol already defined in this scope", 0
    msg_sym_notfound db "Symbol not found", 0

section .bss
    global_symtable:    resb SymTable_size
    current_scope:      resq 1

; ============================================================================
; Code Section
; ============================================================================
section .text

global symtable_init
global symtable_create
global symtable_insert
global symtable_lookup
global symtable_lookup_current_scope
global symtable_enter_scope
global symtable_exit_scope
global symtable_hash

; ============================================================================
; symtable_init - Initialize global symbol table
; Returns:
;   RAX = pointer to global symbol table
; ============================================================================
symtable_init:
    push rbp
    mov rbp, rsp
    
    lea rax, [global_symtable]
    
    ; Zero out all buckets
    mov rcx, SYMTABLE_SIZE
    lea rdx, [rax + SymTable.buckets]
    
.clear_loop:
    mov qword [rdx], 0
    add rdx, 8
    dec rcx
    jnz .clear_loop
    
    ; Set scope level to 0 (global)
    mov qword [rax + SymTable.scope_level], 0
    mov qword [rax + SymTable.parent], 0
    
    ; Set as current scope
    mov [current_scope], rax
    
    pop rbp
    ret

; ============================================================================
; symtable_create - Create new symbol table (for new scope)
; Parameters:
;   RCX = parent symbol table pointer
; Returns:
;   RAX = pointer to new symbol table
; ============================================================================
symtable_create:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    
    mov rbx, rcx  ; Save parent
    
    ; Allocate symbol table
    mov rcx, SymTable_size
    call arena_alloc
    test rax, rax
    jz .error
    
    ; Zero out buckets
    mov rcx, SYMTABLE_SIZE
    lea rdx, [rax + SymTable.buckets]
    
.clear_loop:
    mov qword [rdx], 0
    add rdx, 8
    dec rcx
    jnz .clear_loop
    
    ; Set parent and scope level
    mov [rax + SymTable.parent], rbx
    test rbx, rbx
    jz .global_scope
    
    ; Increment scope level from parent
    mov rcx, [rbx + SymTable.scope_level]
    inc rcx
    mov [rax + SymTable.scope_level], rcx
    jmp .done
    
.global_scope:
    mov qword [rax + SymTable.scope_level], 0
    
.done:
    pop rbx
    add rsp, 32
    pop rbp
    ret
    
.error:
    xor rax, rax
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; symtable_hash - Compute hash of string
; Parameters:
;   RCX = pointer to string
;   RDX = string length
; Returns:
;   RAX = hash value (0 to SYMTABLE_SIZE-1)
; ============================================================================
symtable_hash:
    push rbp
    mov rbp, rsp
    
    xor rax, rax        ; hash = 0
    test rdx, rdx
    jz .done
    
    mov r8, rcx         ; String pointer
    mov r9, rdx         ; Length
    
.hash_loop:
    movzx r10, byte [r8]
    imul rax, 31        ; hash = hash * 31
    add rax, r10        ; hash += char
    inc r8
    dec r9
    jnz .hash_loop
    
    ; Modulo by table size (use AND since size is power of 2)
    and rax, SYMTABLE_SIZE - 1
    
.done:
    pop rbp
    ret

; ============================================================================
; symtable_insert - Insert symbol into symbol table
; Parameters:
;   RCX = symbol table pointer
;   RDX = symbol pointer
; Returns:
;   RAX = 1 if success, 0 if symbol already exists in this scope
; ============================================================================
symtable_insert:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    push r13
    
    mov r12, rcx        ; Symbol table
    mov r13, rdx        ; Symbol
    
    ; Check if symbol already exists in current scope
    mov rcx, r12
    mov rdx, [r13 + Symbol.name]
    mov r8, [r13 + Symbol.name_len]
    call symtable_lookup_current_scope
    test rax, rax
    jnz .error          ; Symbol exists
    
    ; Compute hash
    mov rcx, [r13 + Symbol.name]
    mov rdx, [r13 + Symbol.name_len]
    call symtable_hash
    mov rbx, rax        ; Save hash
    
    ; Insert at head of chain
    lea rcx, [r12 + SymTable.buckets]
    mov rdx, [rcx + rbx * 8]        ; Get current head
    mov [r13 + Symbol.next], rdx    ; symbol->next = head
    mov [rcx + rbx * 8], r13        ; head = symbol
    
    mov rax, 1          ; Success
    jmp .done
    
.error:
    xor rax, rax        ; Failure
    
.done:
    pop r13
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; symtable_lookup - Lookup symbol in symbol table and parent scopes
; Parameters:
;   RCX = symbol table pointer
;   RDX = symbol name pointer
;   R8 = symbol name length
; Returns:
;   RAX = pointer to symbol if found, 0 otherwise
; ============================================================================
symtable_lookup:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    push r13
    push r14
    
    mov r12, rcx        ; Symbol table
    mov r13, rdx        ; Name
    mov r14, r8         ; Length
    
.search_scope:
    ; Compute hash
    mov rcx, r13
    mov rdx, r14
    call symtable_hash
    mov rbx, rax
    
    ; Get bucket head
    lea rcx, [r12 + SymTable.buckets]
    mov rax, [rcx + rbx * 8]
    
    ; Search chain
.search_chain:
    test rax, rax
    jz .not_in_scope
    
    ; Compare name length first
    mov rcx, [rax + Symbol.name_len]
    cmp rcx, r14
    jne .next_symbol
    
    ; Compare names
    mov rdi, [rax + Symbol.name]
    mov rsi, r13
    mov rcx, r14
    repe cmpsb
    je .found
    
.next_symbol:
    mov rax, [rax + Symbol.next]
    jmp .search_chain
    
.not_in_scope:
    ; Try parent scope
    mov r12, [r12 + SymTable.parent]
    test r12, r12
    jnz .search_scope
    
    ; Not found
    xor rax, rax
    jmp .done
    
.found:
    ; RAX already points to symbol
    
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; symtable_lookup_current_scope - Lookup symbol only in current scope
; Parameters:
;   RCX = symbol table pointer
;   RDX = symbol name pointer
;   R8 = symbol name length
; Returns:
;   RAX = pointer to symbol if found, 0 otherwise
; ============================================================================
symtable_lookup_current_scope:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    push r13
    push r14
    
    mov r12, rcx        ; Symbol table
    mov r13, rdx        ; Name
    mov r14, r8         ; Length
    
    ; Compute hash
    mov rcx, r13
    mov rdx, r14
    call symtable_hash
    mov rbx, rax
    
    ; Get bucket head
    lea rcx, [r12 + SymTable.buckets]
    mov rax, [rcx + rbx * 8]
    
    ; Search chain
.search_chain:
    test rax, rax
    jz .not_found
    
    ; Compare name length first
    mov rcx, [rax + Symbol.name_len]
    cmp rcx, r14
    jne .next_symbol
    
    ; Compare names
    mov rdi, [rax + Symbol.name]
    mov rsi, r13
    mov rcx, r14
    repe cmpsb
    je .found
    
.next_symbol:
    mov rax, [rax + Symbol.next]
    jmp .search_chain
    
.not_found:
    xor rax, rax
    
.found:
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; symtable_enter_scope - Enter new scope (create new symbol table)
; Returns:
;   RAX = pointer to new symbol table
; ============================================================================
symtable_enter_scope:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Create new symbol table with current as parent
    mov rcx, [current_scope]
    call symtable_create
    
    ; Set as current scope
    mov [current_scope], rax
    
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; symtable_exit_scope - Exit current scope (return to parent)
; Returns:
;   RAX = pointer to parent symbol table
; ============================================================================
symtable_exit_scope:
    push rbp
    mov rbp, rsp
    
    ; Get current scope
    mov rax, [current_scope]
    test rax, rax
    jz .error
    
    ; Get parent
    mov rax, [rax + SymTable.parent]
    mov [current_scope], rax
    
    pop rbp
    ret
    
.error:
    xor rax, rax
    pop rbp
    ret
