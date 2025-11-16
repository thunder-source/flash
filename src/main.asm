; Main entry point for Flash Compiler
global main
extern ExitProcess

section .text
main:
    ; TODO: Add actual compiler logic here
    
    ; For now, just exit with code 0
    xor eax, eax
    ret
