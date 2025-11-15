# Flash Compiler - Package Manager Integration

This directory contains manifests and setup files for distributing Flash Compiler via popular Windows package managers.

## Directory Structure

```
packaging/
├── chocolatey/          # Chocolatey package files
│   ├── flash-compiler.nuspec
│   └── tools/
│       ├── chocolateyInstall.bat
│       └── chocolateyUninstall.bat
├── scoop/               # Scoop bucket manifest
│   └── flash.json
├── winget/              # Windows Package Manager manifest
│   └── thunder-source.flash.yaml
└── README.md            # This file
```

## Installation Methods

Users can install Flash using any of these methods:

### Option 1: Chocolatey (Recommended for Windows)

```powershell
choco install flash-compiler
```

### Option 2: Scoop

First, add the Flash bucket:

```powershell
scoop bucket add flash https://github.com/thunder-source/flash-bucket
scoop install flash
```

### Option 3: WinGet

```powershell
winget install thunder-source.flash
```

### Option 4: Manual Installation

Download the latest release from GitHub:

```powershell
Invoke-WebRequest -Uri "https://github.com/thunder-source/flash/releases/download/v0.1.0/flash-0.1.0-windows-x64.zip" -OutFile "flash.zip"
Expand-Archive -Path "flash.zip" -DestinationPath "$env:DOWNLOADS"
& "$env:DOWNLOADS\flash\scripts\install.ps1" -SourceDir "$env:DOWNLOADS\flash"
```

## Publishing Instructions

### Chocolatey Community Repository

1. **Prerequisites:**

   - Chocolatey CLI (`choco` command)
   - Account on https://community.chocolatey.org/
   - API key from your account

2. **Build the package:**

   ```powershell
   cd packaging\chocolatey
   choco pack flash-compiler.nuspec
   ```

3. **Submit:**

   ```powershell
   choco push flash-compiler.0.1.0.nupkg -s https://push.chocolatey.org/
   ```

   When prompted, enter your API key.

4. **Moderation:** Wait for package review (typically 1-7 days). You'll receive email confirmation.

**Reference:** https://docs.chocolatey.org/en-us/community-repository/community-packages-maintenance

### Scoop Bucket

1. **Create a separate repository** (recommended):

   ```
   https://github.com/thunder-source/flash-bucket
   ```

2. **Copy the manifest** to the bucket:

   ```
   bucket/
   └── flash.json
   ```

3. **Test the bucket:**

   ```powershell
   scoop bucket add flash https://github.com/thunder-source/flash-bucket
   scoop install flash
   ```

4. **Optional: Submit to official bucket**
   - Fork https://github.com/ScoopInstaller/Main
   - Add `flash.json` to `bucket/`
   - Create a pull request with description and testing confirmation

**Reference:** https://scoop.sh/#/

### Windows Package Manager (WinGet)

1. **Fork** https://github.com/microsoft/winget-pkgs

2. **Create the manifest structure:**

   ```
   manifests/
   └── t/
       └── thunder-source/
           └── flash/
               └── 0.1.0/
                   ├── thunder-source.flash.yaml
                   ├── thunder-source.flash.installer.yaml (optional)
                   └── thunder-source.flash.locale.en-US.yaml (optional)
   ```

3. **Validate manifest:**

   ```powershell
   wingetcreate validate manifests\t\thunder-source\flash\0.1.0
   ```

4. **Create a pull request** on winget-pkgs with:
   - Clear description of the package
   - Link to official repository
   - Confirmation that binary is signed (if applicable)

**Reference:** https://github.com/microsoft/winget-pkgs

## Version Management

When releasing a new version:

1. **Update version** in all manifests:

   - `flash-compiler.nuspec` → `<version>`
   - `flash.json` (Scoop) → `"version"`
   - `thunder-source.flash.yaml` (WinGet) → `PackageVersion`

2. **Update download URLs** to point to the new release:

   ```
   https://github.com/thunder-source/flash/releases/download/vX.Y.Z/flash-X.Y.Z-windows-x64.zip
   ```

3. **Calculate SHA256 hash** of the release zip:

   ```powershell
   (Get-FileHash "dist\flash-X.Y.Z-windows-x64.zip" -Algorithm SHA256).Hash
   ```

4. **Update manifests** with the new hash:
   - Chocolatey: Not required for community repo (auto-detected)
   - Scoop: `"hash"` field
   - WinGet: `InstallerSha256` field

## Automated Publishing (Future)

The GitHub Actions workflow (`.github/workflows/release.yml`) currently:

- ✅ Builds on tag push (`v*`)
- ✅ Creates release on GitHub
- ⏳ Can be extended to auto-publish to Chocolatey, Scoop, etc.

To enable automatic publishing:

1. **For Chocolatey:**

   - Add `CHOCOLATEY_API_KEY` secret to GitHub
   - Add `choco push` step to workflow

2. **For Scoop:**

   - Set up auto-sync from this repo to your bucket repo
   - Or add workflow step to push manifest to bucket

3. **For WinGet:**
   - Manually submit or automate via `wingetcreate` tool in workflow

## File Descriptions

### chocolatey/

- **flash-compiler.nuspec**: Package metadata and dependencies
- **tools/chocolateyInstall.bat**: Installation script
- **tools/chocolateyUninstall.bat**: Uninstallation script

### scoop/

- **flash.json**: Manifest with download URL and hash
  - Used by Scoop to verify and extract packages
  - Supports auto-updates via GitHub releases

### winget/

- **thunder-source.flash.yaml**: WinGet package manifest
  - Describes package identity, version, installers
  - Can be split into multiple YAML files for complex packages

## Troubleshooting

### Chocolatey

- **Package validation fails**: Ensure `nuspec` XML is well-formed
- **Hash mismatch**: Use `choco download flash-compiler` to verify
- **Already exists error**: Submit as a new version to update

### Scoop

- **Bucket not found**: Verify bucket URL is correct
- **Checksum mismatch**: Recalculate hash from release zip
- **Auto-update fails**: Check GitHub releases exist with tag format `vX.Y.Z`

### WinGet

- **Validation error**: Run validator against manifest
- **Installer not found**: Verify URL is accessible
- **SHA256 mismatch**: Recalculate from actual file

## Questions?

For package management questions, refer to:

- **Chocolatey**: https://github.com/chocolatey/choco/discussions
- **Scoop**: https://github.com/ScoopInstaller/Scoop/discussions
- **WinGet**: https://github.com/microsoft/winget-pkgs/discussions
