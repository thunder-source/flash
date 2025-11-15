# Flash Compiler Benchmarking Framework Test
# Validates that Phase 10 benchmarking infrastructure is working correctly

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

function Write-TestStatus {
    param([string]$Message, [string]$Color = "White")
    Write-Host "[TEST] $Message" -ForegroundColor $Color
}

function Test-DirectoryStructure {
    Write-TestStatus "Testing directory structure..." "Yellow"

    $requiredDirs = @(
        "programs",
        "programs/flash",
        "programs/c",
        "programs/results",
        "tools",
        "results",
        "results/compilation",
        "results/runtime",
        "results/memory",
        "config"
    )

    $allExist = $true
    foreach ($dir in $requiredDirs) {
        if (Test-Path $dir) {
            Write-TestStatus "✓ Directory exists: $dir" "Green"
        } else {
            Write-TestStatus "✗ Missing directory: $dir" "Red"
            $allExist = $false
        }
    }

    return $allExist
}

function Test-ConfigurationFiles {
    Write-TestStatus "Testing configuration files..." "Yellow"

    $configFile = "config/benchmarks.json"
    if (Test-Path $configFile) {
        try {
            $config = Get-Content $configFile -Raw | ConvertFrom-Json
            Write-TestStatus "✓ Configuration file is valid JSON" "Green"

            # Test key sections
            if ($config.compilers -and $config.benchmark_programs -and $config.performance_targets) {
                Write-TestStatus "✓ Configuration has required sections" "Green"
                return $true
            } else {
                Write-TestStatus "✗ Configuration missing required sections" "Red"
                return $false
            }
        } catch {
            Write-TestStatus "✗ Configuration file is invalid JSON: $($_.Exception.Message)" "Red"
            return $false
        }
    } else {
        Write-TestStatus "✗ Configuration file not found: $configFile" "Red"
        return $false
    }
}

function Test-BenchmarkPrograms {
    Write-TestStatus "Testing benchmark programs..." "Yellow"

    $requiredPrograms = @("fibonacci", "prime_sieve")
    $allExist = $true

    foreach ($program in $requiredPrograms) {
        $flashFile = "programs/flash/$program.fl"
        $cFile = "programs/c/$program.c"
        $resultFile = "programs/results/$program.txt"

        if (Test-Path $flashFile) {
            Write-TestStatus "✓ Flash program exists: $flashFile" "Green"
        } else {
            Write-TestStatus "✗ Missing Flash program: $flashFile" "Red"
            $allExist = $false
        }

        if (Test-Path $cFile) {
            Write-TestStatus "✓ C program exists: $cFile" "Green"
        } else {
            Write-TestStatus "✗ Missing C program: $cFile" "Red"
            $allExist = $false
        }

        if (Test-Path $resultFile) {
            Write-TestStatus "✓ Expected result exists: $resultFile" "Green"
        } else {
            Write-TestStatus "✗ Missing expected result: $resultFile" "Red"
            $allExist = $false
        }
    }

    return $allExist
}

function Test-BenchmarkScripts {
    Write-TestStatus "Testing benchmark scripts..." "Yellow"

    $requiredScripts = @(
        "tools/runner.ps1",
        "tools/compile_bench.ps1",
        "tools/runtime_bench.ps1",
        "tools/compare.ps1",
        "quick_bench.ps1"
    )

    $allExist = $true
    foreach ($script in $requiredScripts) {
        if (Test-Path $script) {
            Write-TestStatus "✓ Script exists: $script" "Green"
        } else {
            Write-TestStatus "✗ Missing script: $script" "Red"
            $allExist = $false
        }
    }

    return $allExist
}

function Test-SystemRequirements {
    Write-TestStatus "Testing system requirements..." "Yellow"

    # Test PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -ge 5) {
        Write-TestStatus "✓ PowerShell version: $psVersion" "Green"
    } else {
        Write-TestStatus "✗ PowerShell version too old: $psVersion (need 5.0+)" "Red"
        return $false
    }

    # Test available memory
    try {
        $memory = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
        if ($memory) {
            $totalMemoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 1)
            if ($totalMemoryGB -ge 4) {
                Write-TestStatus "✓ System memory: ${totalMemoryGB}GB" "Green"
            } else {
                Write-TestStatus "⚠ Low system memory: ${totalMemoryGB}GB (recommend 4GB+)" "Yellow"
            }
        } else {
            Write-TestStatus "⚠ Could not determine system memory" "Yellow"
        }
    } catch {
        Write-TestStatus "⚠ Could not check system memory" "Yellow"
    }

    # Test CPU cores
    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cpu -and $cpu.NumberOfCores -ge 2) {
            Write-TestStatus "✓ CPU cores: $($cpu.NumberOfCores)" "Green"
        } else {
            Write-TestStatus "⚠ Could not determine CPU cores or single core detected" "Yellow"
        }
    } catch {
        Write-TestStatus "⚠ Could not check CPU information" "Yellow"
    }

    return $true
}

function Test-CompilerAvailability {
    Write-TestStatus "Testing compiler availability..." "Yellow"

    $compilers = @(
        @("Flash", "flash.exe", "Flash compiler"),
        @("GCC", "gcc.exe", "GNU Compiler Collection"),
        @("Clang", "clang.exe", "LLVM Clang compiler"),
        @("MSVC", "cl.exe", "Microsoft Visual C++")
    )

    $availableCount = 0
    foreach ($compiler in $compilers) {
        $name, $exe, $desc = $compiler
        try {
            $null = Get-Command $exe -ErrorAction SilentlyContinue
            if ($?) {
                Write-TestStatus "✓ $name available: $exe" "Green"
                $availableCount++
            } else {
                Write-TestStatus "✗ $name not available: $exe" "Red"
            }
        } catch {
            Write-TestStatus "✗ $name not found: $exe" "Red"
        }
    }

    if ($availableCount -ge 1) {
        Write-TestStatus "✓ At least one compiler available ($availableCount/4)" "Green"
        return $true
    } else {
        Write-TestStatus "✗ No compilers available" "Red"
        return $false
    }
}

function Run-QuickFunctionalTest {
    Write-TestStatus "Running quick functional test..." "Yellow"

    # Check if quick_bench.ps1 exists and can be parsed
    if (Test-Path "quick_bench.ps1") {
        try {
            # Just validate the script syntax without running
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content "quick_bench.ps1" -Raw), [ref]$null)
            Write-TestStatus "✓ Quick benchmark script has valid syntax" "Green"
            return $true
        } catch {
            Write-TestStatus "✗ Quick benchmark script has syntax errors: $($_.Exception.Message)" "Red"
            return $false
        }
    } else {
        Write-TestStatus "✗ Quick benchmark script not found" "Red"
        return $false
    }
}

function Show-TestSummary {
    param([hashtable]$Results)

    Write-Host ""
    Write-TestStatus "Test Summary" "Magenta"
    Write-Host "============" -ForegroundColor Magenta

    $totalTests = $Results.Count
    $passedTests = ($Results.Values | Where-Object { $_ -eq $true }).Count
    $failedTests = $totalTests - $passedTests

    foreach ($test in $Results.Keys | Sort-Object) {
        $status = if ($Results[$test]) { "PASS" } else { "FAIL" }
        $color = if ($Results[$test]) { "Green" } else { "Red" }
        Write-Host "$test`: $status" -ForegroundColor $color
    }

    Write-Host ""
    Write-TestStatus "Overall: $passedTests/$totalTests tests passed" $(if ($failedTests -eq 0) { "Green" } elseif ($failedTests -le 2) { "Yellow" } else { "Red" })

    if ($failedTests -eq 0) {
        Write-TestStatus "✓ Phase 10 benchmarking framework is ready!" "Green"
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Run quick benchmark: .\quick_bench.ps1" -ForegroundColor Gray
        Write-Host "2. Run compilation benchmark: .\tools\compile_bench.ps1" -ForegroundColor Gray
        Write-Host "3. Run runtime benchmark: .\tools\runtime_bench.ps1" -ForegroundColor Gray
        Write-Host "4. Compare results: .\tools\compare.ps1" -ForegroundColor Gray
    } else {
        Write-TestStatus "⚠ Some tests failed. Please resolve issues before running benchmarks." "Yellow"
        Write-Host ""
        Write-Host "Common fixes:" -ForegroundColor Yellow
        Write-Host "- Install missing compilers (GCC via MinGW, Visual Studio)" -ForegroundColor Gray
        Write-Host "- Build Flash compiler: cd .. && .\scripts\build.bat" -ForegroundColor Gray
        Write-Host "- Create missing directories manually" -ForegroundColor Gray
    }

    return $failedTests -eq 0
}

# Main test execution
Write-TestStatus "Flash Compiler Benchmarking Framework Test" "Magenta"
Write-Host "===========================================" -ForegroundColor Magenta
Write-Host ""

$testResults = [ordered]@{}

$testResults["Directory Structure"] = Test-DirectoryStructure
$testResults["Configuration Files"] = Test-ConfigurationFiles
$testResults["Benchmark Programs"] = Test-BenchmarkPrograms
$testResults["Benchmark Scripts"] = Test-BenchmarkScripts
$testResults["System Requirements"] = Test-SystemRequirements
$testResults["Compiler Availability"] = Test-CompilerAvailability
$testResults["Quick Functional Test"] = Run-QuickFunctionalTest

$success = Show-TestSummary $testResults

if ($success) {
    exit 0
} else {
    exit 1
}
