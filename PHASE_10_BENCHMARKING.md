# Flash Compiler - Phase 10: Benchmarking & Profiling

## Overview

Phase 10 implements comprehensive benchmarking and profiling infrastructure to validate Flash compiler's performance goals against industry-standard compilers (GCC, Clang, MSVC).

## Performance Goals

- **Compilation Speed**: 2-5x faster than GCC/Clang
- **Generated Code**: Within 95-100% of GCC -O3 performance
- **Memory Usage**: Lower than mainstream compilers
- **Binary Size**: Smaller than equivalent C/C++ programs

## Quick Start

### 1. Validate Framework Setup

```powershell
cd benchmarks
.\test_framework.ps1
```

### 2. Run Quick Benchmark

```powershell
# Test both compilation and runtime performance
.\quick_bench.ps1 -Test both -Iterations 3 -Verbose
```

### 3. Detailed Benchmarks

```powershell
# Compilation speed tests
.\tools\compile_bench.ps1 -Program fibonacci -GenerateReport

# Runtime performance tests
.\tools\runtime_bench.ps1 -Program fibonacci -GenerateReport

# Full benchmark suite
.\tools\runner.ps1 -Program all -StoreResults
```

### 4. Analyze Results

```powershell
# Compare latest results
.\tools\compare.ps1 -Type compilation
.\tools\compare.ps1 -Type runtime -ShowTrends

# Export results
.\tools\compare.ps1 -Type compilation -OutputFormat csv
```

## Benchmark Programs

### Algorithm Benchmarks

1. **fibonacci** - Recursive/iterative Fibonacci (CPU intensive)
2. **prime_sieve** - Sieve of Eratosthenes (memory intensive)
3. **quicksort** - In-place sorting algorithm
4. **string_search** - Boyer-Moore pattern matching

### Numerical Benchmarks

5. **matrix_multiply** - Dense matrix operations
6. **numerical** - Floating-point computations

### Data Structure Benchmarks

7. **hash_table** - Hash operations with collision handling
8. **binary_tree** - Tree traversal and manipulation

### Compilation Stress Tests

9. **large_file** - Single large source (10K+ lines)
10. **many_functions** - 1000+ function definitions
11. **deep_recursion** - Complex call chains
12. **complex_expressions** - Nested arithmetic

## Framework Architecture

```
benchmarks/
├── README.md                   # Framework documentation
├── quick_bench.ps1            # Fast development testing
├── test_framework.ps1         # Validate setup
├── programs/                  # Benchmark sources
│   ├── flash/                # Flash language versions
│   ├── c/                    # Equivalent C versions
│   └── results/              # Expected outputs
├── tools/                    # Benchmarking utilities
│   ├── runner.ps1            # Main benchmark orchestrator
│   ├── compile_bench.ps1     # Compilation speed tests
│   ├── runtime_bench.ps1     # Runtime performance tests
│   └── compare.ps1           # Results analysis
├── results/                  # Generated results
│   ├── compilation/          # Compile-time metrics
│   ├── runtime/              # Runtime metrics
│   └── memory/               # Memory profiling
└── config/                   # Configuration
    └── benchmarks.json       # Program definitions
```

## Metrics Measured

### Compilation Speed
- **Parse time** - Lexing + parsing duration
- **Semantic time** - Type checking + analysis
- **Codegen time** - IR generation + optimization + assembly
- **Total time** - End-to-end compilation
- **Memory peak** - Maximum memory usage
- **Throughput** - Lines/bytes per second

### Runtime Performance
- **Execution time** - Program runtime (wall clock)
- **CPU time** - User + system time
- **Memory usage** - Peak working set
- **Correctness** - Output validation
- **Success rate** - Reliable execution percentage

### Quality Assessment
- **Optimization effectiveness** - vs unoptimized versions  
- **Performance consistency** - Low standard deviation
- **Regression detection** - Performance changes over time

## Usage Examples

### Basic Performance Check

```powershell
# Quick compilation speed test
.\quick_bench.ps1 -Test compilation -Iterations 5

# Output:
# Flash average: 45.2ms
# GCC -O0 average: 123.8ms
# Flash is 2.7x faster than GCC -O0
```

### Detailed Program Analysis

```powershell
# Comprehensive fibonacci benchmark
.\tools\runner.ps1 -Program fibonacci -Iterations 10 -StoreResults -Verbose

# Results show:
# - Flash compilation: 38ms average
# - Flash runtime: 145ms average (95.2% of GCC -O3)
# - Memory usage: 12.3MB peak
# - All correctness tests passed
```

### Trend Analysis

```powershell
# Compare performance over time
.\tools\compare.ps1 -Type runtime -ShowTrends

# Output shows:
# Flash vs GCC -O3 trend: 8.2% improvement over last 5 runs
# Goal achievement: 7/8 programs (87.5%) meet performance targets
```

### Continuous Integration

```powershell
# Automated performance regression testing
.\tools\runner.ps1 -Program all -StoreResults -GitHash $(git rev-parse HEAD)

# Store results with git commit for regression tracking
# Alert if performance degrades >10% from baseline
```

## Interpreting Results

### Compilation Speed Goals

✅ **Excellent**: Flash 3x+ faster than GCC -O0  
✅ **Good**: Flash 2-3x faster than GCC -O0  
⚠️ **Acceptable**: Flash 1.5-2x faster than GCC -O0  
❌ **Poor**: Flash slower than GCC -O0  

### Runtime Performance Goals

✅ **Excellent**: Flash within 105% of GCC -O3  
✅ **Good**: Flash within 120% of GCC -O3  
⚠️ **Acceptable**: Flash within 150% of GCC -O3  
❌ **Poor**: Flash >150% of GCC -O3  

### Memory Usage Goals

✅ **Excellent**: Flash uses <50% memory vs GCC  
✅ **Good**: Flash uses 50-75% memory vs GCC  
⚠️ **Acceptable**: Flash uses 75-100% memory vs GCC  
❌ **Poor**: Flash uses >100% memory vs GCC  

## Configuration

Edit `config/benchmarks.json` to:

- Add new benchmark programs
- Modify compiler arguments
- Adjust performance targets
- Configure reporting options

Example program definition:
```json
{
  "name": "my_benchmark",
  "description": "Custom algorithm test",
  "category": "algorithms",
  "complexity": "cpu_intensive",
  "expected_runtime_ms": 100,
  "validation": {
    "output_contains": ["benchmark completed"],
    "exit_code": 0
  }
}
```

## Adding New Benchmarks

### 1. Create Flash Version
```flash
// programs/flash/my_benchmark.fl
fn main() -> i32 {
    // Your benchmark implementation
    print_str("My benchmark completed successfully");
    return 0;
}
```

### 2. Create C Equivalent
```c
// programs/c/my_benchmark.c
#include <stdio.h>

int main() {
    // Equivalent C implementation
    printf("My benchmark completed successfully\n");
    return 0;
}
```

### 3. Define Expected Output
```
// programs/results/my_benchmark.txt
My benchmark completed successfully
```

### 4. Update Configuration
Add entry to `config/benchmarks.json` programs array.

### 5. Test Integration
```powershell
.\tools\runner.ps1 -Program my_benchmark -Verbose
```

## Troubleshooting

### Common Issues

**No compilers found**
- Ensure GCC/Clang/MSVC are in PATH
- Install MinGW-w64 or Visual Studio Build Tools

**Flash compiler not available**
- Build Flash compiler first: `.\scripts\build.bat`
- Verify `flash.exe` in project root or PATH

**Permission errors**
- Run PowerShell as Administrator
- Check antivirus exclusions for benchmark files

**Inconsistent timing**
- Close other applications during benchmarking
- Run multiple iterations (increase -Iterations)
- Use dedicated test machine if possible

### Debug Mode

```powershell
# Enable detailed debugging
.\tools\runner.ps1 -Program fibonacci -Debug -Verbose

# Shows:
# - Detailed compilation steps
# - Intermediate file locations
# - Command-line arguments used
# - Raw performance measurements
```

## Performance Baseline Results

*Expected performance ranges on modern hardware (4+ cores, 8GB+ RAM):*

| Program | Flash Compile | GCC -O0 Compile | Flash Runtime | GCC -O3 Runtime |
|---------|---------------|-----------------|---------------|-----------------|
| fibonacci | 20-60ms | 80-200ms | 100-300ms | 90-280ms |
| prime_sieve | 30-80ms | 90-250ms | 50-150ms | 45-140ms |
| quicksort | 25-70ms | 85-220ms | 20-80ms | 18-75ms |
| matrix_multiply | 40-100ms | 120-300ms | 200-600ms | 180-550ms |

*Results vary by system configuration and compiler versions.*

## Integration with Development

### Pre-commit Hook
```bash
# Run performance regression test before commits
.\benchmarks\quick_bench.ps1 -Test both
if ($LASTEXITCODE -ne 0) {
    Write-Error "Performance regression detected"
    exit 1
}
```

### CI/CD Integration
```yaml
# GitHub Actions example
- name: Run Performance Benchmarks
  run: |
    cd benchmarks
    .\tools\runner.ps1 -Program fibonacci,prime_sieve -StoreResults
    .\tools\compare.ps1 -Type compilation -OutputFormat json
```

### Release Validation
```powershell
# Full performance validation before release
.\tools\runner.ps1 -Program all -Iterations 10 -StoreResults
.\tools\compare.ps1 -Type compilation -ShowTrends
.\tools\compare.ps1 -Type runtime -ShowTrends

# Verify all performance targets are met
# Generate release performance report
```

## Future Enhancements

### Planned Features
- **Memory profiling** - Detailed heap/stack analysis
- **Cache performance** - L1/L2/L3 cache hit rates
- **Profile-guided optimization** - Learn from runtime data
- **Cross-platform** - Linux and macOS support
- **Web dashboard** - Real-time performance monitoring
- **Automated alerts** - Performance regression notifications

### Advanced Analysis
- **Statistical analysis** - Confidence intervals, significance tests
- **Performance modeling** - Predict performance on different hardware
- **Bottleneck identification** - Hot path analysis
- **Optimization recommendations** - Automated suggestions

## Contributing

1. Add benchmark programs following the established patterns
2. Ensure both Flash and C versions produce identical output
3. Test on multiple systems and compiler versions
4. Update documentation for new features
5. Validate performance targets are realistic and achievable

## Support

- **Issues**: Report bugs in benchmark framework
- **Discussions**: Performance optimization strategies
- **Contributions**: New benchmark programs and analysis tools
- **Documentation**: Improvements to setup and usage guides

---

**Phase 10 Status**: ✅ Framework Complete, 📊 Data Collection In Progress

The benchmarking infrastructure is production-ready and provides comprehensive performance validation for the Flash compiler project.