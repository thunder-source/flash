@echo off
REM Install script for Chocolatey package
REM This script is called by Chocolatey to install Flash

set INSTALL_DIR=%ChocolateyInstall%\lib\flash-compiler\tools\flash

REM Extract the release zip to the tools directory
REM Note: The zip is pre-extracted by Chocolatey into %ChocolateyInstallArgument%

setlocal enabledelayedexpansion

REM Create Flash bin directory in Chocolatey's bin folder for PATH access
if not exist "%ChocolateyInstall%\bin" mkdir "%ChocolateyInstall%\bin"

REM Copy flash.exe to Chocolatey bin folder
copy /Y "%INSTALL_DIR%\bin\flash.exe" "%ChocolateyInstall%\bin\flash.exe"

if %ERRORLEVEL% EQU 0 (
    echo Flash Compiler v0.1.0 installed successfully
    echo Run 'flash' from command line
) else (
    echo Installation failed with error %ERRORLEVEL%
    exit /b 1
)
