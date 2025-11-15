; bin/flash.asm
; Flash compiler CLI entry point
; A minimal stub that returns successfully

section .data
    version_string db "Flash Compiler v0.1.0", 0dh, 0ah, 0
    usage_string db "Usage: flash [options] <input.fl>", 0dh, 0ah, 0

section .text
global main

main:
    ; Prologue
    push rbp
    mov rbp, rsp
    sub rsp, 32                ; Shadow space for Windows x64 calling convention

    ; Just exit with code 0 for now
    xor eax, eax               ; Return code 0
    
    ; Epilogue
    mov rsp, rbp
    pop rbp
    ret
