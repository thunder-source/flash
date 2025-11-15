# Flash Compiler - Compilation Speed Benchmark
# Measures compilation times for Flash vs GCC/Clang/MSVC

param(
    [string]$Program = "all",
    [int]$Iterations = 10,
    [switch]$Verbose,
    [switch]$GenerateReport,
    [string]$ReportFormat = "json"
)

# Configuration
$script:FlashCompiler = "flash.exe"
$script:GccCompiler = "gcc.exe"
$script:ClangCompiler = "clang.exe"
$script:MsvcCompiler = "cl.exe"

$script:BenchmarkRoot = Split-Path -Parent $PSScriptRoot
$script:ProgramsDir = Join-Path $BenchmarkRoot "programs"
$script:ResultsDir = Join-Path $BenchmarkRoot "results\compilation"

# Ensure results directory exists
if (!(Test-Path $ResultsDir)) {
    New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
}

# Available benchmark programs
$script:CompilationPrograms = @(
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

function Test-Compiler {
    param([string]$CompilerPath)
    try {
        $result = & $CompilerPath --version 2>$null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Get-CompilerInfo {
    param([string]$CompilerPath)
    try {
        $version = & $CompilerPath --version 2>$null | Select-Object -First 1
        return @{
            Available = $true
            Version = $version -replace '.*?(\d+\.\d+\.\d+).*', '$1'
            FullVersion = $version
        }
    } catch {
        return @{
            Available = $false
            Version = "unknown"
            FullVersion = "Not available"
        }
    }
}

function Measure-CompilationTime {
    param(
        [string]$CompilerName,
        [string]$CompilerPath,
        [string]$SourceFile,
        [string]$OutputFile,
        [string[]]$CompilerArgs = @()
    )

    Write-Status "Measuring $CompilerName compilation..." "Cyan"

    if (!(Test-Path $SourceFile)) {
        Write-Warning "Source file not found: $SourceFile"
        return $null
    }

    $results = @()
    $sourceSize = (Get-Item $SourceFile).Length
    $sourceLines = (Get-Content $SourceFile | Measure-Object).Count

    for ($i = 1; $i -le $Iterations; $i++) {
        if ($Verbose) {
            Write-Host "  Iteration $i/$Iterations" -ForegroundColor Gray
        }

        # Clean previous output
        if (Test-Path $OutputFile) {
            Remove-Item $OutputFile -Force -ErrorAction SilentlyContinue
        }

        # Prepare arguments
        $allArgs = @($SourceFile) + $CompilerArgs + @("-o", $OutputFile)

        # Measure compilation
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            $process = Start-Process -FilePath $CompilerPath -ArgumentList $allArgs -NoNewWindow -Wait -PassThru -RedirectStandardError "temp_error.txt" -RedirectStandardOutput "temp_output.txt"
            $stopwatch.Stop()

            $result = @{
                Iteration = $i
                CompileTimeMs = $stopwatch.ElapsedMilliseconds
                ExitCode = $process.ExitCode
                Success = $process.ExitCode -eq 0
                PeakMemoryMB = [math]::Round($process.PeakWorkingSet64 / 1MB, 2)
                SourceSizeBytes = $sourceSize
                SourceLines = $sourceLines
            }

            if ($result.Success -and (Test-Path $OutputFile)) {
                $result.OutputSizeBytes = (Get-Item $OutputFile).Length
                $result.CompileSpeedLPS = [math]::Round(($sourceLines / $stopwatch.ElapsedMilliseconds) * 1000, 2)
                $result.CompileSpeedBPS = [math]::Round(($sourceSize / $stopwatch.ElapsedMilliseconds) * 1000, 2)
            } else {
                $result.OutputSizeBytes = 0
                $result.CompileSpeedLPS = 0
                $result.CompileSpeedBPS = 0

                if (Test-Path "temp_error.txt") {
                    $result.ErrorOutput = Get-Content "temp_error.txt" -Raw
                }
            }

        } catch {
            $stopwatch.Stop()
            $result = @{
                Iteration = $i
                CompileTimeMs = $stopwatch.ElapsedMilliseconds
                ExitCode = -1
                Success = $false
                PeakMemoryMB = 0
                SourceSizeBytes = $sourceSize
                SourceLines = $sourceLines
                OutputSizeBytes = 0
                CompileSpeedLPS = 0
                CompileSpeedBPS = 0
                ErrorOutput = $_.Exception.Message
            }
        }

        $results += $result

        # Clean temp files
        @("temp_error.txt", "temp_output.txt") | ForEach-Object {
            if (Test-Path $_) { Remove-Item $_ -Force -ErrorAction SilentlyContinue }
        }

        # Clean output file for next iteration
        if (Test-Path $OutputFile) {
            Remove-Item $OutputFile -Force -ErrorAction SilentlyContinue
        }
    }

    # Calculate statistics
    $successfulRuns = $results | Where-Object { $_.Success }
    $times = $successfulRuns | ForEach-Object { $_.CompileTimeMs }
    $memories = $successfulRuns | ForEach-Object { $_.PeakMemoryMB }
    $speeds = $successfulRuns | ForEach-Object { $_.CompileSpeedLPS }

    if ($times.Count -eq 0) {
        Write-Warning "No successful compilations for $CompilerName"
        return $null
    }

    return @{
        Compiler = $CompilerName
        SourceFile = $SourceFile
        Iterations = $Iterations
        SuccessfulRuns = $times.Count
        SuccessRate = [math]::Round(($times.Count / $Iterations) * 100, 2)

        CompileTime = @{
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

        Performance = @{
            SourceSizeBytes = $sourceSize
            SourceLines = $sourceLines
            AvgOutputSizeBytes = if ($successfulRuns) { [math]::Round(($successfulRuns | ForEach-Object { $_.OutputSizeBytes } | Measure-Object -Average).Average, 0) } else { 0 }
            AvgCompileSpeedLPS = if ($speeds) { [math]::Round(($speeds | Measure-Object -Average).Average, 2) } else { 0 }
            AvgCompileSpeedBPS = if ($successfulRuns) { [math]::Round((($successfulRuns | ForEach-Object { $_.CompileSpeedBPS }) | Measure-Object -Average).Average, 2) } else { 0 }
        }

        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        RawResults = $results
    }
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

function Test-ProgramCompilation {
    param([string]$ProgramName)

    Write-Status "Compilation Speed Test: $ProgramName" "Yellow"
    Write-Host "=" * 50 -ForegroundColor Yellow

    $flashFile = Join-Path $ProgramsDir "flash\$ProgramName.fl"
    $cFile = Join-Path $ProgramsDir "c\$ProgramName.c"

    $results = @{}
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

    # Test Flash compiler
    if (Test-Path $flashFile) {
        $flashExe = "temp_flash_$ProgramName.exe"

        if (Test-Compiler $FlashCompiler) {
            $flashResult = Measure-CompilationTime "Flash" $FlashCompiler $flashFile $flashExe @()
            if ($flashResult) {
                $results["Flash"] = $flashResult
            }
        } else {
            Write-Warning "Flash compiler not available"
        }

        if (Test-Path $flashExe) { Remove-Item $flashExe -Force -ErrorAction SilentlyContinue }
    } else {
        Write-Warning "Flash source not found: $flashFile"
    }

    # Test C compilers
    if (Test-Path $cFile) {
        # GCC tests with different optimization levels
        if (Test-Compiler $GccCompiler) {
            @("-O0", "-O1", "-O2", "-O3") | ForEach-Object {
                $optLevel = $_
                $gccExe = "temp_gcc_${ProgramName}_${optLevel}.exe"
                $gccResult = Measure-CompilationTime "GCC$optLevel" $GccCompiler $cFile $gccExe @($optLevel)

                if ($gccResult) {
                    $results["GCC$optLevel"] = $gccResult
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
                $clangExe = "temp_clang_${ProgramName}_${optLevel}.exe"
                $clangResult = Measure-CompilationTime "Clang$optLevel" $ClangCompiler $cFile $clangExe @($optLevel)

                if ($clangResult) {
                    $results["Clang$optLevel"] = $clangResult
                }

                if (Test-Path $clangExe) { Remove-Item $clangExe -Force -ErrorAction SilentlyContinue }
            }
        } else {
            Write-Warning "Clang compiler not available"
        }

        # MSVC test (if available)
        if (Test-Compiler $MsvcCompiler) {
            $msvcExe = "temp_msvc_${ProgramName}.exe"
            $msvcResult = Measure-CompilationTime "MSVC" $MsvcCompiler $cFile $msvcExe @("/O2")

            if ($msvcResult) {
                $results["MSVC"] = $msvcResult
            }

            if (Test-Path $msvcExe) { Remove-Item $msvcExe -Force -ErrorAction SilentlyContinue }
        }
    } else {
        Write-Warning "C source not found: $cFile"
    }

    # Display results
    if ($results.Count -gt 0) {
        Write-Host ""
        Write-Status "Compilation Speed Results for $ProgramName" "Green"
        Write-Host "-" * 60 -ForegroundColor Green

        # Sort by average compilation time
        $sortedResults = $results.GetEnumerator() | Sort-Object { $_.Value.CompileTime.AvgMs }

        foreach ($entry in $sortedResults) {
            $compiler = $entry.Key
            $result = $entry.Value

            Write-Host "$compiler`:" -ForegroundColor Cyan -NoNewline
            Write-Host " $($result.CompileTime.AvgMs)ms " -ForegroundColor White -NoNewline
            Write-Host "(±$($result.CompileTime.StdDevMs)ms, " -ForegroundColor Gray -NoNewline
            Write-Host "$($result.Performance.AvgCompileSpeedLPS) LPS, " -ForegroundColor Gray -NoNewline
            Write-Host "$($result.Memory.AvgMB)MB)" -ForegroundColor Gray
        }

        # Performance comparison
        if ($results.ContainsKey("Flash") -and $results.ContainsKey("GCCO0")) {
            $flashTime = $results["Flash"].CompileTime.AvgMs
            $gccTime = $results["GCCO0"].CompileTime.AvgMs

            if ($gccTime -gt 0) {
                $speedup = [math]::Round($gccTime / $flashTime, 2)
                Write-Host ""
                Write-Host "Flash vs GCC -O0: " -ForegroundColor Yellow -NoNewline
                if ($speedup > 1) {
                    Write-Host "${speedup}x faster" -ForegroundColor Green
                } else {
                    Write-Host "$([math]::Round(1/$speedup, 2))x slower" -ForegroundColor Red
                }
            }
        }

        # Save results if requested
        if ($GenerateReport) {
            $reportFile = Join-Path $ResultsDir "${ProgramName}_compilation_$timestamp.$ReportFormat"

            $reportData = @{
                Program = $ProgramName
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Iterations = $Iterations
                Results = $results
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
        Write-Warning "No successful compilation results for $ProgramName"
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
        Compilers = @{
            Flash = Get-CompilerInfo $FlashCompiler
            GCC = Get-CompilerInfo $GccCompiler
            Clang = Get-CompilerInfo $ClangCompiler
            MSVC = Get-CompilerInfo $MsvcCompiler
        }
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
            AvgCompileTimeMs = $result.CompileTime.AvgMs
            MinCompileTimeMs = $result.CompileTime.MinMs
            MaxCompileTimeMs = $result.CompileTime.MaxMs
            StdDevMs = $result.CompileTime.StdDevMs
            SuccessRate = $result.SuccessRate
            AvgMemoryMB = $result.Memory.AvgMB
            SourceLines = $result.Performance.SourceLines
            CompileSpeedLPS = $result.Performance.AvgCompileSpeedLPS
            OutputSizeBytes = $result.Performance.AvgOutputSizeBytes
        }
    }

    $csvData | Export-Csv -Path $FilePath -NoTypeInformation
}

function Show-SystemInfo {
    Write-Status "System Information" "Magenta"
    Write-Host "=" * 30 -ForegroundColor Magenta

    $info = Get-SystemInfo

    Write-Host "CPU: $($info.CPU)" -ForegroundColor White
    Write-Host "Cores: $($info.Cores) cores, $($info.LogicalProcessors) threads" -ForegroundColor White
    Write-Host "Memory: $($info.TotalMemoryGB) GB" -ForegroundColor White
    Write-Host "OS: $($info.OS)" -ForegroundColor White
    Write-Host "PowerShell: $($info.PowerShellVersion)" -ForegroundColor White

    Write-Host ""
    Write-Host "Available Compilers:" -ForegroundColor White
    foreach ($entry in $info.Compilers.GetEnumerator()) {
        $name = $entry.Key
        $compiler = $entry.Value

        if ($compiler.Available) {
            Write-Host "  $name`: $($compiler.Version)" -ForegroundColor Green
        } else {
            Write-Host "  $name`: Not available" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Main execution
Write-Status "Flash Compiler - Compilation Speed Benchmark" "Magenta"
Write-Host "=" * 50 -ForegroundColor Magenta

Show-SystemInfo

if ($Program -eq "all") {
    Write-Status "Running compilation benchmarks for all programs..." "Yellow"
    foreach ($prog in $CompilationPrograms) {
        Test-ProgramCompilation $prog
    }
} else {
    if ($CompilationPrograms -contains $Program) {
        Test-ProgramCompilation $Program
    } else {
        Write-Error "Unknown program: $Program. Available programs: $($CompilationPrograms -join ', ')"
        exit 1
    }
}

Write-Status "Compilation speed benchmarking completed!" "Green"
