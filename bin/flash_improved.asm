; bin/flash_improved.asm
; Flash compiler CLI entry point - Improved stub for benchmarking
; Creates minimal output file to test full compilation pipeline

section .data
    version_string db "Flash Compiler v0.1.0", 0dh, 0ah, 0
    usage_string db "Usage: flash [options] <input.fl>", 0dh, 0ah, 0
    success_msg db "Flash: Compilation successful (stub)", 0dh, 0ah, 0
    error_msg db "Flash: Error - output file creation failed", 0dh, 0ah, 0

    ; Minimal Windows executable header (PE stub)
    ; This creates a tiny executable that just returns 0
    pe_stub_header db 0x4d, 0x5a, 0x90, 0x00  ; MZ header
                   times 60-4 db 0              ; DOS header padding
    pe_signature   db 'PE', 0, 0               ; PE signature

    ; Minimal PE file content (simplified)
    minimal_exe_content:
        ; DOS stub program that prints "This program cannot be run in DOS mode"
        db 0x0e, 0x1f, 0xba, 0x0e, 0x00, 0xb4, 0x09, 0xcd, 0x21, 0xb8, 0x01, 0x4c, 0xcd, 0x21
        db 'This program cannot be run in DOS mode.', 0x0d, 0x0a, 0x24
        times 64 db 0
        ; PE header would go here in a real implementation
        db 0x50, 0x45, 0x00, 0x00  ; PE signature
        ; Minimal machine code that returns 0
        db 0xb8, 0x00, 0x00, 0x00, 0x00  ; mov eax, 0
        db 0xc3                           ; ret

    minimal_exe_size equ $ - minimal_exe_content
    output_filename db "temp_output.exe", 0

section .bss
    input_filename resb 256
    output_filename_arg resb 256
    file_handle resq 1
    bytes_written resq 1

section .text
global main
extern GetStdHandle
extern WriteConsoleA
extern CreateFileA
extern WriteFile
extern CloseHandle
extern GetCommandLineA
extern ExitProcess

main:
    ; Prologue
    push rbp
    mov rbp, rsp
    sub rsp, 64                ; Shadow space + local variables

    ; Get command line arguments (simplified parsing)
    call GetCommandLineA
    ; For now, just create a default output file

    ; Create output file
    lea rcx, [output_filename]
    mov rdx, 0x40000000        ; GENERIC_WRITE
    mov r8, 0                  ; No sharing
    mov r9, 0                  ; No security attributes
    push 0x80                  ; FILE_ATTRIBUTE_NORMAL
    push 2                     ; CREATE_ALWAYS
    push 0                     ; No template
    sub rsp, 32                ; Shadow space
    call CreateFileA
    add rsp, 56                ; Clean up stack

    cmp rax, -1                ; INVALID_HANDLE_VALUE
    je error_exit

    mov [file_handle], rax

    ; Write minimal executable content
    mov rcx, [file_handle]
    lea rdx, [minimal_exe_content]
    mov r8, minimal_exe_size
    lea r9, [bytes_written]
    push 0                     ; No overlapped
    sub rsp, 32                ; Shadow space
    call WriteFile
    add rsp, 40                ; Clean up stack

    ; Close file handle
    mov rcx, [file_handle]
    call CloseHandle

    ; Print success message
    mov rcx, -11               ; STD_OUTPUT_HANDLE
    call GetStdHandle

    mov rcx, rax
    lea rdx, [success_msg]
    mov r8, 37                 ; Message length
    lea r9, [bytes_written]
    push 0                     ; Reserved
    sub rsp, 32                ; Shadow space
    call WriteConsoleA
    add rsp, 40                ; Clean up stack

    ; Success exit
    xor eax, eax               ; Return code 0
    jmp cleanup_exit

error_exit:
    ; Print error message
    mov rcx, -11               ; STD_OUTPUT_HANDLE
    call GetStdHandle

    mov rcx, rax
    lea rdx, [error_msg]
    mov r8, 44                 ; Message length
    lea r9, [bytes_written]
    push 0                     ; Reserved
    sub rsp, 32                ; Shadow space
    call WriteConsoleA
    add rsp, 40                ; Clean up stack

    mov eax, 1                 ; Return code 1 (error)

cleanup_exit:
    ; Epilogue
    mov rsp, rbp
    pop rbp

    ; Exit process with return code
    mov rcx, rax
    call ExitProcess
