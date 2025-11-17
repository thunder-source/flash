; ============================================================================
; Flash Compiler - Front-end Regression Test
; ============================================================================

bits 64
default rel

extern arena_init
extern lexer_init
extern parser_init
extern parser_parse
extern ExitProcess
extern GetStdHandle
extern WriteFile

%define STD_OUTPUT_HANDLE -11

section .data
    msg_intro db "Running frontend regression tests...", 13, 10, 0
    msg_pass db "All frontend regression tests passed", 13, 10, 0
    msg_case_prefix db "[case] ", 0
    msg_case_running db " ... ", 0
    msg_case_ok db "ok", 13, 10, 0
    msg_case_fail db "FAILED ", 0
    msg_fail_prefix db "Frontend regression failed on ", 0
    msg_arena_fail db "Failed to initialize arena allocator", 13, 10, 0
    newline db 13, 10, 0

    bytes_written dd 0

    case_hello_label db "examples/hello.fl", 0
    case_hello_source:
        incbin "../../examples/hello.fl"
        db 0

    case_control_label db "examples/control_flow.fl", 0
    case_control_source:
        incbin "../../examples/control_flow.fl"
        db 0

    cases:
        dq case_hello_source
        dq case_hello_label
        dq case_control_source
        dq case_control_label
    cases_end:
%assign CASE_COUNT ((cases_end - cases) / 16)

section .bss
    stdout        resq 1
    current_label resq 1
    case_cursor   resq 1

section .text
global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout], rax

    lea rcx, [msg_intro]
    call print_cstring

    xor rcx, rcx
    call arena_init
    test rax, rax
    jz .arena_fail

    lea rax, [cases]
    mov [case_cursor], rax
    mov ecx, CASE_COUNT

.case_loop:
    test ecx, ecx
    jz .all_passed

    mov rax, [case_cursor]
    mov r8, [rax]        ; source pointer
    mov r9, [rax + 8]    ; label pointer
    mov [current_label], r9

    lea rcx, [msg_case_prefix]
    call print_cstring
    mov rcx, r9
    call print_cstring
    lea rcx, [msg_case_running]
    call print_cstring

    mov rcx, r8
    call lexer_init
    test rax, rax
    jz .case_fail
    mov r10, rax

    mov rcx, r10
    call parser_init
    test rax, rax
    jz .case_fail
    mov r11, rax

    mov rcx, r11
    call parser_parse
    test rax, rax
    jz .case_fail

    lea rcx, [msg_case_ok]
    call print_cstring

    mov rax, [case_cursor]
    add rax, 16
    mov [case_cursor], rax
    dec ecx
    jmp .case_loop

.all_passed:
    lea rcx, [msg_pass]
    call print_cstring
    xor rcx, rcx
    call ExitProcess

.case_fail:
    lea rcx, [msg_case_fail]
    call print_cstring
    mov rcx, [current_label]
    call print_cstring
    lea rcx, [newline]
    call print_cstring
    mov rcx, 1
    call ExitProcess

.arena_fail:
    lea rcx, [msg_arena_fail]
    call print_cstring
    mov rcx, 1
    call ExitProcess

; ============================================================================
; print_cstring - Print null-terminated string
;   RCX = pointer
; ============================================================================
print_cstring:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx

    mov rbx, rcx
    xor rdx, rdx

.len_loop:
    cmp byte [rbx + rdx], 0
    je .write
    inc rdx
    jmp .len_loop

.write:
    test rdx, rdx
    jz .done
    mov rcx, [stdout]
    mov r8, rdx
    mov rdx, rbx
    lea r9, [bytes_written]
    xor rax, rax
    mov [rsp + 32], rax
    call WriteFile

.done:
    pop rbx
    add rsp, 32
    pop rbp
    ret

