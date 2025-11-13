@echo off
REM Simple test runner with environment setup
set "LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64"

echo ========================================
echo Building Flash Compiler Tests
echo ========================================
call build_test.bat
if errorlevel 1 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Running Flash Compiler Tests
echo ========================================
flash_test.exe
pause
