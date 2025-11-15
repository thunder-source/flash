# Flash Compiler - Benchmark Framework Validation
# Simple test script to verify Phase 10 setup

Write-Host "Flash Compiler - Benchmark Framework Validation" -ForegroundColor Magenta
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host ""

$TestsPassed = 0
$TotalTests = 0

function Test-Item {
    param($Name, $TestResult, $Message = "")
    $script:TotalTests++

    if ($TestResult) {
        Write-Host "PASS: $Name" -ForegroundColor Green
        $script:TestsPassed++
    } else {
        Write-Host "FAIL: $Name" -ForegroundColor Red
    }

    if ($Message) {
        Write-Host "      $Message" -ForegroundColor Gray
    }
}

# Test 1: Directory Structure
Write-Host "Testing directory structure..." -ForegroundColor Yellow

$RequiredDirs = @("programs", "programs/flash", "programs/c", "tools", "config")
$DirTestPassed = $true

foreach ($dir in $RequiredDirs) {
    if (!(Test-Path $dir)) {
        $DirTestPassed = $false
        Write-Host "  Missing: $dir" -ForegroundColor Red
    }
}

Test-Item "Directory Structure" $DirTestPassed

# Test 2: Configuration Files
$ConfigExists = Test-Path "config/benchmarks.json"
$ConfigValid = $false

if ($ConfigExists) {
    try {
        $config = Get-Content "config/benchmarks.json" -Raw | ConvertFrom-Json
        $ConfigValid = $true
    } catch {
        $ConfigValid = $false
    }
}

Test-Item "Configuration File" ($ConfigExists -and $ConfigValid)

# Test 3: Benchmark Programs
$ProgramFiles = @(
    "programs/flash/fibonacci.fl",
    "programs/c/fibonacci.c"
)

$ProgramsFound = 0
foreach ($file in $ProgramFiles) {
    if (Test-Path $file) {
        $ProgramsFound++
    }
}

Test-Item "Benchmark Programs" ($ProgramsFound -eq $ProgramFiles.Count) "$ProgramsFound/$($ProgramFiles.Count) found"

# Test 4: Benchmark Scripts
$ScriptFiles = @(
    "tools/runner.ps1",
    "tools/compile_bench.ps1",
    "quick_bench.ps1"
)

$ScriptsFound = 0
foreach ($file in $ScriptFiles) {
    if (Test-Path $file) {
        $ScriptsFound++
    }
}

Test-Item "Benchmark Scripts" ($ScriptsFound -eq $ScriptFiles.Count) "$ScriptsFound/$($ScriptFiles.Count) found"

# Test 5: Flash Compiler
$FlashPaths = @("../build/flash.exe", "../flash.exe", "flash.exe")
$FlashFound = $false
$FlashPath = ""

foreach ($path in $FlashPaths) {
    if (Test-Path $path) {
        $FlashFound = $true
        $FlashPath = $path
        break
    }
}

Test-Item "Flash Compiler" $FlashFound $FlashPath

# Test 6: PowerShell Version
$PSVersionOK = $PSVersionTable.PSVersion.Major -ge 5
Test-Item "PowerShell Version" $PSVersionOK "Version $($PSVersionTable.PSVersion)"

# Summary
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "--------" -ForegroundColor Cyan

if ($TestsPassed -eq $TotalTests) {
    Write-Host "All tests passed! ($TestsPassed/$TotalTests)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Framework is ready. Try these commands:" -ForegroundColor Yellow
    Write-Host "  .\quick_bench.ps1" -ForegroundColor White
    Write-Host "  .\tools\compile_bench.ps1 -Program fibonacci" -ForegroundColor White
} else {
    Write-Host "Tests passed: $TestsPassed/$TotalTests" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To fix issues:" -ForegroundColor Yellow
    Write-Host "  1. Build Flash compiler: cd .. && .\scripts\build.bat" -ForegroundColor White
    Write-Host "  2. Check missing files and directories" -ForegroundColor White
}

Write-Host ""
