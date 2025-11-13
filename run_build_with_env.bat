@echo off
echo Looking for Visual Studio installation...

REM Try common VS installation paths
set VS_PATHS[0]="C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
set VS_PATHS[1]="C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat"
set VS_PATHS[2]="C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat"
set VS_PATHS[3]="C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
set VS_PATHS[4]="C:\Program Files\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat"
set VS_PATHS[5]="C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"

set FOUND=0
for /L %%i in (0,1,5) do (
    if exist !VS_PATHS[%%i]! (
        echo Found Visual Studio at: !VS_PATHS[%%i]!
        call !VS_PATHS[%%i]! x64
        set FOUND=1
        goto :build
    )
)

if %FOUND%==0 (
    echo ERROR: Could not find Visual Studio installation
    echo Please run this from "Developer Command Prompt for VS"
    echo Or manually set up the environment with vcvarsall.bat
    pause
    exit /b 1
)

:build
echo.
echo Building and running tests...
echo.
call build_test.bat
if errorlevel 1 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo Running tests...
flash_test.exe
pause
