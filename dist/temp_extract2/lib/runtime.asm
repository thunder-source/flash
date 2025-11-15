; ============================================================================
; Flash Compiler - Runtime Library
; ============================================================================
; Minimal runtime support for Flash programs
; Provides program startup, exit, and basic infrastructure
; ============================================================================

bits 64
default rel

; ============================================================================
; External Dependencies (Windows API)
; ============================================================================
extern ExitProcess

; ============================================================================
; External References (User code)
; ============================================================================
extern main             ; User's main function

; ============================================================================
; Data Section
; ============================================================================
section .text

; ============================================================================
; Global Exports
; ============================================================================
global _start           ; Entry point for executables
global flash_exit       ; Exit with status code

; ============================================================================
; _start - Program entry point
; This is called by the OS when the program starts
; ============================================================================
_start:
    ; Set up stack frame
    push rbp
    mov rbp, rsp
    sub rsp, 32             ; Shadow space for Windows x64
    
    ; Call user's main function
    ; main() should return i32 in RAX
    call main
    
    ; RAX now contains return value from main
    ; Pass it to exit
    mov rcx, rax            ; Exit code in RCX
    call flash_exit
    
    ; Should never reach here
    int 3                   ; Breakpoint if we somehow continue

; ============================================================================
; flash_exit - Exit program with status code
; Parameters:
;   RCX = exit code (i32)
; ============================================================================
flash_exit:
    ; RCX already has the exit code
    ; Just call Windows ExitProcess
    jmp ExitProcess         ; Tail call, no return

; ============================================================================
; Note: No constructors/destructors for now
; Future enhancements:
; - Global variable initialization
; - Constructor/destructor support
; - Exception handling setup
; - Command line argument parsing
; ============================================================================
