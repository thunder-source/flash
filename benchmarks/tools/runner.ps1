# Flash Compiler Benchmark Runner
# Comprehensive performance testing suite for Flash vs GCC/Clang/MSVC

param(
    [string]$Program = "all",
    [string]$Type = "all",
    [switch]$Verbose,
    [switch]$Debug,
    [switch]$StoreResults,
    [string]$GitHash = "",
    [int]$Iterations = 5,
    [string]$OutputFormat = "json"
)

# Configuration
$script:FlashCompiler = "flash.exe"
$script:GccCompiler = "gcc.exe"
$script:ClangCompiler = "clang.exe"
$script:MsvcCompiler = "cl.exe"

$script:BenchmarkRoot = Split-Path -Parent $PSScriptRoot
$script:ProgramsDir = Join-Path $BenchmarkRoot "programs"
$script:ResultsDir = Join-Path $BenchmarkRoot "results"
$script:ConfigDir = Join-Path $BenchmarkRoot "config"

# Ensure results directories exist
@("compilation", "runtime", "memory") | ForEach-Object {
    $dir = Join-Path $ResultsDir $_
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

# Available benchmark programs
$script:BenchmarkPrograms = @(
    "fibonacci",
    "prime_sieve",
    "quicksort",
    "matrix_multiply",
    "hash_table",
    "binary_tree",
    "string_search",
    "numerical",
    "large_file",
    "many_functions",
    "deep_recursion",
    "complex_expressions"
)

function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

function Write-Debug {
    param([string]$Message)
    if ($Debug) { Write-Host "[DEBUG] $Message" -ForegroundColor Gray }
}

function Test-Compiler {
    param([string]$CompilerPath)

    try {
        $result = & $CompilerPath --version 2>$null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Get-CompilerVersion {
    param([string]$CompilerPath)

    try {
        $version = & $CompilerPath --version 2>$null | Select-Object -First 1
        return $version -replace '.*?(\d+\.\d+\.\d+).*', '$1'
    } catch {
        return "unknown"
    }
}

function Measure-CompilationSpeed {
    param(
        [string]$Program,
        [string]$Compiler,
        [string]$SourceFile,
        [string]$OutputFile,
        [string[]]$CompilerArgs
    )

    Write-Debug "Measuring compilation speed: $Compiler $Program"

    $results = @()

    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Debug "Iteration $i/$Iterations for $Program with $Compiler"

        # Clean previous output
        if (Test-Path $OutputFile) { Remove-Item $OutputFile -Force }

        # Measure compilation time and memory usage
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $process = Start-Process -FilePath $Compiler -ArgumentList (@($SourceFile) + $CompilerArgs + @("-o", $OutputFile)) -NoNewWindow -Wait -PassThru
        $stopwatch.Stop()

        $result = @{
            Iteration = $i
            CompileTimeMs = $stopwatch.ElapsedMilliseconds
            ExitCode = $process.ExitCode
            Success = $process.ExitCode -eq 0
            PeakMemoryMB = [math]::Round($process.PeakWorkingSet64 / 1MB, 2)
        }

        if (Test-Path $SourceFile) {
            $sourceSize = (Get-Item $SourceFile).Length
            $result.SourceSizeBytes = $sourceSize
            $result.CompileSpeedLPS = [math]::Round(($sourceSize / $stopwatch.ElapsedMilliseconds) * 1000, 2)
        }

        if (Test-Path $OutputFile) {
            $result.BinarySizeBytes = (Get-Item $OutputFile).Length
        }

        $results += $result

        if ($Verbose) {
            Write-Host "  Iteration $i: $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Cyan
        }
    }

    # Calculate statistics
    $times = $results | Where-Object { $_.Success } | ForEach-Object { $_.CompileTimeMs }
    $memories = $results | Where-Object { $_.Success } | ForEach-Object { $_.PeakMemoryMB }

    return @{
        Program = $Program
        Compiler = $Compiler
        Iterations = $times.Count
        SuccessRate = [math]::Round(($times.Count / $Iterations) * 100, 2)
        CompileTime = @{
            MinMs = if ($times) { ($times | Measure-Object -Minimum).Minimum } else { 0 }
            MaxMs = if ($times) { ($times | Measure-Object -Maximum).Maximum } else { 0 }
            AvgMs = if ($times) { [math]::Round(($times | Measure-Object -Average).Average, 2) } else { 0 }
            MedianMs = if ($times) { Get-Median $times } else { 0 }
        }
        Memory = @{
            MinMB = if ($memories) { ($memories | Measure-Object -Minimum).Minimum } else { 0 }
            MaxMB = if ($memories) { ($memories | Measure-Object -Maximum).Maximum } else { 0 }
            AvgMB = if ($memories) { [math]::Round(($memories | Measure-Object -Average).Average, 2) } else { 0 }
        }
        BinarySize = if ($results | Where-Object Success) { $results[0].BinarySizeBytes } else { 0 }
        SourceSize = if ($results | Where-Object Success) { $results[0].SourceSizeBytes } else { 0 }
        CompileSpeed = if ($results | Where-Object Success) { $results[0].CompileSpeedLPS } else { 0 }
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        GitHash = $GitHash
        RawResults = $results
    }
}

function Measure-RuntimePerformance {
    param(
        [string]$Program,
        [string]$Executable
    )

    Write-Debug "Measuring runtime performance: $Program"

    if (!(Test-Path $Executable)) {
        Write-Warning "Executable not found: $Executable"
        return $null
    }

    $results = @()

    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Debug "Runtime iteration $i/$Iterations for $Program"

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $process = Start-Process -FilePath $Executable -NoNewWindow -Wait -PassThru -RedirectStandardOutput "temp_output.txt" -RedirectStandardError "temp_error.txt"
        $stopwatch.Stop()

        $output = if (Test-Path "temp_output.txt") { Get-Content "temp_output.txt" -Raw } else { "" }
        $error = if (Test-Path "temp_error.txt") { Get-Content "temp_error.txt" -Raw } else { "" }

        $result = @{
            Iteration = $i
            RuntimeMs = $stopwatch.ElapsedMilliseconds
            ExitCode = $process.ExitCode
            Success = $process.ExitCode -eq 0
            Output = $output
            Error = $error
            PeakMemoryMB = [math]::Round($process.PeakWorkingSet64 / 1MB, 2)
        }

        $results += $result

        if ($Verbose) {
            Write-Host "  Runtime iteration $i: $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Green
        }

        # Clean temp files
        @("temp_output.txt", "temp_error.txt") | ForEach-Object {
            if (Test-Path $_) { Remove-Item $_ -Force }
        }
    }

    # Calculate statistics
    $times = $results | Where-Object { $_.Success } | ForEach-Object { $_.RuntimeMs }
    $memories = $results | Where-Object { $_.Success } | ForEach-Object { $_.PeakMemoryMB }

    return @{
        Program = $Program
        Executable = $Executable
        Iterations = $times.Count
        SuccessRate = [math]::Round(($times.Count / $Iterations) * 100, 2)
        Runtime = @{
            MinMs = if ($times) { ($times | Measure-Object -Minimum).Minimum } else { 0 }
            MaxMs = if ($times) { ($times | Measure-Object -Maximum).Maximum } else { 0 }
            AvgMs = if ($times) { [math]::Round(($times | Measure-Object -Average).Average, 2) } else { 0 }
            MedianMs = if ($times) { Get-Median $times } else { 0 }
        }
        Memory = @{
            MinMB = if ($memories) { ($memories | Measure-Object -Minimum).Minimum } else { 0 }
            MaxMB = if ($memories) { ($memories | Measure-Object -Maximum).Maximum } else { 0 }
            AvgMB = if ($memories) { [math]::Round(($memories | Measure-Object -Average).Average, 2) } else { 0 }
        }
        Output = if ($results | Where-Object Success) { $results[0].Output } else { "" }
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        GitHash = $GitHash
        RawResults = $results
    }
}

function Get-Median {
    param([array]$Numbers)

    $sorted = $Numbers | Sort-Object
    $count = $sorted.Count

    if ($count % 2 -eq 0) {
        return ($sorted[$count/2 - 1] + $sorted[$count/2]) / 2
    } else {
        return $sorted[[math]::Floor($count/2)]
    }
}

function Run-ProgramBenchmark {
    param([string]$Program)

    Write-Status "Benchmarking program: $Program" "Yellow"

    $flashFile = Join-Path $ProgramsDir "flash\$Program.fl"
    $cFile = Join-Path $ProgramsDir "c\$Program.c"

    if (!(Test-Path $flashFile)) {
        Write-Warning "Flash source not found: $flashFile"
        return
    }

    if (!(Test-Path $cFile)) {
        Write-Warning "C source not found: $cFile"
        return
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $compilationResults = @{}
    $runtimeResults = @{}

    # Flash compilation benchmark
    if ($Type -eq "all" -or $Type -eq "compilation") {
        Write-Status "Testing Flash compiler..." "Cyan"

        $flashExe = "temp_flash_$Program.exe"
        $flashResult = Measure-CompilationSpeed $Program "Flash" $flashFile $flashExe @()

        if ($flashResult.CompileTime.AvgMs -gt 0) {
            $compilationResults["Flash"] = $flashResult

            # Runtime benchmark for Flash
            if ($Type -eq "all" -or $Type -eq "runtime") {
                $flashRuntimeResult = Measure-RuntimePerformance $Program $flashExe
                if ($flashRuntimeResult) {
                    $runtimeResults["Flash"] = $flashRuntimeResult
                }
            }
        }

        if (Test-Path $flashExe) { Remove-Item $flashExe -Force }
    }

    # GCC compilation benchmark
    if (($Type -eq "all" -or $Type -eq "compilation") -and (Test-Compiler $GccCompiler)) {
        Write-Status "Testing GCC compiler..." "Cyan"

        $gccExe = "temp_gcc_$Program.exe"

        # Test different optimization levels
        @("-O0", "-O1", "-O2", "-O3") | ForEach-Object {
            $optLevel = $_
            $gccResult = Measure-CompilationSpeed $Program "GCC$optLevel" $cFile $gccExe @($optLevel)

            if ($gccResult.CompileTime.AvgMs -gt 0) {
                $compilationResults["GCC$optLevel"] = $gccResult

                # Runtime benchmark for GCC
                if ($Type -eq "all" -or $Type -eq "runtime") {
                    $gccRuntimeResult = Measure-RuntimePerformance $Program $gccExe
                    if ($gccRuntimeResult) {
                        $runtimeResults["GCC$optLevel"] = $gccRuntimeResult
                    }
                }
            }

            if (Test-Path $gccExe) { Remove-Item $gccExe -Force }
        }
    }

    # Clang compilation benchmark (if available)
    if (($Type -eq "all" -or $Type -eq "compilation") -and (Test-Compiler $ClangCompiler)) {
        Write-Status "Testing Clang compiler..." "Cyan"

        $clangExe = "temp_clang_$Program.exe"
        @("-O0", "-O3") | ForEach-Object {
            $optLevel = $_
            $clangResult = Measure-CompilationSpeed $Program "Clang$optLevel" $cFile $clangExe @($optLevel)

            if ($clangResult.CompileTime.AvgMs -gt 0) {
                $compilationResults["Clang$optLevel"] = $clangResult

                # Runtime benchmark for Clang
                if ($Type -eq "all" -or $Type -eq "runtime") {
                    $clangRuntimeResult = Measure-RuntimePerformance $Program $clangExe
                    if ($clangRuntimeResult) {
                        $runtimeResults["Clang$optLevel"] = $clangRuntimeResult
                    }
                }
            }

            if (Test-Path $clangExe) { Remove-Item $clangExe -Force }
        }
    }

    # Save results
    if ($StoreResults -and $compilationResults.Count -gt 0) {
        $compFile = Join-Path $ResultsDir "compilation\$($Program)_$timestamp.json"
        $compilationResults | ConvertTo-Json -Depth 10 | Out-File $compFile -Encoding UTF8
        Write-Status "Compilation results saved: $compFile" "Green"
    }

    if ($StoreResults -and $runtimeResults.Count -gt 0) {
        $runtimeFile = Join-Path $ResultsDir "runtime\$($Program)_$timestamp.json"
        $runtimeResults | ConvertTo-Json -Depth 10 | Out-File $runtimeFile -Encoding UTF8
        Write-Status "Runtime results saved: $runtimeFile" "Green"
    }

    # Display summary
    Write-Status "Benchmark Summary for $Program" "White"
    Write-Host "================================" -ForegroundColor White

    if ($compilationResults.Count -gt 0) {
        Write-Host "Compilation Speed:" -ForegroundColor Yellow
        $compilationResults.GetEnumerator() | Sort-Object { $_.Value.CompileTime.AvgMs } | ForEach-Object {
            $compiler = $_.Key
            $result = $_.Value
            Write-Host "  $compiler`: $($result.CompileTime.AvgMs)ms (±$([math]::Round(($result.CompileTime.MaxMs - $result.CompileTime.MinMs)/2, 1))ms)" -ForegroundColor Cyan
        }
    }

    if ($runtimeResults.Count -gt 0) {
        Write-Host "Runtime Performance:" -ForegroundColor Yellow
        $runtimeResults.GetEnumerator() | Sort-Object { $_.Value.Runtime.AvgMs } | ForEach-Object {
            $compiler = $_.Key
            $result = $_.Value
            Write-Host "  $compiler`: $($result.Runtime.AvgMs)ms (±$([math]::Round(($result.Runtime.MaxMs - $result.Runtime.MinMs)/2, 1))ms)" -ForegroundColor Green
        }
    }

    Write-Host ""
}

function Show-SystemInfo {
    Write-Status "System Information" "Magenta"
    Write-Host "===================" -ForegroundColor Magenta

    $cpu = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
    $memory = Get-WmiObject -Class Win32_ComputerSystem
    $os = Get-WmiObject -Class Win32_OperatingSystem

    Write-Host "CPU: $($cpu.Name)" -ForegroundColor White
    Write-Host "Cores: $($cpu.NumberOfCores) cores, $($cpu.NumberOfLogicalProcessors) threads" -ForegroundColor White
    Write-Host "Memory: $([math]::Round($memory.TotalPhysicalMemory / 1GB, 1)) GB" -ForegroundColor White
    Write-Host "OS: $($os.Caption) $($os.Version)" -ForegroundColor White
    Write-Host "PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor White

    # Check compiler availability
    Write-Host "Compilers:" -ForegroundColor White
    @(
        @("Flash", $FlashCompiler),
        @("GCC", $GccCompiler),
        @("Clang", $ClangCompiler),
        @("MSVC", $MsvcCompiler)
    ) | ForEach-Object {
        $name, $path = $_
        if (Test-Compiler $path) {
            $version = Get-CompilerVersion $path
            Write-Host "  $name`: Available ($version)" -ForegroundColor Green
        } else {
            Write-Host "  $name`: Not available" -ForegroundColor Red
        }
    }

    Write-Host ""
}

# Main execution
Write-Status "Flash Compiler Benchmark Suite" "Magenta"
Write-Host "===============================" -ForegroundColor Magenta

if ($GitHash -eq "" -and $StoreResults) {
    try {
        $GitHash = git rev-parse HEAD 2>$null
        if ($GitHash) {
            Write-Status "Git hash: $GitHash" "Gray"
        }
    } catch {
        Write-Status "Could not determine git hash" "Yellow"
    }
}

Show-SystemInfo

if ($Program -eq "all") {
    Write-Status "Running all benchmark programs..." "Yellow"
    $BenchmarkPrograms | ForEach-Object {
        Run-ProgramBenchmark $_
    }
} else {
    if ($BenchmarkPrograms -contains $Program) {
        Run-ProgramBenchmark $Program
    } else {
        Write-Error "Unknown program: $Program. Available programs: $($BenchmarkPrograms -join ', ')"
        exit 1
    }
}

Write-Status "Benchmark suite completed!" "Green"
