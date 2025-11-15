# Flash Compiler - Phase 11 Build Script (PowerShell)
# Properly locates Visual Studio Build Tools and builds complete compiler

param(
    [switch]$Clean = $false,
    [switch]$Verbose = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Flash Compiler - Phase 11" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Get current directory
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $ProjectRoot

try {
    # Create build directory
    if (!(Test-Path "build")) {
        New-Item -ItemType Directory -Path "build" | Out-Null
    }

    if ($Clean) {
        Write-Host "[CLEAN] Removing previous build artifacts..." -ForegroundColor Yellow
        Remove-Item "build\*.obj" -ErrorAction SilentlyContinue
        Remove-Item "build\flash.exe" -ErrorAction SilentlyContinue
    }

    Write-Host ""
    Write-Host "[Phase 11] Building complete Flash compiler..." -ForegroundColor Green

    # Find NASM
    $nasm = Get-Command "nasm.exe" -ErrorAction SilentlyContinue
    if (!$nasm) {
        throw "NASM not found in PATH. Please install NASM and add it to PATH."
    }
    Write-Host "Using NASM: $($nasm.Source)" -ForegroundColor DarkGray

    # Find Visual Studio Build Tools linker
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $linkerPath = $null

    if (Test-Path $vsWhere) {
        Write-Host "Finding Visual Studio Build Tools..." -ForegroundColor DarkGray

        # Find latest VS installation
        $vsInstall = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath

        if ($vsInstall) {
            # Look for the linker in the installation
            $toolsDir = Join-Path $vsInstall "VC\Tools\MSVC"
            if (Test-Path $toolsDir) {
                $versions = Get-ChildItem $toolsDir | Sort-Object Name -Descending
                foreach ($version in $versions) {
                    $candidateLinker = Join-Path $version.FullName "bin\Hostx64\x64\link.exe"
                    if (Test-Path $candidateLinker) {
                        $linkerPath = $candidateLinker
                        break
                    }
                }
            }
        }
    }

    # Fallback: search common VS paths manually
    if (!$linkerPath) {
        Write-Host "vswhere not found, searching manually..." -ForegroundColor DarkGray
        $commonPaths = @(
            "${env:ProgramFiles}\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC",
            "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC",
            "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\VC\Tools\MSVC",
            "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC",
            "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC"
        )

        foreach ($basePath in $commonPaths) {
            if (Test-Path $basePath) {
                $versions = Get-ChildItem $basePath | Sort-Object Name -Descending
                foreach ($version in $versions) {
                    $candidateLinker = Join-Path $version.FullName "bin\Hostx64\x64\link.exe"
                    if (Test-Path $candidateLinker) {
                        $linkerPath = $candidateLinker
                        break
                    }
                }
                if ($linkerPath) { break }
            }
        }
    }

    if (!$linkerPath) {
        throw "Visual Studio Build Tools linker not found. Please install Visual Studio Build Tools with C++ support."
    }

    Write-Host "Using linker: $linkerPath" -ForegroundColor DarkGray

    # Build components
    $components = @(
        @{ Name = "CLI interface"; Source = "bin\flash.asm"; Output = "build\flash_bin.obj" },
        @{ Name = "memory management"; Source = "src\utils\memory.asm"; Output = "build\memory.obj" },
        @{ Name = "AST module"; Source = "src\ast.asm"; Output = "build\ast.obj" },
        @{ Name = "lexer"; Source = "src\lexer\lexer.asm"; Output = "build\lexer.obj" },
        @{ Name = "parser"; Source = "src\parser\parser.asm"; Output = "build\parser.obj" },
        @{ Name = "semantic analyzer"; Source = "src\semantic\analyze.asm"; Output = "build\semantic.obj" },
        @{ Name = "IR generator"; Source = "src\ir\ir.asm"; Output = "build\ir.obj" },
        @{ Name = "code generator"; Source = "src\codegen\codegen.asm"; Output = "build\codegen.obj" }
    )

    $step = 1
    foreach ($component in $components) {
        Write-Host "[$step/$($components.Count)] Assembling $($component.Name)..." -ForegroundColor Yellow

        $nasmArgs = @("-f", "win64", $component.Source, "-o", $component.Output)
        if ($Verbose) {
            Write-Host "    Command: nasm $($nasmArgs -join ' ')" -ForegroundColor DarkGray
        }

        & $nasm.Source @nasmArgs

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to assemble $($component.Name)"
        }

        if (!(Test-Path $component.Output)) {
            throw "Output file not created for $($component.Name)"
        }

        $step++
    }

    # Link the final executable
    Write-Host "[$step/$($components.Count + 1)] Linking complete Flash compiler..." -ForegroundColor Yellow

    $objectFiles = @(
        "build\flash_bin.obj",
        "build\memory.obj",
        "build\ast.obj",
        "build\lexer.obj",
        "build\parser.obj",
        "build\semantic.obj",
        "build\ir.obj",
        "build\codegen.obj"
    )

    $libraries = @("kernel32.lib", "user32.lib")

    $linkArgs = @(
        "/subsystem:console",
        "/entry:main",
        "/out:build\flash.exe"
    ) + $objectFiles + $libraries

    if ($Verbose) {
        Write-Host "    Command: link $($linkArgs -join ' ')" -ForegroundColor DarkGray
    }

    & $linkerPath @linkArgs

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to link Flash compiler"
    }

    if (!(Test-Path "build\flash.exe")) {
        throw "Executable not created"
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Phase 11 Build Successful!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Flash Compiler: build\flash.exe" -ForegroundColor White
    Write-Host "Status: Complete compiler integration" -ForegroundColor White
    Write-Host "Next: Run benchmark tests to validate" -ForegroundColor White
    Write-Host ""
    Write-Host "Test with: cd benchmarks && .\simple_bench.ps1" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Green

    # Test the compiler
    if (Test-Path "build\flash.exe") {
        Write-Host ""
        Write-Host "Testing compiler..." -ForegroundColor Yellow
        try {
            $output = & "build\flash.exe" --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Compiler test successful: $output" -ForegroundColor Green
            } else {
                Write-Host "⚠ Compiler test failed with exit code $LASTEXITCODE" -ForegroundColor Yellow
                Write-Host "Output: $output" -ForegroundColor Gray
            }
        } catch {
            Write-Host "⚠ Could not test compiler: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Phase 11 Build Failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check that you have:" -ForegroundColor White
    Write-Host "  - NASM installed and in PATH" -ForegroundColor White
    Write-Host "  - Visual Studio Build Tools installed" -ForegroundColor White
    Write-Host "  - All source files present" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Red

    Pop-Location
    exit 1
}

Pop-Location
exit 0
