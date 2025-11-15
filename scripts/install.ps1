<#
install.ps1
Simple user-level installer for Flash compiler.
Usage: Run from extracted release folder (where `bin`, `include`, `lib` exist):
  powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1

Or from any directory:
  powershell -ExecutionPolicy Bypass -File C:\path\to\scripts\install.ps1 -SourceDir C:\path\to\extracted\flash

This copies `bin`, `include`, `lib`, `share` to `%LocalAppData%\Programs\Flash` and adds the `bin` folder to the user PATH.
#>
param(
  [string]$SourceDir = (Resolve-Path ..).Path,
  [string]$TargetDir = "$env:LOCALAPPDATA\Programs\Flash"
)

# If SourceDir doesn't contain 'bin', try one level deeper (for zip extraction)
if (-Not (Test-Path (Join-Path $SourceDir 'bin')) -and (Test-Path (Join-Path $SourceDir 'flash'))) {
  $SourceDir = Join-Path $SourceDir 'flash'
}

Write-Output "Installing Flash from '$SourceDir' to '$TargetDir'..."

if (-Not (Test-Path $SourceDir)) { throw "Source not found: $SourceDir" }
New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

# Copy known layout folders if they exist
foreach ($sub in @('bin','include','lib','share')) {
    $src = Join-Path $SourceDir $sub
    if (Test-Path $src) {
        $dst = Join-Path $TargetDir $sub
        Write-Output "Copying $sub to $dst"
        if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
        Copy-Item -Path $src -Destination $dst -Recurse -Force
    }
}

# Add to user PATH if not present (use registry to avoid setx truncation)
$binPath = Join-Path $TargetDir 'bin'
$envKey = 'HKCU:\Environment'
$currentPath = (Get-ItemProperty -Path $envKey -Name Path -ErrorAction SilentlyContinue).Path
if (-not $currentPath) { $currentPath = [Environment]::GetEnvironmentVariable('Path','User') }
if ($currentPath -notlike "*$binPath*") {
  $newPath = if ($currentPath) { "$currentPath;$binPath" } else { $binPath }
  if (-not (Test-Path $envKey)) { New-Item -Path $envKey | Out-Null }
  Set-ItemProperty -Path $envKey -Name Path -Value $newPath
  [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
  Write-Output "Added '$binPath' to user PATH. Restart shell to use."
} else {
  Write-Output "Path already contains '$binPath'."
}

Write-Output "Installation complete."
