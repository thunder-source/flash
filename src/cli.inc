; ============================================================ ; Flash Compiler
- CLI Definitions ; ============================================================
; This file contains constants and function prototypes for the ; command-line
interface of the Flash compiler. ;
============================================================ ;
============================================================ ; Constants ;
============================================================ ; Exit codes
%define EXIT_SUCCESS 0 %define EXIT_FAILURE 1 ; Maximum lengths %define
MAX_FILENAME_LEN 260 ; Windows MAX_PATH %define MAX_CMDLINE_LEN 32767 ; Windows
maximum command line length ;
============================================================ ; Function
Prototypes ; ============================================================ extern
printf ; Compilation functions extern compile_file ; File I/O functions extern
file_read_all extern file_write_all ; Error handling extern print_error extern
print_warning ; ============================================================ ;
Command Line Structure ;
============================================================ struc
CompileOptions .input_file resq 1 ; Pointer to input filename .output_file resq
1 ; Pointer to output filename .opt_level resb 1 ; Optimization level (0-3)
.show_help resb 1 ; Show help flag .show_version resb 1 ; Show version flag
.verbose resb 1 ; Verbose output flag endstruc ;
============================================================ ; End of File ;
============================================================
