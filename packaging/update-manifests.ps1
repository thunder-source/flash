# packaging/update-manifests.ps1
# Helper script to update all package manager manifests with new version and hash

param(
  [Parameter(Mandatory=$true)]
  [string]$Version,
  
  [Parameter(Mandatory=$true)]
  [string]$ZipPath
)

if (-not (Test-Path $ZipPath)) {
  Write-Error "ZIP file not found: $ZipPath"
  exit 1
}

# Calculate SHA256 hash
$hash = (Get-FileHash $ZipPath -Algorithm SHA256).Hash
$size = (Get-Item $ZipPath).Length / 1MB

Write-Output "Updating manifests for version $Version"
Write-Output "SHA256: $hash"
Write-Output "Size: $([math]::Round($size, 2)) MB"

# Update Scoop manifest
$scoopPath = Join-Path $PSScriptRoot "scoop\flash.json"
$scoopJson = Get-Content $scoopPath | ConvertFrom-Json
$scoopJson.version = $Version
$scoopJson.architecture."64bit".hash = "sha256:$hash"
$scoopJson.architecture."64bit".url = "https://github.com/thunder-source/flash/releases/download/v$Version/flash-$Version-windows-x64.zip"
$scoopJson | ConvertTo-Json -Depth 10 | Set-Content $scoopPath
Write-Output "✓ Updated scoop/flash.json"

# Update Chocolatey nuspec
$chocoPath = Join-Path $PSScriptRoot "chocolatey\flash-compiler.nuspec"
$chocoContent = Get-Content $chocoPath -Raw
$chocoContent = $chocoContent -replace '<version>.*?</version>', "<version>$Version</version>"
Set-Content $chocoPath $chocoContent
Write-Output "✓ Updated chocolatey/flash-compiler.nuspec"

# Update WinGet manifest
$wingetPath = Join-Path $PSScriptRoot "winget\thunder-source.flash.yaml"
$wingetContent = Get-Content $wingetPath -Raw
$wingetContent = $wingetContent -replace 'PackageVersion:.*', "PackageVersion: $Version"
$wingetContent = $wingetContent -replace 'InstallerUrl:.*', "InstallerUrl: https://github.com/thunder-source/flash/releases/download/v$Version/flash-$Version-windows-x64.zip"
$wingetContent = $wingetContent -replace 'InstallerSha256:.*', "InstallerSha256: $hash"
Set-Content $wingetPath $wingetContent
Write-Output "✓ Updated winget/thunder-source.flash.yaml"

Write-Output ""
Write-Output "✓ All manifests updated successfully"
Write-Output ""
Write-Output "Next steps:"
Write-Output "1. Chocolatey: Run 'choco pack' in packaging\chocolatey and submit"
Write-Output "2. Scoop: Push scoop/flash.json to your bucket repo"
Write-Output "3. WinGet: Push YAML to https://github.com/microsoft/winget-pkgs"
