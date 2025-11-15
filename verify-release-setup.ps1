#!/usr/bin/env powershell
# First-Time Release Checklist
# Copy this to help guide your first release process

Write-Host "=== Flash Compiler - Release Checklist ===" -ForegroundColor Cyan
Write-Host ""

$checks = @(
    @{ Item = "Makefile has VERSION = 0.1.0"; Check = { Select-String 'VERSION = 0.1.0' Makefile -q } },
    @{ Item = ".github/workflows/release.yml exists"; Check = { Test-Path .\.github\workflows\release.yml } },
    @{ Item = "scripts/install.ps1 exists"; Check = { Test-Path .\scripts\install.ps1 } },
    @{ Item = "scripts/uninstall.ps1 exists"; Check = { Test-Path .\scripts\uninstall.ps1 } },
    @{ Item = "packaging/scoop/flash.json exists"; Check = { Test-Path .\packaging\scoop\flash.json } },
    @{ Item = "packaging/chocolatey/flash-compiler.nuspec exists"; Check = { Test-Path .\packaging\chocolatey\flash-compiler.nuspec } },
    @{ Item = "packaging/winget/thunder-source.flash.yaml exists"; Check = { Test-Path .\packaging\winget\thunder-source.flash.yaml } },
    @{ Item = "RELEASE.md exists"; Check = { Test-Path .\RELEASE.md } },
    @{ Item = "INSTALLATION.md exists"; Check = { Test-Path .\INSTALLATION.md } }
)

$passCount = 0
foreach ($check in $checks) {
    $result = & $check.Check
    $symbol = if ($result) { "[OK]" } else { "[FAIL]" }
    $color = if ($result) { "Green" } else { "Red" }
    Write-Host "$symbol $($check.Item)" -ForegroundColor $color
    if ($result) { $passCount++ }
}

Write-Host ""
Write-Host "Checks passed: $passCount/$($checks.Count)" -ForegroundColor Cyan
Write-Host ""

if ($passCount -eq $checks.Count) {
    Write-Host "[OK] All prerequisites met! Ready for release." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Run: nmake release"
    Write-Host "2. Run: nmake update-manifests VERSION=0.1.0"
    Write-Host "3. Test: .\scripts\install.ps1"
    Write-Host "4. Tag:  git tag -a v0.1.0 -m 'Initial Release'"
    Write-Host "5. Push: git push origin v0.1.0"
    Write-Host ""
    Write-Host "GitHub Actions will automatically build and create a Release!"
} else {
    Write-Host "[FAIL] Some files are missing. Check the list above." -ForegroundColor Red
}
