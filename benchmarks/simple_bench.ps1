# Flash Compiler - Simple Benchmark Script
# Basic performance testing with correct PowerShell syntax

param(
    [int]$Iterations = 3,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

# Configuration
$FlashCompiler = "..\build\flash.exe"
$GccCompiler = "gcc.exe"

function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

function Test-CompilerExists {
    param([string]$CompilerPath)

    if ($CompilerPath.StartsWith("..")) {
        return Test-Path $CompilerPath
    } else {
        try {
            $null = Get-Command $CompilerPath -ErrorAction SilentlyContinue
            return $?
        } catch {
            return $false
        }
    }
}

function Test-CompilationSpeed {
    Write-Status "Flash Compiler Compilation Speed Test" "Yellow"
    Write-Host "=====================================" -ForegroundColor Yellow

    $testFile = "programs\flash\fibonacci.fl"
    $cTestFile = "programs\c\fibonacci.c"

    if (!(Test-Path $testFile)) {
        Write-Host "Test file not found: $testFile" -ForegroundColor Red
        return
    }

    # Test Flash compiler
    if (Test-CompilerExists $FlashCompiler) {
        Write-Status "Testing Flash compilation speed..." "Cyan"

        $flashTimes = @()
        for ($i = 1; $i -le $Iterations; $i++) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            try {
                $process = Start-Process -FilePath $FlashCompiler -ArgumentList @($testFile, "-o", "temp_flash.exe") -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
                $stopwatch.Stop()

                if ($process -and $process.ExitCode -eq 0) {
                    $flashTimes += $stopwatch.ElapsedMilliseconds
                    if ($Verbose) {
                        Write-Host "  Iteration $i : $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Gray
                    }
                } else {
                    Write-Host "  Iteration $i : Failed" -ForegroundColor Red
                }
            } catch {
                $stopwatch.Stop()
                Write-Host "  Iteration $i : Error" -ForegroundColor Red
            }

            # Clean up
            if (Test-Path "temp_flash.exe") {
                Remove-Item "temp_flash.exe" -Force -ErrorAction SilentlyContinue
            }
        }

        if ($flashTimes.Count -gt 0) {
            $flashAvg = [math]::Round(($flashTimes | Measure-Object -Average).Average, 2)
            Write-Host "Flash average: $flashAvg ms" -ForegroundColor Green
            $flashSuccess = $true
        } else {
            Write-Host "Flash: No successful compilations" -ForegroundColor Red
            $flashSuccess = $false
            $flashAvg = 0
        }
    } else {
        Write-Host "Flash compiler not available: $FlashCompiler" -ForegroundColor Red
        $flashSuccess = $false
        $flashAvg = 0
    }

    # Test GCC compiler (if available)
    if ((Test-Path $cTestFile) -and (Test-CompilerExists $GccCompiler)) {
        Write-Status "Testing GCC -O0 compilation speed..." "Cyan"

        $gccTimes = @()
        for ($i = 1; $i -le $Iterations; $i++) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            try {
                $process = Start-Process -FilePath $GccCompiler -ArgumentList @($cTestFile, "-O0", "-o", "temp_gcc.exe") -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
                $stopwatch.Stop()

                if ($process -and $process.ExitCode -eq 0) {
                    $gccTimes += $stopwatch.ElapsedMilliseconds
                    if ($Verbose) {
                        Write-Host "  Iteration $i : $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Gray
                    }
                } else {
                    Write-Host "  Iteration $i : Failed" -ForegroundColor Red
                }
            } catch {
                $stopwatch.Stop()
                Write-Host "  Iteration $i : Error" -ForegroundColor Red
            }

            # Clean up
            if (Test-Path "temp_gcc.exe") {
                Remove-Item "temp_gcc.exe" -Force -ErrorAction SilentlyContinue
            }
        }

        if ($gccTimes.Count -gt 0) {
            $gccAvg = [math]::Round(($gccTimes | Measure-Object -Average).Average, 2)
            Write-Host "GCC -O0 average: $gccAvg ms" -ForegroundColor Green

            # Compare speeds
            if ($flashSuccess -and $gccAvg -gt 0 -and $flashAvg -gt 0) {
                $speedup = [math]::Round($gccAvg / $flashAvg, 2)
                Write-Host ""
                Write-Host "Speed comparison:" -ForegroundColor Yellow
                if ($speedup -gt 1) {
                    Write-Host "Flash is $speedup x faster than GCC -O0" -ForegroundColor Green
                } else {
                    $slower = [math]::Round(1 / $speedup, 2)
                    Write-Host "Flash is $slower x slower than GCC -O0" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "GCC: No successful compilations" -ForegroundColor Red
        }
    } else {
        if (!(Test-Path $cTestFile)) {
            Write-Host "C test file not found: $cTestFile" -ForegroundColor Yellow
        }
        if (!(Test-CompilerExists $GccCompiler)) {
            Write-Host "GCC compiler not available" -ForegroundColor Yellow
        }
    }
}

function Test-RuntimePerformance {
    Write-Status "Flash Compiler Runtime Performance Test" "Yellow"
    Write-Host "=======================================" -ForegroundColor Yellow

    $testFile = "programs\flash\fibonacci.fl"
    $cTestFile = "programs\c\fibonacci.c"

    # Compile Flash version
    $flashExe = "temp_flash_runtime.exe"
    $flashCompiled = $false

    if ((Test-CompilerExists $FlashCompiler) -and (Test-Path $testFile)) {
        Write-Status "Compiling Flash version..." "Cyan"
        try {
            $process = Start-Process -FilePath $FlashCompiler -ArgumentList @($testFile, "-o", $flashExe) -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
            $flashCompiled = $process -and $process.ExitCode -eq 0 -and (Test-Path $flashExe)

            if ($process -and $process.ExitCode -eq 0 -and !(Test-Path $flashExe)) {
                Write-Host "  Note: Flash compiler succeeded but no output file created (stub implementation)" -ForegroundColor Yellow
            }
        } catch {
            $flashCompiled = $false
        }
    }

    # Compile GCC version
    $gccExe = "temp_gcc_runtime.exe"
    $gccCompiled = $false

    if ((Test-CompilerExists $GccCompiler) -and (Test-Path $cTestFile)) {
        Write-Status "Compiling GCC -O3 version..." "Cyan"
        try {
            $process = Start-Process -FilePath $GccCompiler -ArgumentList @($cTestFile, "-O3", "-o", $gccExe) -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
            $gccCompiled = $process -and $process.ExitCode -eq 0 -and (Test-Path $gccExe)
        } catch {
            $gccCompiled = $false
        }
    }

    # Test Flash runtime
    if ($flashCompiled) {
        Write-Status "Testing Flash runtime performance..." "Cyan"

        $flashTimes = @()
        for ($i = 1; $i -le $Iterations; $i++) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $process = Start-Process -FilePath $flashExe -NoNewWindow -Wait -PassThru -RedirectStandardOutput "temp_out.txt" -RedirectStandardError "temp_err.txt" -ErrorAction SilentlyContinue
                $stopwatch.Stop()

                if ($process -and $process.ExitCode -eq 0) {
                    $flashTimes += $stopwatch.ElapsedMilliseconds
                    if ($Verbose) {
                        Write-Host "  Iteration $i : $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Gray
                    }
                }
            } catch {
                $stopwatch.Stop()
            }
        }

        if ($flashTimes.Count -gt 0) {
            $flashAvg = [math]::Round(($flashTimes | Measure-Object -Average).Average, 2)
            Write-Host "Flash runtime average: $flashAvg ms" -ForegroundColor Green
        }

        Remove-Item $flashExe -Force -ErrorAction SilentlyContinue
    } else {
        if ((Test-CompilerExists $FlashCompiler) -and (Test-Path $testFile)) {
            Write-Host "Flash compiler is stub implementation (no executable output)" -ForegroundColor Yellow
        } else {
            Write-Host "Failed to compile Flash version" -ForegroundColor Red
        }
        $flashAvg = 0
    }

    # Test GCC runtime
    if ($gccCompiled) {
        Write-Status "Testing GCC -O3 runtime performance..." "Cyan"

        $gccTimes = @()
        for ($i = 1; $i -le $Iterations; $i++) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $process = Start-Process -FilePath $gccExe -NoNewWindow -Wait -PassThru -RedirectStandardOutput "temp_out.txt" -RedirectStandardError "temp_err.txt" -ErrorAction SilentlyContinue
                $stopwatch.Stop()

                if ($process -and $process.ExitCode -eq 0) {
                    $gccTimes += $stopwatch.ElapsedMilliseconds
                    if ($Verbose) {
                        Write-Host "  Iteration $i : $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Gray
                    }
                }
            } catch {
                $stopwatch.Stop()
            }
        }

        if ($gccTimes.Count -gt 0) {
            $gccAvg = [math]::Round(($gccTimes | Measure-Object -Average).Average, 2)
            Write-Host "GCC -O3 runtime average: $gccAvg ms" -ForegroundColor Green

            # Compare performance
            if ($flashAvg -gt 0 -and $gccAvg -gt 0) {
                $ratio = [math]::Round($flashAvg / $gccAvg, 3)
                Write-Host ""
                Write-Host "Runtime comparison:" -ForegroundColor Yellow
                if ($ratio -le 1.05) {
                    Write-Host "Flash performance: $ratio x of GCC -O3 (Excellent - within 5%)" -ForegroundColor Green
                } elseif ($ratio -le 1.20) {
                    Write-Host "Flash performance: $ratio x of GCC -O3 (Good - within 20%)" -ForegroundColor Yellow
                } else {
                    Write-Host "Flash performance: $ratio x of GCC -O3 (Needs optimization)" -ForegroundColor Red
                }
            }
        }

        Remove-Item $gccExe -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "Failed to compile GCC version" -ForegroundColor Red
    }

    # Clean temp files
    @("temp_out.txt", "temp_err.txt") | ForEach-Object {
        if (Test-Path $_) { Remove-Item $_ -Force -ErrorAction SilentlyContinue }
    }
}

function Show-SystemInfo {
    Write-Status "Flash Compiler Simple Benchmark" "Magenta"
    Write-Host "===============================" -ForegroundColor Magenta

    Write-Host "System: Windows" -ForegroundColor White
    Write-Host "PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor White
    Write-Host "Test iterations: $Iterations" -ForegroundColor White

    # Compiler availability
    Write-Host "Compilers:" -ForegroundColor White
    if (Test-Path $FlashCompiler) {
        Write-Host "  Flash: Available ($FlashCompiler)" -ForegroundColor Green
    } else {
        Write-Host "  Flash: Not available ($FlashCompiler)" -ForegroundColor Red
    }

    if (Test-CompilerExists $GccCompiler) {
        Write-Host "  GCC: Available" -ForegroundColor Green
    } else {
        Write-Host "  GCC: Not available" -ForegroundColor Yellow
    }

    Write-Host ""
}

# Main execution
Show-SystemInfo

Write-Host "Running compilation speed test..." -ForegroundColor Cyan
Test-CompilationSpeed

Write-Host ""
Write-Host "Running runtime performance test..." -ForegroundColor Cyan
Test-RuntimePerformance

Write-Host ""
Write-Host "Simple benchmark completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Current Flash Compiler Status:" -ForegroundColor Yellow
Write-Host "  Flash compiler is currently a stub implementation" -ForegroundColor Gray
Write-Host "  Compilation timing is measured, but no executables are generated" -ForegroundColor Gray
Write-Host "  Framework is ready for testing when compiler implementation is complete" -ForegroundColor Gray
Write-Host ""
Write-Host "For more detailed benchmarks:" -ForegroundColor Yellow
Write-Host "  Check the tools\ directory for advanced scripts" -ForegroundColor Gray
Write-Host "  Run validate.ps1 to verify framework setup" -ForegroundColor Gray
