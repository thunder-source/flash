; ============================================================================
; Flash Compiler - File I/O Utilities
; ============================================================================
; Implements file reading and writing functions
; ============================================================================

bits 64
default rel

; Windows API
extern CreateFileA
extern ReadFile
extern WriteFile
extern CloseHandle
extern GetFileSize
extern GetLastError
extern LocalAlloc
extern LocalFree

; Constants
%define GENERIC_READ      0x80000000
%define GENERIC_WRITE     0x40000000
%define FILE_SHARE_READ   0x00000001
%define FILE_SHARE_WRITE  0x00000002
%define OPEN_EXISTING     0x00000003
%define CREATE_ALWAYS     0x00000002
%define FILE_ATTRIBUTE_NORMAL 0x00000080
%define INVALID_HANDLE_VALUE -1
%define INVALID_FILE_SIZE -1

; ============================================================================
; Read entire file into memory
; Arguments:
;   rcx = filename (null-terminated)
; Returns:
;   rax = pointer to file contents (must be freed by caller)
;   rdx = file size in bytes
; ============================================================================
global file_read_all
file_read_all:
    push rbp
    mov rbp, rsp
    sub rsp, 32 + 8*5    ; Shadow space + 5 parameters + local vars

    ; Save non-volatile registers
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14

    ; Initialize variables
    mov [rbp-8], rcx     ; Save filename
    mov qword [rbp-16], 0 ; File handle = 0
    mov qword [rbp-24], 0 ; File size = 0
    mov qword [rbp-32], 0 ; Buffer pointer = 0

    ; Open the file
    mov rcx, [rbp-8]     ; lpFileName
    mov rdx, GENERIC_READ ; dwDesiredAccess
    xor r8, r8           ; dwShareMode
    xor r9, r9           ; lpSecurityAttributes
    mov qword [rsp+32], OPEN_EXISTING ; dwCreationDisposition
    mov qword [rsp+40], FILE_ATTRIBUTE_NORMAL ; dwFlagsAndAttributes
    mov qword [rsp+48], 0 ; hTemplateFile
    call CreateFileA
    
    cmp rax, INVALID_HANDLE_VALUE
    je .error
    mov [rbp-16], rax    ; Save file handle

    ; Get file size
    mov rcx, rax         ; hFile
    xor rdx, rdx         ; lpFileSizeHigh
    call GetFileSize
    cmp rax, INVALID_FILE_SIZE
    je .close_error
    mov [rbp-24], rax    ; Save file size

    ; Allocate memory for file contents (+1 for null terminator)
    mov rcx, rax
    add rcx, 1
    mov rdx, 0x40        ; LMEM_ZEROINIT | LMEM_MOVEABLE
    call LocalAlloc
    test rax, rax
    jz .close_error
    mov [rbp-32], rax    ; Save buffer pointer

    ; Read file contents
    mov rcx, [rbp-16]    ; hFile
    mov rdx, rax         ; lpBuffer
    mov r8, [rbp-24]     ; nNumberOfBytesToRead
    lea r9, [rbp-40]     ; lpNumberOfBytesRead
    mov qword [rsp+32], 0 ; lpOverlapped
    call ReadFile
    test eax, eax
    jz .free_error

    ; Null-terminate the buffer
    mov rcx, [rbp-32]
    add rcx, [rbp-24]
    mov byte [rcx], 0

    ; Return values
    mov rax, [rbp-32]    ; buffer pointer
    mov rdx, [rbp-24]    ; file size

.cleanup:
    ; Close file handle if it was opened
    mov rcx, [rbp-16]
    test rcx, rcx
    jz .done
    call CloseHandle
    jmp .done

.close_error:
    ; Get last error code
    call GetLastError
    mov r12, rax
    
    ; Close file handle
    mov rcx, [rbp-16]
    test rcx, rcx
    jz .free_error
    call CloseHandle
    mov [rbp-16], 0

.free_error:
    ; Free allocated memory if any
    mov rcx, [rbp-32]
    test rcx, rcx
    jz .error
    call LocalFree
    mov [rbp-32], 0

.error:
    ; Return NULL and 0 on error
    xor rax, rax
    xor rdx, rdx

.done:
    ; Restore non-volatile registers
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    
    mov rsp, rbp
    pop rbp
    ret

; ============================================================================
; Write data to file
; Arguments:
;   rcx = filename (null-terminated)
;   rdx = data buffer
;   r8 = data size in bytes
; Returns:
;   rax = 0 on success, non-zero on error
; ============================================================================
global file_write_all
file_write_all:
    push rbp
    mov rbp, rsp
    sub rsp, 32 + 8*5    ; Shadow space + 5 parameters + local vars

    ; Save non-volatile registers
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14

    ; Initialize variables
    mov [rbp-8], rcx     ; filename
    mov [rbp-16], rdx    ; buffer
    mov [rbp-24], r8     ; size
    mov qword [rbp-32], 0 ; file handle

    ; Create the file
    mov rcx, [rbp-8]     ; lpFileName
    mov rdx, GENERIC_WRITE ; dwDesiredAccess
    mov r8, 0            ; dwShareMode
    xor r9, r9           ; lpSecurityAttributes
    mov qword [rsp+32], CREATE_ALWAYS ; dwCreationDisposition
    mov qword [rsp+40], FILE_ATTRIBUTE_NORMAL ; dwFlagsAndAttributes
    mov qword [rsp+48], 0 ; hTemplateFile
    call CreateFileA
    
    cmp rax, INVALID_HANDLE_VALUE
    je .error
    mov [rbp-32], rax    ; Save file handle

    ; Write data to file
    mov rcx, rax         ; hFile
    mov rdx, [rbp-16]    ; lpBuffer
    mov r8, [rbp-24]     ; nNumberOfBytesToWrite
    lea r9, [rbp-40]     ; lpNumberOfBytesWritten
    mov qword [rsp+32], 0 ; lpOverlapped
    call WriteFile
    test eax, eax
    jz .close_error

    ; Close the file
    mov rcx, [rbp-32]
    call CloseHandle
    mov [rbp-32], 0

    ; Return success
    xor rax, rax
    jmp .done

.close_error:
    ; Get last error code
    call GetLastError
    mov r12, rax
    
    ; Close file handle
    mov rcx, [rbp-32]
    test rcx, rcx
    jz .error
    call CloseHandle
    mov [rbp-32], 0

.error:
    ; Return error code
    mov rax, 1

.done:
    ; Restore non-volatile registers
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    
    mov rsp, rbp
    pop rbp
    ret
