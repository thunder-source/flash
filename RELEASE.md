# Flash Compiler Release Guide

This guide explains how to build, release, and publish Flash Compiler to GitHub, Chocolatey, Scoop, and WinGet.

## Quick Release Process

### 1. Prepare for Release

Update the version in `Makefile`:

```makefile
VERSION = X.Y.Z  # Change this line
```

### 2. Build Release Locally

```cmd
nmake clean
nmake release
```

This produces: `dist/flash-vX.Y.Z-windows-x64.zip`

### 3. Update Package Manifests

```powershell
nmake update-manifests VERSION=X.Y.Z
```

This automatically updates:
- `packaging/chocolatey/flash-compiler.nuspec`
- `packaging/scoop/flash.json`
- `packaging/winget/thunder-source.flash.yaml`

With the correct version and SHA256 hash.

### 4. Test Installation Locally

Extract and test the installer:

```powershell
# Extract release
Expand-Archive -Path "dist/flash-vX.Y.Z-windows-x64.zip" -DestinationPath "test_extract"

# Test install
.\scripts\install.ps1 -SourceDir "test_extract"

# Verify
flash -version  # (Once commands are implemented)

# Test uninstall
.\scripts\uninstall.ps1
```

### 5. Git Commit and Tag

```cmd
git add .
git commit -m "Release version X.Y.Z"
git tag -a vX.Y.Z -m "Flash Compiler version X.Y.Z"
git push origin main
git push origin vX.Y.Z
```

### 6. Automated: GitHub Actions

When you push the tag, GitHub Actions automatically:
- ✅ Assembles `flash.exe`
- ✅ Creates the release zip
- ✅ Creates a GitHub Release
- ✅ Uploads the zip as release asset

### 7. Manual: Publish to Package Managers

#### Chocolatey

```powershell
cd packaging\chocolatey
choco pack flash-compiler.nuspec
choco push flash-compiler.X.Y.Z.nupkg -s https://push.chocolatey.org/
# Enter your API key when prompted
# Wait 1-7 days for moderation
```

#### Scoop

Option A: Use your own bucket
```powershell
# Push updated flash.json to your bucket repo
git -C ../scoop-bucket add packaging/flash.json
git -C ../scoop-bucket commit -m "Flash v X.Y.Z"
git -C ../scoop-bucket push
```

Option B: Submit to official Main bucket
```powershell
# Fork https://github.com/ScoopInstaller/Main
# Add flash.json to bucket/
# Create PR with version and testing confirmation
```

#### WinGet

```powershell
# Fork https://github.com/microsoft/winget-pkgs
# Create directory: manifests/t/thunder-source/flash/X.Y.Z/
# Copy updated YAML files there
# Create PR with package description and link to release
```

## Files Updated by `update-manifests`

The `packaging/update-manifests.ps1` script updates:

### Chocolatey
- `packaging/chocolatey/flash-compiler.nuspec`
  - `<version>` element
  - Download URL (inferred from package content)

### Scoop
- `packaging/scoop/flash.json`
  - `"version"` field
  - `"hash"` field (SHA256 of zip)
  - `"url"` field (GitHub release URL)

### WinGet
- `packaging/winget/thunder-source.flash.yaml`
  - `PackageVersion` field
  - `InstallerUrl` field
  - `InstallerSha256` field

## Release Version Checklist

- [ ] Update `VERSION = X.Y.Z` in `Makefile`
- [ ] Run `nmake clean && nmake release`
- [ ] Run `nmake update-manifests`
- [ ] Test installation locally
- [ ] Commit and tag: `git tag -a vX.Y.Z`
- [ ] Push: `git push origin main && git push origin vX.Y.Z`
- [ ] Wait for GitHub Actions to complete
- [ ] Submit to Chocolatey (optional, recommended)
- [ ] Submit to Scoop (optional, recommended)
- [ ] Submit to WinGet (optional)

## Example Release (v0.1.0)

```powershell
# 1. Build
nmake clean
nmake release
# → Creates dist/flash-v0.1.0-windows-x64.zip (7.5 KB)

# 2. Update manifests
nmake update-manifests VERSION=0.1.0
# → Sets SHA256: D9CDF027A4CE07A8C024D76800A603D4A70616B3E405001F27A7A083415D3694

# 3. Test locally
Expand-Archive -Path "dist/flash-v0.1.0-windows-x64.zip" -DestinationPath "test"
.\scripts\install.ps1 -SourceDir "test"
# → Installed to C:\Users\{user}\AppData\Local\Programs\Flash

# 4. Commit and tag
git add .
git commit -m "Release v0.1.0"
git tag -a v0.1.0 -m "Flash Compiler v0.1.0"
git push origin main
git push origin v0.1.0

# 5. GitHub Actions runs automatically
# → Creates Release v0.1.0
# → Uploads flash-0.1.0-windows-x64.zip

# 6. Optional: Publish to package managers
# (See instructions in packaging/README.md)
```

## Troubleshooting

### Release build fails
- Ensure NASM is installed: `nasm -version`
- Check `bin/flash.asm` compiles: `nasm -f win64 bin/flash.asm -o build/test.obj`
- Ensure `include/` and `lib/` directories exist

### Update script fails
- Verify `packaging/` directory structure is intact
- Check file paths in error message
- Ensure ZIP file exists and is accessible

### GitHub Actions fails
- Check `.github/workflows/release.yml` is valid YAML
- Verify tag format matches `v*` (e.g., `v1.0.0`)
- Check runner has NASM installed (choco install step)

### Package manager submission fails
- **Chocolatey**: Verify nuspec XML is well-formed
- **Scoop**: Ensure JSON is valid, hash matches
- **WinGet**: Run validator: `wingetcreate validate manifests/t/thunder-source/flash/X.Y.Z`

## Useful Commands

```cmd
# Build and release
nmake release

# Update all manifests
nmake update-manifests VERSION=X.Y.Z

# Clean build artifacts
nmake clean

# Verify NASM works
nasm -version

# Test PowerShell scripts
powershell -NoProfile -ExecutionPolicy Bypass -File packaging\update-manifests.ps1 -Version 0.1.0 -ZipPath dist\flash-v0.1.0-windows-x64.zip
```

## Next Steps

After your first release:

1. **Monitor package approval** times (Chocolatey typically 1-7 days)
2. **Iterate on feedback** from package manager moderators
3. **Plan next release** with v0.2.0 (fix any issues found)
4. **Consider automation** (add auto-publish to Chocolatey in CI)

## Additional Resources

- **Chocolatey Docs**: https://docs.chocolatey.org/en-us/community-repository/community-packages-maintenance
- **Scoop Docs**: https://scoop.sh/
- **WinGet Docs**: https://github.com/microsoft/winget-pkgs
- **GitHub Releases**: https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository
