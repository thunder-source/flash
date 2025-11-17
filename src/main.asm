; ============================================================================
; Flash Compiler - Main Entry Point
; ============================================================================
; Implements command-line interface and compilation pipeline
; ============================================================================

%include "cli.inc"

; External dependencies
extern ExitProcess

; Compiler components
extern compile_file

; Windows API
extern GetCommandLineA

; Standard library
extern printf
extern fprintf
extern stderr

; ============================================================================
; Data Section
; ============================================================================
section .data
    ; Version information
    version_string     db 'Flash Compiler v0.1.0', 0
    
    ; Help message
    help_msg          db 'Usage: flash [options] <source_file>', 0x0A
             db 'Options:', 0x0A
             db '  -o <file>     Place the output into <file>', 0x0A
             db '  -O<level>     Set optimization level (0-3)', 0x0A
             db '  -v, --version Display version information', 0x0A
             db '  -h, --help    Display this information', 0x0A, 0
    
    ; Error messages
    error_no_input db 'error: no input files', 0x0A, 0
    error_unknown_option db 'error: unknown option %s', 0x0A, 0
    error_invalid_option_arg db 'error: invalid argument for option %s', 0x0A, 0

; ============================================================
; BSS Section
; ============================================================
section .bss
    input_file  resq 1      ; Pointer to input filename
    output_file resq 1      ; Pointer to output filename
    opt_level   resb 1      ; Optimization level (0-3)

; ============================================================
; Text Section
; ============================================================
section .text

; Main entry point
main:
    push rbp
    mov rbp, rsp
    sub rsp, 32 + 8*4    ; Shadow space + 4 parameters
    
    ; Initialize default values
    mov qword [input_file], 0
    mov qword [output_file], 0
    mov byte [opt_level], 0  ; Default optimization level 0
    
    ; Parse command line arguments
    call parse_arguments
    test eax, eax
    jnz .exit
    
    ; Check if input file was provided
    cmp qword [input_file], 0
    jne .compile
    
    ; No input file, show help
    lea rcx, [error_no_input]
    call printf
    lea rcx, [help_msg]
    call printf
    mov eax, 1
    jmp .exit
    
.compile:
    ; Call the compiler with the parsed arguments
    mov rcx, [input_file]
    mov rdx, [output_file]
    movzx r8, byte [opt_level]
    call compile_file
    
    ; Exit with the compiler's return code
    mov eax, eax
    
.exit:
    ; Cleanup and return
    mov rsp, rbp
    pop rbp
    ret

; ============================================================
; Parse command line arguments
; Arguments:
;   None (uses Windows API to get command line)
; Returns:
;   eax = 0 on success, non-zero on error
; ============================================================
parse_arguments:
    push rbp
    mov rbp, rsp
    sub rsp, 32 + 8*5    ; Shadow space + 5 parameters + local vars
    
    ; Get command line
    call GetCommandLineA
    mov rsi, rax         ; rsi = command line string
    
    ; Skip program name (first argument)
    call skip_program_name
    
    ; Parse arguments
.parse_loop:
    lodsb                ; Load next character
    test al, al
    jz .parse_done       ; End of string
    
    cmp al, ' '          ; Skip spaces
    jbe .parse_loop
    
    cmp al, '-'          ; Check for option
    jne .handle_filename
    
    ; Handle option
    lodsb
    cmp al, 'o'          ; -o output file
    je .handle_output
    cmp al, 'O'          ; -O optimization level
    je .handle_optimization
    cmp al, 'v'          ; -v version
    je .handle_version
    cmp al, 'h'          ; -h help
    je .handle_help
    
    ; Handle -- options
    cmp al, '-'          ; Check for --
    jne .unknown_option
    lodsb
    cmp byte [rsi-1], 'v'  ; --version
    je .handle_version
    cmp byte [rsi-1], 'h'  ; --help
    je .handle_help
    
.unknown_option:
    ; Print error for unknown option
    lea rcx, [error_unknown_option]
    dec rsi
    mov rdx, rsi
    call printf
    mov eax, 1
    jmp .done
    
.handle_output:
    ; Skip whitespace after -o
    lodsb
    cmp al, ' '
    jbe .output_missing_arg
    
    ; Save output filename
    dec rsi
    mov [output_file], rsi
    
    ; Skip to next argument
    call skip_to_next_arg
    jmp .parse_loop
    
.output_missing_arg:
    lea rcx, [error_invalid_option_arg]
    mov rdx, [rsi-2]     ; Get the '-o' part
    and rdx, 0x000000000000FFFF
    call printf
    mov eax, 1
    jmp .done
    
.handle_optimization:
    ; Get optimization level (0-3)
    lodsb
    sub al, '0'
    cmp al, 3
    ja .invalid_opt_level
    mov [opt_level], al
    jmp .parse_loop
    
.invalid_opt_level:
    lea rcx, [error_invalid_option_arg]
    mov rdx, [rsi-2]     ; Get the '-O' part
    and rdx, 0x000000000000FFFF
    call printf
    mov eax, 1
    jmp .done
    
.handle_version:
    lea rcx, [version_string]
    call printf
    mov eax, 1
    jmp .done
    
.handle_help:
    lea rcx, [help_msg]
    call printf
    mov eax, 1
    jmp .done
    
.handle_filename:
    ; Save input filename
    dec rsi
    mov [input_file], rsi
    
    ; Skip to next argument
    call skip_to_next_arg
    jmp .parse_loop
    
.parse_done:
    xor eax, eax    ; Success
    
.done:
    mov rsp, rbp
    pop rbp
    ret

; ============================================================
; Skip program name in command line
; Arguments:
;   rsi = pointer to command line string
; Returns:
;   rsi = pointer to first argument
; ============================================================
skip_program_name:
    push rbp
    mov rbp, rsp
    
    ; Skip leading whitespace
.skip_whitespace:
    lodsb
    test al, al
    jz .done
    cmp al, ' '
    jbe .skip_whitespace
    
    ; Skip quoted string
    cmp al, '"'
    je .quoted
    
    ; Skip unquoted string
.unquoted:
    lodsb
    test al, al
    jz .done
    cmp al, ' '
    ja .unquoted
    jmp .done
    
.quoted:
    lodsb
    test al, al
    jz .done
    cmp al, '"'
    jne .quoted
    
.done:
    ; Skip trailing whitespace
    cmp byte [rsi], ' '
    jbe .skip_trailing_whitespace
    ret

.skip_trailing_whitespace:
    inc rsi
    jmp .done

; ============================================================
; Skip to next argument in command line
; Arguments:
;   rsi = pointer to current position in command line
; Returns:
;   rsi = pointer to next argument
; ============================================================
skip_to_next_arg:
    push rbp
    mov rbp, rsp
    
    ; Skip until space or end of string
.skip_loop:
    lodsb
    test al, al
    jz .done
    cmp al, ' '
    ja .skip_loop
    
    ; Skip whitespace
.skip_whitespace:
    lodsb
    test al, al
    jz .done
    cmp al, ' '
    jbe .skip_whitespace
    
    ; Back up to first non-whitespace character
    dec rsi
    
.done:
    pop rbp
    ret
