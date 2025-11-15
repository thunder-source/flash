@echo off
REM Uninstall script for Chocolatey package

setlocal enabledelayedexpansion

REM Remove flash.exe from Chocolatey bin folder
if exist "%ChocolateyInstall%\bin\flash.exe" (
    del /F /Q "%ChocolateyInstall%\bin\flash.exe"
    echo Removed flash.exe from PATH
)

echo Flash Compiler uninstalled
