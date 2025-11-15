# Flash Compiler - Runtime Performance Benchmark
# Measures execution performance of Flash vs GCC/Clang/MSVC compiled programs

param(
    [string]$Program = "all",
    [int]$Iterations = 10,
    [switch]$Verbose,
    [switch]$GenerateReport,
    [string]$ReportFormat = "json",
    [switch]$ProfileMemory
)

# Configuration
$script:FlashCompiler = "flash.exe"
$script:GccCompiler = "gcc.exe"
$script:ClangCompiler = "clang.exe"
$script:MsvcCompiler = "cl.exe"

$script:BenchmarkRoot = Split-Path -Parent $PSScriptRoot
$script:ProgramsDir = Join-Path $BenchmarkRoot "programs"
$script:ResultsDir = Join-Path $BenchmarkRoot "results\runtime"

# Ensure results directory exists
if (!(Test-Path $ResultsDir)) {
    New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
}

# Available benchmark programs
$script:RuntimePrograms = @(
    "fibonacci",
    "prime_sieve",
    "quicksort",
    "matrix_multiply",
    "hash_table",
    "binary_tree",
    "string_search",
    "numerical"
)

function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
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

function Compile-Program {
    param(
        [string]$CompilerName,
        [string]$CompilerPath,
        [string]$SourceFile,
        [string]$OutputFile,
        [string[]]$CompilerArgs = @()
    )

    if (!(Test-Path $SourceFile)) {
        Write-Warning "Source file not found: $SourceFile"
        return $false
    }

    # Clean previous output
    if (Test-Path $OutputFile) {
        Remove-Item $OutputFile -Force -ErrorAction SilentlyContinue
    }

    # Compile
    $allArgs = @($SourceFile) + $CompilerArgs + @("-o", $OutputFile)

    try {
        $process = Start-Process -FilePath $CompilerPath -ArgumentList $allArgs -NoNewWindow -Wait -PassThru -RedirectStandardError "temp_compile_error.txt" -RedirectStandardOutput "temp_compile_output.txt"

        $success = $process.ExitCode -eq 0 -and (Test-Path $OutputFile)

        if (!$success -and $Verbose) {
            if (Test-Path "temp_compile_error.txt") {
                $errorOutput = Get-Content "temp_compile_error.txt" -Raw
                Write-Warning "Compilation failed for $CompilerName`: $errorOutput"
            }
        }

        # Clean temp files
        @("temp_compile_error.txt", "temp_compile_output.txt") | ForEach-Object {
            if (Test-Path $_) { Remove-Item $_ -Force -ErrorAction SilentlyContinue }
        }

        return $success
    } catch {
        Write-Warning "Failed to compile with $CompilerName`: $($_.Exception.Message)"
        return $false
    }
}

function Measure-ExecutionTime {
    param(
        [string]$CompilerName,
        [string]$ExecutablePath,
        [hashtable]$ExpectedOutput = @{}
    )

    Write-Status "Measuring $CompilerName runtime performance..." "Cyan"

    if (!(Test-Path $ExecutablePath)) {
        Write-Warning "Executable not found: $ExecutablePath"
        return $null
    }

    $results = @()

    for ($i = 1; $i -le $Iterations; $i++) {
        if ($Verbose) {
            Write-Host "  Runtime iteration $i/$Iterations" -ForegroundColor Gray
        }

        # Measure execution time
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            $process = Start-Process -FilePath $ExecutablePath -NoNewWindow -Wait -PassThru -RedirectStandardOutput "temp_output.txt" -RedirectStandardError "temp_error.txt"
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
                UserTimeMs = [math]::Round($process.UserProcessorTime.TotalMilliseconds, 2)
                SystemTimeMs = [math]::Round($process.PrivilegedProcessorTime.TotalMilliseconds, 2)
            }

            # Verify output correctness if expected output provided
            if ($ExpectedOutput.Count -gt 0 -and $result.Success) {
                $result.OutputCorrect = Verify-ProgramOutput $output $ExpectedOutput
            } else {
                $result.OutputCorrect = $true  # Assume correct if no expected output
            }

        } catch {
            $stopwatch.Stop()
            $result = @{
                Iteration = $i
                RuntimeMs = $stopwatch.ElapsedMilliseconds
                ExitCode = -1
                Success = $false
                Output = ""
                Error = $_.Exception.Message
                PeakMemoryMB = 0
                UserTimeMs = 0
                SystemTimeMs = 0
                OutputCorrect = $false
            }
        }

        $results += $result

        # Clean temp files
        @("temp_output.txt", "temp_error.txt") | ForEach-Object {
            if (Test-Path $_) { Remove-Item $_ -Force -ErrorAction SilentlyContinue }
        }
    }

    # Calculate statistics
    $successfulRuns = $results | Where-Object { $_.Success -and $_.OutputCorrect }
    $times = $successfulRuns | ForEach-Object { $_.RuntimeMs }
    $memories = $successfulRuns | ForEach-Object { $_.PeakMemoryMB }
    $userTimes = $successfulRuns | ForEach-Object { $_.UserTimeMs }
    $systemTimes = $successfulRuns | ForEach-Object { $_.SystemTimeMs }

    if ($times.Count -eq 0) {
        Write-Warning "No successful runs for $CompilerName"
        return $null
    }

    return @{
        Compiler = $CompilerName
        Executable = $ExecutablePath
        Iterations = $Iterations
        SuccessfulRuns = $times.Count
        CorrectRuns = ($results | Where-Object { $_.Success -and $_.OutputCorrect }).Count
        SuccessRate = [math]::Round(($times.Count / $Iterations) * 100, 2)
        CorrectnessRate = [math]::Round((($results | Where-Object { $_.Success -and $_.OutputCorrect }).Count / $Iterations) * 100, 2)

        Runtime = @{
            MinMs = ($times | Measure-Object -Minimum).Minimum
            MaxMs = ($times | Measure-Object -Maximum).Maximum
            AvgMs = [math]::Round(($times | Measure-Object -Average).Average, 2)
            MedianMs = Get-Median $times
            StdDevMs = [math]::Round((Get-StandardDeviation $times), 2)
        }

        Memory = @{
            MinMB = ($memories | Measure-Object -Minimum).Minimum
            MaxMB = ($memories | Measure-Object -Maximum).Maximum
            AvgMB = [math]::Round(($memories | Measure-Object -Average).Average, 2)
        }

        CPUTime = @{
            AvgUserMs = if ($userTimes) { [math]::Round(($userTimes | Measure-Object -Average).Average, 2) } else { 0 }
            AvgSystemMs = if ($systemTimes) { [math]::Round(($systemTimes | Measure-Object -Average).Average, 2) } else { 0 }
        }

        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        RawResults = $results
    }
}

function Verify-ProgramOutput {
    param([string]$ActualOutput, [hashtable]$ExpectedPatterns)

    # Simple output verification - check for key patterns/values
    foreach ($pattern in $ExpectedPatterns.Keys) {
        $expectedValue = $ExpectedPatterns[$pattern]

        if ($ActualOutput -notmatch $pattern) {
            return $false
        }

        # If expected value is provided, verify it matches
        if ($expectedValue -and $ActualOutput -notmatch "$pattern.*$expectedValue") {
            return $false
        }
    }

    return $true
}

function Get-Median {
    param([array]$Numbers)
    if ($Numbers.Count -eq 0) { return 0 }

    $sorted = $Numbers | Sort-Object
    $count = $sorted.Count

    if ($count % 2 -eq 0) {
        return [math]::Round(($sorted[$count/2 - 1] + $sorted[$count/2]) / 2, 2)
    } else {
        return $sorted[[math]::Floor($count/2)]
    }
}

function Get-StandardDeviation {
    param([array]$Numbers)
    if ($Numbers.Count -le 1) { return 0 }

    $mean = ($Numbers | Measure-Object -Average).Average
    $sumSquaredDiffs = ($Numbers | ForEach-Object { [math]::Pow($_ - $mean, 2) } | Measure-Object -Sum).Sum
    return [math]::Sqrt($sumSquaredDiffs / ($Numbers.Count - 1))
}

function Get-ExpectedOutput {
    param([string]$ProgramName)

    # Define expected output patterns for verification
    $patterns = @{
        "fibonacci" = @{
            "Fibonacci.*completed successfully" = $null
            "Recursive.*result.*35" = "9227465"
        }
        "prime_sieve" = @{
            "Prime sieve.*completed successfully" = $null
            "Found.*9592.*primes" = $null  # Expected for limit 100000
        }
        "quicksort" = @{
            "Quicksort.*completed successfully" = $null
        }
        "matrix_multiply" = @{
            "Matrix.*completed successfully" = $null
        }
        "hash_table" = @{
            "Hash table.*completed successfully" = $null
        }
        "binary_tree" = @{
            "Binary tree.*completed successfully" = $null
        }
        "string_search" = @{
            "String search.*completed successfully" = $null
        }
        "numerical" = @{
            "Numerical.*completed successfully" = $null
        }
    }

    return $patterns[$ProgramName] ?? @{}
}

function Test-ProgramRuntime {
    param([string]$ProgramName)

    Write-Status "Runtime Performance Test: $ProgramName" "Yellow"
    Write-Host "=" * 50 -ForegroundColor Yellow

    $flashFile = Join-Path $ProgramsDir "flash\$ProgramName.fl"
    $cFile = Join-Path $ProgramsDir "c\$ProgramName.c"
    $expectedOutput = Get-ExpectedOutput $ProgramName

    $compilationResults = @{}
    $runtimeResults = @{}
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

    # Compile and test Flash version
    if (Test-Path $flashFile) {
        $flashExe = "temp_flash_runtime_$ProgramName.exe"

        if (Test-Compiler $FlashCompiler) {
            Write-Status "Compiling Flash version..." "Cyan"
            $flashCompiled = Compile-Program "Flash" $FlashCompiler $flashFile $flashExe @()

            if ($flashCompiled) {
                $flashResult = Measure-ExecutionTime "Flash" $flashExe $expectedOutput
                if ($flashResult) {
                    $runtimeResults["Flash"] = $flashResult
                }
            } else {
                Write-Warning "Failed to compile Flash version"
            }

            if (Test-Path $flashExe) { Remove-Item $flashExe -Force -ErrorAction SilentlyContinue }
        } else {
            Write-Warning "Flash compiler not available"
        }
    } else {
        Write-Warning "Flash source not found: $flashFile"
    }

    # Compile and test C versions
    if (Test-Path $cFile) {
        # GCC tests with different optimization levels
        if (Test-Compiler $GccCompiler) {
            @("-O0", "-O1", "-O2", "-O3") | ForEach-Object {
                $optLevel = $_
                $gccExe = "temp_gcc_runtime_${ProgramName}_${optLevel}.exe"

                Write-Status "Compiling GCC $optLevel version..." "Cyan"
                $gccCompiled = Compile-Program "GCC$optLevel" $GccCompiler $cFile $gccExe @($optLevel)

                if ($gccCompiled) {
                    $gccResult = Measure-ExecutionTime "GCC$optLevel" $gccExe $expectedOutput
                    if ($gccResult) {
                        $runtimeResults["GCC$optLevel"] = $gccResult
                    }
                } else {
                    Write-Warning "Failed to compile GCC $optLevel version"
                }

                if (Test-Path $gccExe) { Remove-Item $gccExe -Force -ErrorAction SilentlyContinue }
            }
        } else {
            Write-Warning "GCC compiler not available"
        }

        # Clang tests
        if (Test-Compiler $ClangCompiler) {
            @("-O0", "-O3") | ForEach-Object {
                $optLevel = $_
                $clangExe = "temp_clang_runtime_${ProgramName}_${optLevel}.exe"

                Write-Status "Compiling Clang $optLevel version..." "Cyan"
                $clangCompiled = Compile-Program "Clang$optLevel" $ClangCompiler $cFile $clangExe @($optLevel)

                if ($clangCompiled) {
                    $clangResult = Measure-ExecutionTime "Clang$optLevel" $clangExe $expectedOutput
                    if ($clangResult) {
                        $runtimeResults["Clang$optLevel"] = $clangResult
                    }
                } else {
                    Write-Warning "Failed to compile Clang $optLevel version"
                }

                if (Test-Path $clangExe) { Remove-Item $clangExe -Force -ErrorAction SilentlyContinue }
            }
        } else {
            Write-Warning "Clang compiler not available"
        }

        # MSVC test (if available)
        if (Test-Compiler $MsvcCompiler) {
            $msvcExe = "temp_msvc_runtime_${ProgramName}.exe"

            Write-Status "Compiling MSVC version..." "Cyan"
            $msvcCompiled = Compile-Program "MSVC" $MsvcCompiler $cFile $msvcExe @("/O2")

            if ($msvcCompiled) {
                $msvcResult = Measure-ExecutionTime "MSVC" $msvcExe $expectedOutput
                if ($msvcResult) {
                    $runtimeResults["MSVC"] = $msvcResult
                }
            } else {
                Write-Warning "Failed to compile MSVC version"
            }

            if (Test-Path $msvcExe) { Remove-Item $msvcExe -Force -ErrorAction SilentlyContinue }
        }
    } else {
        Write-Warning "C source not found: $cFile"
    }

    # Display results
    if ($runtimeResults.Count -gt 0) {
        Write-Host ""
        Write-Status "Runtime Performance Results for $ProgramName" "Green"
        Write-Host "-" * 60 -ForegroundColor Green

        # Sort by average runtime
        $sortedResults = $runtimeResults.GetEnumerator() | Sort-Object { $_.Value.Runtime.AvgMs }

        foreach ($entry in $sortedResults) {
            $compiler = $entry.Key
            $result = $entry.Value

            $correctnessIndicator = if ($result.CorrectnessRate -eq 100) { "✓" } else { "✗" }

            Write-Host "$compiler`: " -ForegroundColor Cyan -NoNewline
            Write-Host "$($result.Runtime.AvgMs)ms " -ForegroundColor White -NoNewline
            Write-Host "(±$($result.Runtime.StdDevMs)ms, " -ForegroundColor Gray -NoNewline
            Write-Host "$($result.Memory.AvgMB)MB, " -ForegroundColor Gray -NoNewline
            Write-Host "$correctnessIndicator)" -ForegroundColor Gray
        }

        # Performance comparisons
        Write-Host ""
        if ($runtimeResults.ContainsKey("Flash")) {
            $flashTime = $runtimeResults["Flash"].Runtime.AvgMs

            # Compare with GCC -O3
            if ($runtimeResults.ContainsKey("GCCO3")) {
                $gccO3Time = $runtimeResults["GCCO3"].Runtime.AvgMs
                if ($gccO3Time -gt 0) {
                    $ratio = [math]::Round($flashTime / $gccO3Time, 3)
                    Write-Host "Flash vs GCC -O3: " -ForegroundColor Yellow -NoNewline
                    if ($ratio <= 1.05) {
                        Write-Host "${ratio}x (within 5% of GCC -O3)" -ForegroundColor Green
                    } elseif ($ratio <= 1.20) {
                        Write-Host "${ratio}x (within 20% of GCC -O3)" -ForegroundColor Yellow
                    } else {
                        Write-Host "${ratio}x (slower than target)" -ForegroundColor Red
                    }
                }
            }

            # Compare with GCC -O0
            if ($runtimeResults.ContainsKey("GCCO0")) {
                $gccO0Time = $runtimeResults["GCCO0"].Runtime.AvgMs
                if ($gccO0Time -gt 0) {
                    $speedup = [math]::Round($gccO0Time / $flashTime, 2)
                    Write-Host "Flash vs GCC -O0: " -ForegroundColor Yellow -NoNewline
                    if ($speedup > 1) {
                        Write-Host "${speedup}x faster" -ForegroundColor Green
                    } else {
                        Write-Host "$([math]::Round(1/$speedup, 2))x slower" -ForegroundColor Red
                    }
                }
            }
        }

        # Save results if requested
        if ($GenerateReport) {
            $reportFile = Join-Path $ResultsDir "${ProgramName}_runtime_$timestamp.$ReportFormat"

            $reportData = @{
                Program = $ProgramName
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Iterations = $Iterations
                Results = $runtimeResults
                SystemInfo = Get-SystemInfo
            }

            if ($ReportFormat -eq "json") {
                $reportData | ConvertTo-Json -Depth 10 | Out-File $reportFile -Encoding UTF8
            } else {
                Generate-CsvReport $reportData $reportFile
            }

            Write-Status "Report saved: $reportFile" "Green"
        }
    } else {
        Write-Warning "No successful runtime results for $ProgramName"
    }

    Write-Host ""
}

function Get-SystemInfo {
    $cpu = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
    $memory = Get-WmiObject -Class Win32_ComputerSystem
    $os = Get-WmiObject -Class Win32_OperatingSystem

    return @{
        CPU = $cpu.Name
        Cores = $cpu.NumberOfCores
        LogicalProcessors = $cpu.NumberOfLogicalProcessors
        TotalMemoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 1)
        OS = "$($os.Caption) $($os.Version)"
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    }
}

function Generate-CsvReport {
    param($ReportData, $FilePath)

    $csvData = @()
    foreach ($entry in $ReportData.Results.GetEnumerator()) {
        $compiler = $entry.Key
        $result = $entry.Value

        $csvData += [PSCustomObject]@{
            Program = $ReportData.Program
            Compiler = $compiler
            AvgRuntimeMs = $result.Runtime.AvgMs
            MinRuntimeMs = $result.Runtime.MinMs
            MaxRuntimeMs = $result.Runtime.MaxMs
            StdDevMs = $result.Runtime.StdDevMs
            SuccessRate = $result.SuccessRate
            CorrectnessRate = $result.CorrectnessRate
            AvgMemoryMB = $result.Memory.AvgMB
            AvgUserTimeMs = $result.CPUTime.AvgUserMs
            AvgSystemTimeMs = $result.CPUTime.AvgSystemMs
        }
    }

    $csvData | Export-Csv -Path $FilePath -NoTypeInformation
}

# Main execution
Write-Status "Flash Compiler - Runtime Performance Benchmark" "Magenta"
Write-Host "=" * 50 -ForegroundColor Magenta

if ($Program -eq "all") {
    Write-Status "Running runtime benchmarks for all programs..." "Yellow"
    foreach ($prog in $RuntimePrograms) {
        Test-ProgramRuntime $prog
    }
} else {
    if ($RuntimePrograms -contains $Program) {
        Test-ProgramRuntime $Program
    } else {
        Write-Error "Unknown program: $Program. Available programs: $($RuntimePrograms -join ', ')"
        exit 1
    }
}

Write-Status "Runtime performance benchmarking completed!" "Green"
