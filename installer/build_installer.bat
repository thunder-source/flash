@echo off
:: f:\flash\installer\build_installer.bat
setlocal EnableDelayedExpansion

echo Building Flash Compiler Installer...
echo ===================================

:: Build the compiler in Release mode
echo.
echo [1/3] Building compiler in Release mode...
cd /d "%~dp0.."
call scripts\build_prod.bat release
if errorlevel 1 (
    echo ERROR: Failed to build the compiler
    exit /b 1
)

:: Create dist directory if it doesn't exist
if not exist "dist" mkdir "dist"

:: Verify the main executable was built
if not exist "build\Release\bin\flash_compiler.exe" (
    echo ERROR: Main executable not found at build\Release\bin\flash_compiler.exe
    exit /b 1
)

:: Compile the installer
echo.
echo [2/3] Creating installer...

:: Direct path to Inno Setup
set "INNO_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

:: Verify the file exists (use delayed expansion here)
if not exist "!INNO_PATH!" (
    echo ERROR: Inno Setup not found at: !INNO_PATH!
    echo Please install Inno Setup from: https://jrsoftware.org/isdl.php
    pause
    exit /b 1
)

echo Using Inno Setup at: !INNO_PATH!

:: Run Inno Setup with the full path in quotes (delayed expansion)
start "" /wait "!INNO_PATH!" "%~dp0setup_compiler.iss"
if errorlevel 1 (
    echo ERROR: Failed to create installer. Exit code: %ERRORLEVEL%
    echo Please try running this script as Administrator
    pause
    exit /b 1
)

:: Create portable package
echo.
echo [3/3] Creating portable package...
set PORTABLE_DIR=dist\FlashCompiler_Portable
if exist "%PORTABLE_DIR%" rmdir /s /q "%PORTABLE_DIR%"
mkdir "%PORTABLE_DIR%"

:: Copy only the necessary files
xcopy /Y "build\Release\bin\flash_compiler.exe" "%PORTABLE_DIR%\" >nul
xcopy /Y "build\Release\bin\*.dll" "%PORTABLE_DIR%\" 2>nul
if exist "docs" xcopy /E /Y "docs" "%PORTABLE_DIR%\docs\"
if exist "examples" xcopy /E /Y "examples" "%PORTABLE_DIR%\examples\"

echo Creating ZIP archive...
powershell -Command "Compress-Archive -Path '%PORTABLE_DIR%\*' -DestinationPath 'dist\FlashCompiler_Portable.zip' -Force" 2>nul

echo.
echo ===================================
echo Build completed successfully!
echo.
echo Installer: dist\FlashCompiler_Setup.exe
echo Portable:  dist\FlashCompiler_Portable.zip
echo ===================================
pause
