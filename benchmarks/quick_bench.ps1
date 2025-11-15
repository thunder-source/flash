# Flash Compiler - Quick Benchmark Runner
# Fast performance testing for Flash compiler development

param(
    [string]$Test = "compilation",  # compilation, runtime, or both
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

function Test-Compiler {
    param([string]$CompilerPath)
    try {
        $null = Get-Command $CompilerPath -ErrorAction SilentlyContinue
        return $?
    } catch {
        return $false
    }
}

function Quick-CompilationTest {
    Write-Status "Quick Compilation Speed Test" "Yellow"
    Write-Host "=============================" -ForegroundColor Yellow

    $testFile = "programs/flash/fibonacci.fl"
    $cTestFile = "programs/c/fibonacci.c"

    if (!(Test-Path $testFile)) {
        Write-Warning "Test file not found: $testFile"
        return
    }

    # Test Flash compiler
    if (Test-Compiler $FlashCompiler) {
        Write-Status "Testing Flash compilation speed..." "Cyan"

        $flashTimes = @()
        for ($i = 1; $i -le $Iterations; $i++) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $process = Start-Process -FilePath $FlashCompiler -ArgumentList @($testFile, "-o", "temp_flash.exe") -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            if ($process -and $process.ExitCode -eq 0) {
                $flashTimes += $stopwatch.ElapsedMilliseconds
                if ($Verbose) { Write-Host "  Iteration $i`: $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Gray }
            }

            if (Test-Path "temp_flash.exe") { Remove-Item "temp_flash.exe" -Force -ErrorAction SilentlyContinue }
        }

        if ($flashTimes.Count -gt 0) {
            $flashAvg = [math]::Round(($flashTimes | Measure-Object -Average).Average, 2)
            Write-Host "Flash average: ${flashAvg}ms" -ForegroundColor Green
        }
    } else {
        Write-Warning "Flash compiler not available"
        $flashAvg = 0
    }

    # Test GCC for comparison
    if (Test-Path $cTestFile -and (Test-Compiler $GccCompiler)) {
        Write-Status "Testing GCC -O0 compilation speed..." "Cyan"

        $gccTimes = @()
        for ($i = 1; $i -le $Iterations; $i++) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $process = Start-Process -FilePath $GccCompiler -ArgumentList @($cTestFile, "-O0", "-o", "temp_gcc.exe") -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            if ($process -and $process.ExitCode -eq 0) {
                $gccTimes += $stopwatch.ElapsedMilliseconds
                if ($Verbose) { Write-Host "  Iteration $i`: $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Gray }
            }

            if (Test-Path "temp_gcc.exe") { Remove-Item "temp_gcc.exe" -Force -ErrorAction SilentlyContinue }
        }

        if ($gccTimes.Count -gt 0) {
            $gccAvg = [math]::Round(($gccTimes | Measure-Object -Average).Average, 2)
            Write-Host "GCC -O0 average: ${gccAvg}ms" -ForegroundColor Green

            # Compare speeds
            if ($flashAvg -gt 0 -and $gccAvg -gt 0) {
                $speedup = [math]::Round($gccAvg / $flashAvg, 2)
                Write-Host ""
                Write-Host "Speed comparison:" -ForegroundColor Yellow
                if ($speedup > 1) {
                    Write-Host "Flash is ${speedup}x faster than GCC -O0" -ForegroundColor Green
                } else {
                    Write-Host "Flash is $([math]::Round(1/$speedup, 2))x slower than GCC -O0" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Warning "GCC compiler or C test file not available"
    }

    Write-Host ""
}

function Quick-RuntimeTest {
    Write-Status "Quick Runtime Performance Test" "Yellow"
    Write-Host "==============================" -ForegroundColor Yellow

    $testFile = "programs/flash/fibonacci.fl"
    $cTestFile = "programs/c/fibonacci.c"

    # Compile Flash version
    $flashExe = "temp_flash_runtime.exe"
    if (Test-Compiler $FlashCompiler -and (Test-Path $testFile)) {
        Write-Status "Compiling Flash version..." "Cyan"
        $process = Start-Process -FilePath $FlashCompiler -ArgumentList @($testFile, "-o", $flashExe) -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
        $flashCompiled = $process -and $process.ExitCode -eq 0 -and (Test-Path $flashExe)
    } else {
        $flashCompiled = $false
    }

    # Compile GCC version
    $gccExe = "temp_gcc_runtime.exe"
    if (Test-Compiler $GccCompiler -and (Test-Path $cTestFile)) {
        Write-Status "Compiling GCC -O3 version..." "Cyan"
        $process = Start-Process -FilePath $GccCompiler -ArgumentList @($cTestFile, "-O3", "-o", $gccExe) -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
        $gccCompiled = $process -and $process.ExitCode -eq 0 -and (Test-Path $gccExe)
    } else {
        $gccCompiled = $false
    }

    # Test Flash runtime
    if ($flashCompiled) {
        Write-Status "Testing Flash runtime performance..." "Cyan"

        $flashTimes = @()
        for ($i = 1; $i -le $Iterations; $i++) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $process = Start-Process -FilePath $flashExe -NoNewWindow -Wait -PassThru -RedirectStandardOutput "temp_out.txt" -RedirectStandardError "temp_err.txt" -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            if ($process -and $process.ExitCode -eq 0) {
                $flashTimes += $stopwatch.ElapsedMilliseconds
                if ($Verbose) { Write-Host "  Iteration $i`: $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Gray }
            }
        }

        if ($flashTimes.Count -gt 0) {
            $flashAvg = [math]::Round(($flashTimes | Measure-Object -Average).Average, 2)
            Write-Host "Flash runtime average: ${flashAvg}ms" -ForegroundColor Green
        }

        Remove-Item $flashExe -Force -ErrorAction SilentlyContinue
    } else {
        Write-Warning "Failed to compile Flash version"
        $flashAvg = 0
    }

    # Test GCC runtime
    if ($gccCompiled) {
        Write-Status "Testing GCC -O3 runtime performance..." "Cyan"

        $gccTimes = @()
        for ($i = 1; $i -le $Iterations; $i++) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $process = Start-Process -FilePath $gccExe -NoNewWindow -Wait -PassThru -RedirectStandardOutput "temp_out.txt" -RedirectStandardError "temp_err.txt" -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            if ($process -and $process.ExitCode -eq 0) {
                $gccTimes += $stopwatch.ElapsedMilliseconds
                if ($Verbose) { Write-Host "  Iteration $i`: $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Gray }
            }
        }

        if ($gccTimes.Count -gt 0) {
            $gccAvg = [math]::Round(($gccTimes | Measure-Object -Average).Average, 2)
            Write-Host "GCC -O3 runtime average: ${gccAvg}ms" -ForegroundColor Green

            # Compare performance
            if ($flashAvg -gt 0 -and $gccAvg -gt 0) {
                $ratio = [math]::Round($flashAvg / $gccAvg, 3)
                Write-Host ""
                Write-Host "Runtime comparison:" -ForegroundColor Yellow
                if ($ratio <= 1.05) {
                    Write-Host "Flash performance: ${ratio}x of GCC -O3 (excellent!)" -ForegroundColor Green
                } elseif ($ratio <= 1.20) {
                    Write-Host "Flash performance: ${ratio}x of GCC -O3 (good)" -ForegroundColor Yellow
                } else {
                    Write-Host "Flash performance: ${ratio}x of GCC -O3 (needs optimization)" -ForegroundColor Red
                }
            }
        }

        Remove-Item $gccExe -Force -ErrorAction SilentlyContinue
    } else {
        Write-Warning "Failed to compile GCC version"
    }

    # Clean temp files
    @("temp_out.txt", "temp_err.txt") | ForEach-Object {
        if (Test-Path $_) { Remove-Item $_ -Force -ErrorAction SilentlyContinue }
    }

    Write-Host ""
}

function Show-QuickStatus {
    Write-Status "Flash Compiler Quick Benchmark" "Magenta"
    Write-Host "==============================" -ForegroundColor Magenta

    # System info
    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cpu) {
            Write-Host "CPU: $($cpu.Name)" -ForegroundColor White
        } else {
            Write-Host "CPU: Unknown" -ForegroundColor Gray
        }
    } catch {
        Write-Host "CPU: Could not determine" -ForegroundColor Gray
    }
    Write-Host "Test iterations: $Iterations" -ForegroundColor White

    # Compiler availability
    Write-Host "Compilers:" -ForegroundColor White
    if (Test-Path $FlashCompiler) {
        Write-Host "  Flash: Available ($FlashCompiler)" -ForegroundColor Green
    } else {
        Write-Host "  Flash: Not available ($FlashCompiler)" -ForegroundColor Red
    }

    if (Test-Compiler $GccCompiler) {
        Write-Host "  GCC: Available" -ForegroundColor Green
    } else {
        Write-Host "  GCC: Not available" -ForegroundColor Red
    }

    Write-Host ""
}

# Main execution
Show-QuickStatus

if ($Test -eq "compilation" -or $Test -eq "both") {
    Quick-CompilationTest
}

if ($Test -eq "runtime" -or $Test -eq "both") {
    Quick-RuntimeTest
}

Write-Status "Quick benchmark completed!" "Green"
Write-Host ""
Write-Host "For detailed benchmarks, run:" -ForegroundColor Yellow
Write-Host "  .\tools\compile_bench.ps1  # Detailed compilation benchmarks" -ForegroundColor Gray
Write-Host "  .\tools\runtime_bench.ps1  # Detailed runtime benchmarks" -ForegroundColor Gray
Write-Host "  .\tools\runner.ps1         # Full benchmark suite" -ForegroundColor Gray
