# Simple Framework Test - No External Dependencies
# Quick validation of benchmarking framework setup

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

function Write-TestResult {
    param([string]$TestName, [bool]$Passed, [string]$Message = "")
    $status = if ($Passed) { "PASS" } else { "FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }

    Write-Host "$TestName`: $status" -ForegroundColor $color
    if ($Message -and $Verbose) {
        Write-Host "  $Message" -ForegroundColor Gray
    }
}

# Test 1: Check directory structure
Write-Host "Testing Benchmark Framework Setup..." -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow

$requiredDirs = @(
    "programs",
    "programs/flash",
    "programs/c",
    "tools",
    "config"
)

$dirTest = $true
foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        if ($Verbose) {
            Write-Host "✓ $dir exists" -ForegroundColor Green
        }
    } else {
        Write-Host "✗ Missing: $dir" -ForegroundColor Red
        $dirTest = $false
    }
}

Write-TestResult "Directory Structure" $dirTest

# Test 2: Check configuration files
$configTest = Test-Path "config/benchmarks.json"
if ($configTest) {
    try {
        $config = Get-Content "config/benchmarks.json" -Raw | ConvertFrom-Json
        $configTest = $config -ne $null
    } catch {
        $configTest = $false
    }
}

Write-TestResult "Configuration Files" $configTest

# Test 3: Check benchmark programs
$programFiles = @(
    "programs/flash/fibonacci.fl",
    "programs/c/fibonacci.c",
    "programs/flash/prime_sieve.fl",
    "programs/c/prime_sieve.c"
)

$foundPrograms = 0
foreach ($file in $programFiles) {
    if (Test-Path $file) {
        $foundPrograms++
    }
}

$programTest = $foundPrograms -eq $programFiles.Count
Write-TestResult "Benchmark Programs" $programTest "$foundPrograms/$($programFiles.Count) programs found"

# Test 4: Check benchmark scripts
$scriptFiles = @(
    "tools/runner.ps1",
    "tools/compile_bench.ps1",
    "tools/runtime_bench.ps1",
    "quick_bench.ps1"
)

$foundScripts = 0
foreach ($file in $scriptFiles) {
    if (Test-Path $file) {
        $foundScripts++
    }
}

$scriptTest = $foundScripts -eq $scriptFiles.Count
Write-TestResult "Benchmark Scripts" $scriptTest "$foundScripts/$($scriptFiles.Count) scripts found"

# Test 5: Check Flash compiler
$flashCompilerPaths = @(
    "../build/flash.exe",
    "../flash.exe",
    "flash.exe"
)

$flashFound = $false
$flashPath = ""
foreach ($path in $flashCompilerPaths) {
    if (Test-Path $path) {
        $flashFound = $true
        $flashPath = $path
        break
    }
}

Write-TestResult "Flash Compiler" $flashFound $flashPath

# Test 6: Check system basics
$psVersion = $PSVersionTable.PSVersion.Major
$psTest = $psVersion -ge 5
Write-TestResult "PowerShell Version" $psTest "Version $($PSVersionTable.PSVersion)"

# Test 7: Check if we can create temp files
$tempTest = $true
try {
    "test" | Out-File "temp_test.txt" -ErrorAction Stop
    Remove-Item "temp_test.txt" -ErrorAction Stop
} catch {
    $tempTest = $false
}

Write-TestResult "File System Access" $tempTest

# Summary
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan

$allTests = @($dirTest, $configTest, $programTest, $scriptTest, $flashFound, $psTest, $tempTest)
$passedTests = 0
foreach ($test in $allTests) {
    if ($test) {
        $passedTests++
    }
}
$totalTests = $allTests.Count

if ($passedTests -eq $totalTests) {
    $summaryColor = "Green"
} else {
    $summaryColor = "Yellow"
}

Write-Host "Tests passed: $passedTests/$totalTests" -ForegroundColor $summaryColor

if ($passedTests -eq $totalTests) {
    Write-Host ""
    Write-Host "✓ Framework setup is complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Run: .\quick_bench.ps1 -Test compilation" -ForegroundColor Gray
    Write-Host "2. Run: .\tools\compile_bench.ps1 -Program fibonacci" -ForegroundColor Gray
    Write-Host "3. Check results in results/ directory" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "⚠ Some setup issues found:" -ForegroundColor Yellow

    if (!$dirTest) {
        Write-Host "- Create missing directories" -ForegroundColor Gray
    }
    if (!$configTest) {
        Write-Host "- Check config/benchmarks.json" -ForegroundColor Gray
    }
    if (!$programTest) {
        Write-Host "- Add missing benchmark programs" -ForegroundColor Gray
    }
    if (!$scriptTest) {
        Write-Host "- Check benchmark scripts in tools/" -ForegroundColor Gray
    }
    if (!$flashFound) {
        Write-Host "- Build Flash compiler: cd .. && .\scripts\build.bat" -ForegroundColor Gray
    }
    if (!$psTest) {
        Write-Host "- Upgrade PowerShell to version 5+" -ForegroundColor Gray
    }
    if (!$tempTest) {
        Write-Host "- Check file system permissions" -ForegroundColor Gray
    }
}

Write-Host ""
