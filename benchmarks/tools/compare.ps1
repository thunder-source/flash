# Flash Compiler - Benchmark Results Comparison Tool
# Analyzes and compares benchmark results across different runs and compilers

param(
    [string]$Type = "compilation",  # compilation, runtime, or memory
    [string]$ResultsPath = "",      # Path to specific results file or directory
    [string]$Program = "all",       # Specific program or "all"
    [switch]$ShowTrends,            # Show performance trends over time
    [switch]$GenerateChart,         # Generate HTML chart (requires Chart.js)
    [string]$OutputFormat = "table", # table, json, csv, html
    [switch]$Verbose
)

# Configuration
$script:BenchmarkRoot = Split-Path -Parent $PSScriptRoot
$script:ResultsDir = Join-Path $BenchmarkRoot "results"
$script:CompilationDir = Join-Path $ResultsDir "compilation"
$script:RuntimeDir = Join-Path $ResultsDir "runtime"
$script:MemoryDir = Join-Path $ResultsDir "memory"

function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

function Get-ResultFiles {
    param([string]$ResultType, [string]$ProgramFilter = "all")

    $targetDir = switch ($ResultType) {
        "compilation" { $CompilationDir }
        "runtime" { $RuntimeDir }
        "memory" { $MemoryDir }
        default { $CompilationDir }
    }

    if (!(Test-Path $targetDir)) {
        Write-Warning "Results directory not found: $targetDir"
        return @()
    }

    $pattern = if ($ProgramFilter -eq "all") { "*.json" } else { "${ProgramFilter}_*.json" }
    return Get-ChildItem -Path $targetDir -Filter $pattern | Sort-Object LastWriteTime -Descending
}

function Load-ResultFile {
    param([string]$FilePath)

    try {
        $content = Get-Content $FilePath -Raw | ConvertFrom-Json
        return $content
    } catch {
        Write-Warning "Failed to load result file: $FilePath - $($_.Exception.Message)"
        return $null
    }
}

function Compare-CompilationResults {
    param([array]$ResultFiles)

    Write-Status "Analyzing Compilation Speed Results" "Yellow"
    Write-Host "===================================" -ForegroundColor Yellow

    $allResults = @{}

    foreach ($file in $ResultFiles) {
        $data = Load-ResultFile $file.FullName
        if ($data -and $data.Results) {
            $program = $data.Program ?? "unknown"
            $timestamp = $data.Timestamp ?? $file.LastWriteTime.ToString()

            if (!$allResults.ContainsKey($program)) {
                $allResults[$program] = @()
            }

            $programResult = @{
                Timestamp = $timestamp
                File = $file.Name
                Results = $data.Results
            }

            $allResults[$program] += $programResult
        }
    }

    foreach ($program in $allResults.Keys | Sort-Object) {
        Write-Host ""
        Write-Host "Program: $program" -ForegroundColor Cyan
        Write-Host ("-" * 40) -ForegroundColor Cyan

        $programResults = $allResults[$program] | Sort-Object Timestamp -Descending | Select-Object -First 5

        # Create comparison table
        $compilerNames = @()
        foreach ($result in $programResults) {
            $compilerNames += $result.Results.PSObject.Properties.Name
        }
        $compilerNames = $compilerNames | Sort-Object -Unique

        # Header
        Write-Host "Compiler".PadRight(12) -ForegroundColor White -NoNewline
        foreach ($result in $programResults) {
            $header = $result.Timestamp.Substring(0, 10)  # Just date
            Write-Host $header.PadRight(12) -ForegroundColor White -NoNewline
        }
        Write-Host ""

        # Data rows
        foreach ($compiler in $compilerNames) {
            Write-Host $compiler.PadRight(12) -ForegroundColor Yellow -NoNewline

            foreach ($result in $programResults) {
                if ($result.Results.$compiler) {
                    $time = $result.Results.$compiler.CompileTime.AvgMs
                    $timeStr = "${time}ms".PadRight(12)
                } else {
                    $timeStr = "N/A".PadRight(12)
                }
                Write-Host $timeStr -ForegroundColor White -NoNewline
            }
            Write-Host ""
        }

        # Show performance trends for Flash vs others
        if ($ShowTrends -and $programResults.Count -gt 1) {
            Show-CompilationTrends $program $programResults
        }
    }
}

function Compare-RuntimeResults {
    param([array]$ResultFiles)

    Write-Status "Analyzing Runtime Performance Results" "Yellow"
    Write-Host "====================================" -ForegroundColor Yellow

    $allResults = @{}

    foreach ($file in $ResultFiles) {
        $data = Load-ResultFile $file.FullName
        if ($data -and $data.Results) {
            $program = $data.Program ?? "unknown"
            $timestamp = $data.Timestamp ?? $file.LastWriteTime.ToString()

            if (!$allResults.ContainsKey($program)) {
                $allResults[$program] = @()
            }

            $programResult = @{
                Timestamp = $timestamp
                File = $file.Name
                Results = $data.Results
            }

            $allResults[$program] += $programResult
        }
    }

    foreach ($program in $allResults.Keys | Sort-Object) {
        Write-Host ""
        Write-Host "Program: $program" -ForegroundColor Cyan
        Write-Host ("-" * 50) -ForegroundColor Cyan

        $programResults = $allResults[$program] | Sort-Object Timestamp -Descending | Select-Object -First 5

        # Create comparison table
        $compilerNames = @()
        foreach ($result in $programResults) {
            $compilerNames += $result.Results.PSObject.Properties.Name
        }
        $compilerNames = $compilerNames | Sort-Object -Unique

        # Header
        Write-Host "Compiler".PadRight(12) -ForegroundColor White -NoNewline
        foreach ($result in $programResults) {
            $header = $result.Timestamp.Substring(0, 10)  # Just date
            Write-Host $header.PadRight(15) -ForegroundColor White -NoNewline
        }
        Write-Host ""

        # Data rows
        foreach ($compiler in $compilerNames) {
            Write-Host $compiler.PadRight(12) -ForegroundColor Yellow -NoNewline

            foreach ($result in $programResults) {
                if ($result.Results.$compiler) {
                    $time = $result.Results.$compiler.Runtime.AvgMs
                    $correctness = $result.Results.$compiler.CorrectnessRate
                    $indicator = if ($correctness -eq 100) { "✓" } else { "✗" }
                    $timeStr = "${time}ms$indicator".PadRight(15)
                } else {
                    $timeStr = "N/A".PadRight(15)
                }
                Write-Host $timeStr -ForegroundColor White -NoNewline
            }
            Write-Host ""
        }

        # Performance ratios vs GCC -O3
        $latestResult = $programResults[0]
        if ($latestResult.Results.Flash -and $latestResult.Results.GCCO3) {
            $flashTime = $latestResult.Results.Flash.Runtime.AvgMs
            $gccTime = $latestResult.Results.GCCO3.Runtime.AvgMs

            if ($gccTime -gt 0) {
                $ratio = [math]::Round($flashTime / $gccTime, 3)
                Write-Host ""
                Write-Host "Latest Flash vs GCC -O3 ratio: " -ForegroundColor Yellow -NoNewline

                if ($ratio <= 1.05) {
                    Write-Host "$ratio (Excellent - within 5%)" -ForegroundColor Green
                } elseif ($ratio <= 1.20) {
                    Write-Host "$ratio (Good - within 20%)" -ForegroundColor Yellow
                } else {
                    Write-Host "$ratio (Needs optimization)" -ForegroundColor Red
                }
            }
        }

        # Show runtime trends
        if ($ShowTrends -and $programResults.Count -gt 1) {
            Show-RuntimeTrends $program $programResults
        }
    }
}

function Show-CompilationTrends {
    param([string]$Program, [array]$Results)

    Write-Host ""
    Write-Host "Compilation Speed Trends for $Program" -ForegroundColor Green
    Write-Host ("-" * 35) -ForegroundColor Green

    # Focus on Flash vs GCC comparison over time
    $flashTrend = @()
    $gccTrend = @()

    foreach ($result in $Results | Sort-Object Timestamp) {
        if ($result.Results.Flash) {
            $flashTrend += @{
                Date = $result.Timestamp.Substring(0, 10)
                Time = $result.Results.Flash.CompileTime.AvgMs
            }
        }

        if ($result.Results.GCCO0) {
            $gccTrend += @{
                Date = $result.Timestamp.Substring(0, 10)
                Time = $result.Results.GCCO0.CompileTime.AvgMs
            }
        }
    }

    if ($flashTrend.Count -gt 1) {
        $firstFlash = $flashTrend[0].Time
        $lastFlash = $flashTrend[-1].Time
        $change = [math]::Round((($lastFlash - $firstFlash) / $firstFlash) * 100, 1)

        Write-Host "Flash trend: " -ForegroundColor Cyan -NoNewline
        if ($change -lt 0) {
            Write-Host "$change% faster over time" -ForegroundColor Green
        } elseif ($change -gt 5) {
            Write-Host "+$change% slower over time" -ForegroundColor Red
        } else {
            Write-Host "$change% change (stable)" -ForegroundColor Yellow
        }
    }
}

function Show-RuntimeTrends {
    param([string]$Program, [array]$Results)

    Write-Host ""
    Write-Host "Runtime Performance Trends for $Program" -ForegroundColor Green
    Write-Host ("-" * 35) -ForegroundColor Green

    # Track Flash performance trend vs GCC -O3
    $flashTrend = @()
    $ratioTrend = @()

    foreach ($result in $Results | Sort-Object Timestamp) {
        if ($result.Results.Flash -and $result.Results.GCCO3) {
            $flashTime = $result.Results.Flash.Runtime.AvgMs
            $gccTime = $result.Results.GCCO3.Runtime.AvgMs

            if ($gccTime -gt 0) {
                $ratio = $flashTime / $gccTime
                $ratioTrend += @{
                    Date = $result.Timestamp.Substring(0, 10)
                    Ratio = $ratio
                }
            }
        }
    }

    if ($ratioTrend.Count -gt 1) {
        $firstRatio = $ratioTrend[0].Ratio
        $lastRatio = $ratioTrend[-1].Ratio
        $improvement = [math]::Round((($firstRatio - $lastRatio) / $firstRatio) * 100, 1)

        Write-Host "Flash vs GCC -O3 trend: " -ForegroundColor Cyan -NoNewline
        if ($improvement -gt 5) {
            Write-Host "$improvement% improvement" -ForegroundColor Green
        } elseif ($improvement -lt -5) {
            Write-Host "$([math]::Abs($improvement))% regression" -ForegroundColor Red
        } else {
            Write-Host "Stable performance" -ForegroundColor Yellow
        }
    }
}

function Generate-Summary {
    param([string]$ResultType)

    Write-Host ""
    Write-Status "Performance Goals Assessment" "Magenta"
    Write-Host "============================" -ForegroundColor Magenta

    # Load latest results for each program
    $resultFiles = Get-ResultFiles $ResultType
    $latestResults = @{}

    foreach ($file in $resultFiles) {
        $data = Load-ResultFile $file.FullName
        if ($data -and $data.Results -and $data.Program) {
            $program = $data.Program
            if (!$latestResults.ContainsKey($program) -or
                $data.Timestamp -gt $latestResults[$program].Timestamp) {
                $latestResults[$program] = $data
            }
        }
    }

    if ($ResultType -eq "compilation") {
        Write-Host "Compilation Speed Goals:" -ForegroundColor Yellow
        Write-Host "Target: 2-5x faster than GCC/Clang" -ForegroundColor Gray

        $goalsMet = 0
        $totalPrograms = 0

        foreach ($program in $latestResults.Keys) {
            $result = $latestResults[$program]

            if ($result.Results.Flash -and $result.Results.GCCO0) {
                $flashTime = $result.Results.Flash.CompileTime.AvgMs
                $gccTime = $result.Results.GCCO0.CompileTime.AvgMs

                if ($gccTime -gt 0) {
                    $speedup = $gccTime / $flashTime
                    $totalPrograms++

                    Write-Host "  $program`: " -ForegroundColor White -NoNewline
                    if ($speedup -ge 2) {
                        Write-Host "${speedup:F1}x faster ✓" -ForegroundColor Green
                        $goalsMet++
                    } elseif ($speedup -ge 1) {
                        Write-Host "${speedup:F1}x faster (below target)" -ForegroundColor Yellow
                    } else {
                        Write-Host "$([math]::Round(1/$speedup, 1))x slower ✗" -ForegroundColor Red
                    }
                }
            }
        }

        if ($totalPrograms -gt 0) {
            $successRate = [math]::Round(($goalsMet / $totalPrograms) * 100, 1)
            Write-Host ""
            Write-Host "Goal achievement: $goalsMet/$totalPrograms programs ($successRate%)" -ForegroundColor $(if ($successRate -ge 70) { "Green" } elseif ($successRate -ge 40) { "Yellow" } else { "Red" })
        }
    }
    elseif ($ResultType -eq "runtime") {
        Write-Host "Runtime Performance Goals:" -ForegroundColor Yellow
        Write-Host "Target: Within 95-100% of GCC -O3 performance" -ForegroundColor Gray

        $goalsMet = 0
        $totalPrograms = 0

        foreach ($program in $latestResults.Keys) {
            $result = $latestResults[$program]

            if ($result.Results.Flash -and $result.Results.GCCO3) {
                $flashTime = $result.Results.Flash.Runtime.AvgMs
                $gccTime = $result.Results.GCCO3.Runtime.AvgMs

                if ($gccTime -gt 0) {
                    $ratio = $flashTime / $gccTime
                    $performance = [math]::Round((1 / $ratio) * 100, 1)
                    $totalPrograms++

                    Write-Host "  $program`: " -ForegroundColor White -NoNewline
                    if ($ratio -le 1.05) {
                        Write-Host "$performance% of GCC -O3 ✓" -ForegroundColor Green
                        $goalsMet++
                    } elseif ($ratio -le 1.20) {
                        Write-Host "$performance% of GCC -O3 (acceptable)" -ForegroundColor Yellow
                    } else {
                        Write-Host "$performance% of GCC -O3 ✗" -ForegroundColor Red
                    }
                }
            }
        }

        if ($totalPrograms -gt 0) {
            $successRate = [math]::Round(($goalsMet / $totalPrograms) * 100, 1)
            Write-Host ""
            Write-Host "Goal achievement: $goalsMet/$totalPrograms programs ($successRate%)" -ForegroundColor $(if ($successRate -ge 70) { "Green" } elseif ($successRate -ge 40) { "Yellow" } else { "Red" })
        }
    }
}

function Export-Results {
    param([array]$ResultFiles, [string]$Format)

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $outputPath = Join-Path $BenchmarkRoot "results\comparison_${Type}_${timestamp}.$Format"

    switch ($Format) {
        "json" {
            $exportData = @{
                Type = $Type
                Generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Files = $ResultFiles | ForEach-Object { Load-ResultFile $_.FullName }
            }
            $exportData | ConvertTo-Json -Depth 10 | Out-File $outputPath -Encoding UTF8
        }
        "csv" {
            # Flatten results for CSV export
            $csvData = @()
            foreach ($file in $ResultFiles) {
                $data = Load-ResultFile $file.FullName
                if ($data -and $data.Results) {
                    foreach ($compiler in $data.Results.PSObject.Properties.Name) {
                        $result = $data.Results.$compiler
                        $csvData += [PSCustomObject]@{
                            Program = $data.Program
                            Timestamp = $data.Timestamp
                            Compiler = $compiler
                            AvgTime = if ($Type -eq "compilation") { $result.CompileTime.AvgMs } else { $result.Runtime.AvgMs }
                            MinTime = if ($Type -eq "compilation") { $result.CompileTime.MinMs } else { $result.Runtime.MinMs }
                            MaxTime = if ($Type -eq "compilation") { $result.CompileTime.MaxMs } else { $result.Runtime.MaxMs }
                            MemoryMB = $result.Memory.AvgMB
                            SuccessRate = $result.SuccessRate
                        }
                    }
                }
            }
            $csvData | Export-Csv -Path $outputPath -NoTypeInformation
        }
    }

    Write-Status "Results exported to: $outputPath" "Green"
}

# Main execution
Write-Status "Flash Compiler - Benchmark Results Comparison" "Magenta"
Write-Host "=============================================" -ForegroundColor Magenta

if ($ResultsPath -and (Test-Path $ResultsPath)) {
    if (Test-Path $ResultsPath -PathType Leaf) {
        # Single file
        $resultFiles = @(Get-Item $ResultsPath)
    } else {
        # Directory
        $resultFiles = Get-ChildItem -Path $ResultsPath -Filter "*.json"
    }
} else {
    $resultFiles = Get-ResultFiles $Type $Program
}

if ($resultFiles.Count -eq 0) {
    Write-Warning "No result files found for type '$Type' and program '$Program'"
    exit 1
}

Write-Status "Found $($resultFiles.Count) result files" "Gray"

switch ($Type.ToLower()) {
    "compilation" { Compare-CompilationResults $resultFiles }
    "runtime" { Compare-RuntimeResults $resultFiles }
    default {
        Write-Warning "Unknown comparison type: $Type"
        exit 1
    }
}

Generate-Summary $Type

if ($OutputFormat -ne "table") {
    Export-Results $resultFiles $OutputFormat
}

Write-Host ""
Write-Status "Comparison analysis completed!" "Green"
