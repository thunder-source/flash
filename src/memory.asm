; ============================================================================
; Flash Compiler - Memory Management
; ============================================================================
; Simple arena-based memory allocator for AST nodes
; Fast allocation, bulk deallocation
; ============================================================================

bits 64
default rel

extern VirtualAlloc
extern VirtualFree

%define MEM_COMMIT              0x1000
%define MEM_RESERVE             0x2000
%define PAGE_READWRITE          0x04
%define MEM_RELEASE             0x8000

; ============================================================================
; Arena Structure
; ============================================================================
struc Arena
    .base:      resq 1      ; Base address of arena
    .size:      resq 1      ; Total size of arena
    .offset:    resq 1      ; Current allocation offset
endstruc

; ============================================================================
; Data Section
; ============================================================================
section .data
    default_arena_size  dq  1048576  ; 1 MB default

section .bss
    global_arena:   resb Arena_size

; ============================================================================
; Code Section
; ============================================================================
section .text

global arena_init
global arena_alloc
global arena_free
global arena_reset
global malloc
global free

; ============================================================================
; arena_init - Initialize arena allocator
; Parameters:
;   RCX = size of arena (or 0 for default)
; Returns:
;   RAX = pointer to arena structure (or 0 on failure)
; ============================================================================
arena_init:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    
    ; Use default size if 0
    test rcx, rcx
    jnz .use_provided_size
    mov rcx, [default_arena_size]
    
.use_provided_size:
    mov rbx, rcx  ; Save size
    
    ; Allocate memory using VirtualAlloc
    xor rcx, rcx  ; lpAddress = NULL
    mov rdx, rbx  ; dwSize
    mov r8, MEM_COMMIT | MEM_RESERVE  ; flAllocationType
    mov r9, PAGE_READWRITE  ; flProtect
    call VirtualAlloc
    
    test rax, rax
    jz .error
    
    ; Initialize arena structure
    lea r8, [global_arena]
    mov [r8 + Arena.base], rax
    mov [r8 + Arena.size], rbx
    mov qword [r8 + Arena.offset], 0
    
    mov rax, r8
    
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
; arena_alloc - Allocate memory from arena
; Parameters:
;   RCX = size in bytes
; Returns:
;   RAX = pointer to allocated memory (or 0 on failure)
; ============================================================================
arena_alloc:
    push rbp
    mov rbp, rsp
    
    ; Align size to 16 bytes
    add rcx, 15
    and rcx, ~15
    
    lea r8, [global_arena]
    
    ; Check if enough space
    mov rax, [r8 + Arena.offset]
    mov rdx, rax
    add rdx, rcx
    cmp rdx, [r8 + Arena.size]
    ja .error
    
    ; Allocate
    mov r9, [r8 + Arena.base]
    add r9, rax
    mov [r8 + Arena.offset], rdx
    
    mov rax, r9
    pop rbp
    ret
    
.error:
    xor rax, rax
    pop rbp
    ret

; ============================================================================
; arena_reset - Reset arena (free all allocations)
; Parameters:
;   None
; Returns:
;   None
; ============================================================================
arena_reset:
    push rbp
    mov rbp, rsp
    
    lea rax, [global_arena]
    mov qword [rax + Arena.offset], 0
    
    pop rbp
    ret

; ============================================================================
; arena_free - Free entire arena
; Parameters:
;   None
; Returns:
;   None
; ============================================================================
arena_free:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    lea rax, [global_arena]
    mov rcx, [rax + Arena.base]
    test rcx, rcx
    jz .done
    
    xor rdx, rdx  ; dwSize = 0
    mov r8, MEM_RELEASE  ; dwFreeType
    call VirtualFree
    
    lea rax, [global_arena]
    mov qword [rax + Arena.base], 0
    mov qword [rax + Arena.size], 0
    mov qword [rax + Arena.offset], 0
    
.done:
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; malloc - Standard malloc interface (uses arena allocator)
; Parameters:
;   RCX = size in bytes
; Returns:
;   RAX = pointer to allocated memory (or 0 on failure)
; ============================================================================
malloc:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Check if arena is initialized
    lea r8, [global_arena]
    mov rax, [r8 + Arena.base]
    test rax, rax
    jnz .arena_ready
    
    ; Initialize arena
    push rcx
    xor rcx, rcx
    call arena_init
    pop rcx
    
    test rax, rax
    jz .error
    
.arena_ready:
    call arena_alloc
    
    add rsp, 32
    pop rbp
    ret
    
.error:
    xor rax, rax
    add rsp, 32
    pop rbp
    ret

; ============================================================================
; free - Standard free interface (no-op for arena allocator)
; Parameters:
;   RCX = pointer to memory
; Returns:
;   None
; ============================================================================
free:
    ; No-op for arena allocator
    ; Memory is freed all at once with arena_free
    ret
