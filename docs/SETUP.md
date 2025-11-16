# Flash Compiler - Setup Guide

## Quick Setup for Windows

### Step 1: Install NASM

**Option A: Direct Download (Recommended)**

1. Go to https://www.nasm.us/pub/nasm/releasebuilds/
2. Navigate to latest stable version (e.g., 2.16.01/)
3. Download `nasm-X.XX.XX-installer-x64.exe`
4. Run the installer
5. **Important**: Check "Add NASM to PATH" during installation

**Option B: Chocolatey Package Manager**

```powershell
choco install nasm
```

**Option C: Manual Installation**

1. Download `nasm-X.XX.XX-win64.zip`
2. Extract to `C:\Program Files\NASM\`
3. Add to PATH:
   - Open System Properties → Environment Variables
   - Edit "Path" under System Variables
   - Add `C:\Program Files\NASM`
   - Click OK

**Verify Installation:**

```batch
nasm -v
```

Expected output: `NASM version 2.16.01 compiled on Oct  2 2022`

### Step 2: Install Microsoft Linker

**Option A: Visual Studio (Recommended for Development)**

1. Download Visual Studio Community 2022 (free)
   - https://visualstudio.microsoft.com/downloads/
2. Run installer
3. Select "Desktop development with C++"
4. Install (requires ~10 GB)

**Option B: Build Tools Only (Minimal Install)**

1. Download "Build Tools for Visual Studio 2022"
   - https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
2. Run installer
3. Select "C++ build tools"
4. Install (requires ~7 GB)

**Option C: Use Developer Command Prompt**

After installing Visual Studio:
- Search for "Developer Command Prompt for VS 2022"
- Run all build commands from this prompt
- `link.exe` will be in PATH automatically

**Verify Installation:**

```batch
link /?
```

Expected: Microsoft linker help text

### Step 3: Verify Setup

Open Command Prompt (or PowerShell) and run:

```batch
cd F:\flash
nasm -v
link /?
```

Both commands should work. If not, review Step 1 and 2.

## Quick Start - Build and Test

```batch
cd F:\flash
build_test.bat
flash_test.exe
```

**Expected Output:**
```
========================================
Flash Compiler - Comprehensive Parser Test
========================================

Initializing...
Testing: Test 1: Simple Function
Parsing... [PASS] Test 1: Simple Function
...
Total Tests: 8
Passed: 8
Failed: 0
```

## Alternative: Using Visual Studio Developer Command Prompt

If you have Visual Studio installed:

1. Search for "Developer Command Prompt for VS 2022"
2. Open it (runs as admin if needed)
3. Navigate to Flash directory:
   ```batch
   cd F:\flash
   ```
4. Build and test:
   ```batch
   build_test.bat
   flash_test.exe
   ```

This method automatically sets up all paths for `link.exe` and other tools.

## Troubleshooting

### NASM Not Found

**Problem:** `'nasm' is not recognized as an internal or external command`

**Solutions:**

1. **Verify Installation:**
   ```batch
   where nasm
   ```
   If not found, NASM isn't in PATH.

2. **Add to PATH Manually:**
   - Find NASM installation directory (usually `C:\Program Files\NASM`)
   - Add to PATH environment variable
   - Restart Command Prompt

3. **Use Full Path:**
   ```batch
   "C:\Program Files\NASM\nasm.exe" -f win64 src\lexer.asm -o build\lexer.obj
   ```

### Link Not Found

**Problem:** `'link' is not recognized as an internal or external command`

**Solutions:**

1. **Use Developer Command Prompt:**
   - Start Menu → Visual Studio 2022 → Developer Command Prompt
   - Run build from there

2. **Add VS Tools to PATH:**
   Find Visual Studio installation:
   ```
   C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\XX.XX.XXXXX\bin\Hostx64\x64
   ```
   Add this directory to PATH.

3. **Use Full Path to Link:**
   Modify build scripts to use full path to `link.exe`

### Build Errors

**Problem:** `Error A2008: syntax error`

**Cause:** Old NASM version

**Solution:** Update to NASM 2.15 or newer

**Problem:** `unresolved external symbol`

**Cause:** Missing kernel32.lib

**Solution:** 
- Install Windows SDK
- Or use Visual Studio Developer Command Prompt

### Runtime Errors

**Problem:** Program crashes immediately

**Solution:**
1. Check Windows version (must be Windows 10/11 x64)
2. Ensure running as administrator (for VirtualAlloc)
3. Check antivirus isn't blocking execution

## Directory Structure After Setup

```
F:\flash\
├── src\              # Source files (.asm)
├── build\            # Compiled object files (.obj) [created by build]
├── examples\         # Sample Flash programs (.fl)
├── build.bat         # Build scripts
├── build_test.bat
├── flash_test.exe    # Compiled test executables [created by build]
├── parser_test.exe
└── README.md         # Documentation
```

## Environment Variables

Add these to your system PATH for convenience:

1. NASM: `C:\Program Files\NASM`
2. Link: `C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\XX.XX.XXXXX\bin\Hostx64\x64`

Or simply use Visual Studio Developer Command Prompt which sets everything up.

## Testing Your Setup

Run this complete test:

```batch
@echo off
echo Testing Flash Compiler Setup...
echo.

echo [1/3] Checking NASM...
nasm -v
if errorlevel 1 (
    echo FAILED: NASM not found
    exit /b 1
)
echo OK

echo [2/3] Checking Link...
link /? > nul
if errorlevel 1 (
    echo FAILED: Link not found
    exit /b 1
)
echo OK

echo [3/3] Building compiler...
call build_test.bat
if errorlevel 1 (
    echo FAILED: Build failed
    exit /b 1
)
echo OK

echo.
echo SUCCESS: Setup complete!
echo Run 'flash_test.exe' to test the compiler.
```

Save as `test_setup.bat` and run.

## Next Steps After Setup

1. **Run Tests:** `flash_test.exe`
2. **Review Examples:** Check `examples/` directory
3. **Read Documentation:** Review `TESTING.md`
4. **Start Coding:** Write your own `.fl` programs

## Getting Help

If you encounter issues:

1. Check this SETUP.md file
2. Review TESTING.md for troubleshooting
3. Ensure Windows 10/11 x64
4. Verify NASM version 2.15+
5. Try Visual Studio Developer Command Prompt

## System Requirements

- **OS:** Windows 10/11 x64 (64-bit)
- **Disk:** ~100 MB for compiler, ~10 GB for Visual Studio
- **RAM:** 2 GB minimum, 4 GB recommended
- **CPU:** Any modern x86-64 processor

## Optional Tools

For development:

- **Text Editor:** VS Code with ASM extensions
- **Debugger:** x64dbg for assembly debugging
- **Profiler:** Very Sleepy for performance analysis
- **Hex Editor:** HxD for binary inspection

## Build Performance

Expected build times on modern hardware:

- **Initial Setup:** ~15 minutes (installing NASM + VS)
- **First Build:** ~5 seconds
- **Incremental Build:** ~2 seconds
- **Full Rebuild:** ~5 seconds

Flash compiler is designed to be FAST!
