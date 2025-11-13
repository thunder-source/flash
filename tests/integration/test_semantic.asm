; ============================================================================
; Test program for Semantic Analyzer and Symbol Table
; ============================================================================

bits 64
default rel

extern symtable_init
extern symtable_insert
extern symtable_lookup
extern symtable_enter_scope
extern symtable_exit_scope
extern arena_init
extern arena_alloc
extern ExitProcess
extern GetStdHandle
extern WriteFile
extern ReadConsoleA

%define STD_OUTPUT_HANDLE -11
%define STD_INPUT_HANDLE -10

%define SYM_VARIABLE    0
%define TYPE_I32        2

; Symbol structure
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

section .data
    msg_header db "=== Symbol Table Test ===", 13, 10, 0
    msg_test1 db "Test 1: Insert variable 'x'... ", 0
    msg_test2 db "Test 2: Lookup variable 'x'... ", 0
    msg_test3 db "Test 3: Enter new scope... ", 0
    msg_test4 db "Test 4: Insert variable 'y' in new scope... ", 0
    msg_test5 db "Test 5: Lookup 'x' from nested scope... ", 0
    msg_test6 db "Test 6: Exit scope... ", 0
    msg_test7 db "Test 7: Lookup 'y' after exiting scope... ", 0
    msg_pass db "[PASS]", 13, 10, 0
    msg_fail db "[FAIL]", 13, 10, 0
    msg_summary db 13, 10, "All tests passed!", 13, 10, 0
    msg_pause db 13, 10, "Press Enter to exit...", 0
    
    var_x db "x", 0
    var_y db "y", 0
    
    bytes_written dd 0

section .bss
    stdout resq 1
    stdin resq 1
    symtable resq 1

section .text
global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Get stdout
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout], rax
    
    ; Get stdin
    mov rcx, STD_INPUT_HANDLE
    call GetStdHandle
    mov [stdin], rax
    
    ; Header
    lea rcx, [msg_header]
    call print
    
    ; Init arena
    xor rcx, rcx
    call arena_init
    test rax, rax
    jz .error
    
    ; Init symbol table
    call symtable_init
    mov [symtable], rax
    
    ; Test 1: Insert variable 'x'
    lea rcx, [msg_test1]
    call print
    
    ; Create symbol for 'x'
    mov rcx, Symbol_size
    call arena_alloc
    mov rbx, rax
    
    lea rcx, [var_x]
    mov [rbx + Symbol.name], rcx
    mov qword [rbx + Symbol.name_len], 1
    mov qword [rbx + Symbol.type], SYM_VARIABLE
    mov qword [rbx + Symbol.data_type], TYPE_I32
    mov qword [rbx + Symbol.is_mutable], 0
    
    ; Insert into table
    mov rcx, [symtable]
    mov rdx, rbx
    call symtable_insert
    test rax, rax
    jz .fail1
    
    lea rcx, [msg_pass]
    call print
    
    ; Test 2: Lookup 'x'
    lea rcx, [msg_test2]
    call print
    
    mov rcx, [symtable]
    lea rdx, [var_x]
    mov r8, 1
    call symtable_lookup
    test rax, rax
    jz .fail2
    
    lea rcx, [msg_pass]
    call print
    
    ; Test 3: Enter new scope
    lea rcx, [msg_test3]
    call print
    
    call symtable_enter_scope
    test rax, rax
    jz .fail3
    mov [symtable], rax
    
    lea rcx, [msg_pass]
    call print
    
    ; Test 4: Insert 'y' in new scope
    lea rcx, [msg_test4]
    call print
    
    mov rcx, Symbol_size
    call arena_alloc
    mov rbx, rax
    
    lea rcx, [var_y]
    mov [rbx + Symbol.name], rcx
    mov qword [rbx + Symbol.name_len], 1
    mov qword [rbx + Symbol.type], SYM_VARIABLE
    mov qword [rbx + Symbol.data_type], TYPE_I32
    mov qword [rbx + Symbol.is_mutable], 1
    
    mov rcx, [symtable]
    mov rdx, rbx
    call symtable_insert
    test rax, rax
    jz .fail4
    
    lea rcx, [msg_pass]
    call print
    
    ; Test 5: Lookup 'x' from nested scope (should find in parent)
    lea rcx, [msg_test5]
    call print
    
    mov rcx, [symtable]
    lea rdx, [var_x]
    mov r8, 1
    call symtable_lookup
    test rax, rax
    jz .fail5
    
    lea rcx, [msg_pass]
    call print
    
    ; Test 6: Exit scope
    lea rcx, [msg_test6]
    call print
    
    call symtable_exit_scope
    mov [symtable], rax
    
    lea rcx, [msg_pass]
    call print
    
    ; Test 7: Lookup 'y' after exiting scope (should not find)
    lea rcx, [msg_test7]
    call print
    
    mov rcx, [symtable]
    lea rdx, [var_y]
    mov r8, 1
    call symtable_lookup
    test rax, rax
    jnz .fail7  ; Should NOT find y
    
    lea rcx, [msg_pass]
    call print
    
    ; Success
    lea rcx, [msg_summary]
    call print
    
    ; Wait for Enter key
    lea rcx, [msg_pause]
    call print
    
    mov rcx, [stdin]
    lea rdx, [rbp - 16]
    mov r8, 1
    lea r9, [bytes_written]
    push 0
    call ReadConsoleA
    pop rax
    
    xor rcx, rcx
    call ExitProcess
    
.fail1:
    lea rcx, [msg_fail]
    call print
    jmp .error
    
.fail2:
    lea rcx, [msg_fail]
    call print
    jmp .error
    
.fail3:
    lea rcx, [msg_fail]
    call print
    jmp .error
    
.fail4:
    lea rcx, [msg_fail]
    call print
    jmp .error
    
.fail5:
    lea rcx, [msg_fail]
    call print
    jmp .error
    
.fail7:
    lea rcx, [msg_fail]
    call print
    jmp .error
    
.error:
    mov rcx, 1
    call ExitProcess

print:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push r12
    
    mov r12, rcx
    xor rbx, rbx
    
.len:
    cmp byte [r12 + rbx], 0
    je .write
    inc rbx
    jmp .len
    
.write:
    test rbx, rbx
    jz .done
    
    mov rcx, [stdout]
    mov rdx, r12
    mov r8, rbx
    lea r9, [bytes_written]
    xor rax, rax
    mov [rsp + 32], rax
    call WriteFile
    
.done:
    pop r12
    pop rbx
    add rsp, 32
    pop rbp
    ret
