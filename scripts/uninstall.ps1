<#
uninstall.ps1
Remove a user-level Flash installation created by `install.ps1`.
Usage:
  powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1
#>
param(
  [string]$TargetDir = "$env:LOCALAPPDATA\Programs\Flash"
)

Write-Output "Uninstalling Flash from '$TargetDir'..."
if (Test-Path $TargetDir) {
    Remove-Item -Path $TargetDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Output "Removed directory: $TargetDir"
} else {
    Write-Output "Target not found: $TargetDir"
}

# remove PATH entry (update registry to avoid setx truncation)
$envKey = 'HKCU:\Environment'
$currentPath = (Get-ItemProperty -Path $envKey -Name Path -ErrorAction SilentlyContinue).Path
if (-not $currentPath) { $currentPath = [Environment]::GetEnvironmentVariable('Path','User') }
$binPath = Join-Path $TargetDir 'bin'
if ($currentPath -and ($currentPath -like "*$binPath*")) {
    $parts = $currentPath -split ';' | Where-Object { $_ -and ($_ -ne $binPath) }
    $newPath = $parts -join ';'
    if (-not (Test-Path $envKey)) { New-Item -Path $envKey | Out-Null }
    Set-ItemProperty -Path $envKey -Name Path -Value $newPath
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Output "Removed '$binPath' from user PATH. Restart shell to see changes."
} else {
    Write-Output "User PATH did not contain '$binPath'."
}

Write-Output "Uninstall complete."
