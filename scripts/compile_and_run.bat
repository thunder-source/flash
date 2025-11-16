@echo off
setlocal enabledelayedexpansion

set "COMPILER_PATH=C:\Program Files (x86)\Flash Compiler\flash_compiler.exe"
set "EXAMPLES_DIR=C:\Program Files (x86)\Flash Compiler\examples"
set "OUTPUT_DIR=F:\flash\bin"
set "LOG_FILE=compiler_test_results.txt"

echo Testing Flash Compiler with example files > "%LOG_FILE%"
echo =================================== >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

for /r "%EXAMPLES_DIR%" %%f in (*.fl) do (
    set "output_file=%%~nf.exe"
    
    echo Testing: %%~nxf
    echo ----------------------------
    echo File: %%~nxf
    echo ----------------------------
    
    echo Testing: %%~nxf >> "%LOG_FILE%"
    echo ---------------------------- >> "%LOG_FILE%"
    echo File content: >> "%LOG_FILE%"
    echo ---------------------------- >> "%LOG_FILE%"
    type "%%f" >> "%LOG_FILE%"
    echo. >> "%LOG_FILE%"
    
    echo Compiling...
    echo Compiling... >> "%LOG_FILE%"
    "%COMPILER_PATH%" "%%f" -o "%OUTPUT_DIR%\!output_file!"
    
    if errorlevel 1 (
        echo [ERROR] Compilation failed >> "%LOG_FILE%"
        echo [ERROR] Compilation failed. Press any key to continue...
        pause >nul
    ) else (
        echo [SUCCESS] Compiled successfully
        echo [SUCCESS] Compiled successfully >> "%LOG_FILE%"
        echo. >> "%LOG_FILE%"
        
        if exist "%OUTPUT_DIR%\!output_file!" (
            echo Running program:
            echo ----------------------------
            echo Running program: >> "%LOG_FILE%"
            echo ---------------------------- >> "%LOG_FILE%"
            
            cd /d "%OUTPUT_DIR%"
            call "!output_file!"
            cd /d "%~dp0"
            
            echo. >> "%LOG_FILE%"
            echo [SUCCESS] Program executed >> "%LOG_FILE%"
        )
    )
    
    echo.
    echo ===================================
    echo. >> "%LOG_FILE%"
    echo =================================== >> "%LOG_FILE%"
    echo. >> "%LOG_FILE%"
    pause
)

echo.
echo Test completed. Results saved to %LOG_FILE%
echo. >> "%LOG_FILE%"
echo Test completed. >> "%LOG_FILE%"

pause