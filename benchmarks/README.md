# Flash Compiler Benchmarking Suite

## Overview

This benchmarking suite validates Flash compiler's performance goals:

- **Compilation Speed**: 2-5x faster than GCC/Clang/MSVC
- **Generated Code**: Within 95-100% of GCC -O3 performance
- **Memory Usage**: Lower than mainstream compilers
- **Binary Size**: Smaller than equivalent C/C++ programs

## Structure

```
benchmarks/
├── README.md                   # This file
├── programs/                   # Benchmark programs
│   ├── flash/                 # Flash language versions
│   ├── c/                     # Equivalent C versions
│   └── results/               # Expected outputs
├── tools/                     # Benchmarking utilities
│   ├── runner.ps1             # Main benchmark runner
│   ├── compile_bench.ps1      # Compilation speed tests
│   ├── runtime_bench.ps1      # Runtime performance tests
│   ├── memory_bench.ps1       # Memory usage profiling
│   └── compare.ps1            # Results comparison
├── results/                   # Benchmark results
│   ├── compilation/           # Compilation speed results
│   ├── runtime/               # Runtime performance results
│   └── memory/                # Memory usage results
└── config/                    # Benchmark configurations
    ├── compilers.json         # Compiler settings
    └── benchmarks.json        # Benchmark definitions
```

## Quick Start

### Prerequisites

- Flash compiler (`flash.exe`)
- GCC (MinGW-w64 or MSYS2)
- Clang (optional)
- MSVC (Visual Studio or Build Tools)
- PowerShell 5.1+

### Run All Benchmarks

```powershell
.\tools\runner.ps1
```

### Run Specific Benchmark Types

```powershell
# Compilation speed only
.\tools\compile_bench.ps1

# Runtime performance only  
.\tools\runtime_bench.ps1

# Memory usage profiling
.\tools\memory_bench.ps1
```

### View Results

```powershell
# Compare results across compilers
.\tools\compare.ps1 -Type compilation
.\tools\compare.ps1 -Type runtime
.\tools\compare.ps1 -Type memory
```

## Benchmark Programs

### Core Algorithms (programs/*)

1. **fibonacci** - Recursive and iterative Fibonacci calculation
2. **prime_sieve** - Sieve of Eratosthenes prime number generation
3. **quicksort** - In-place quicksort implementation
4. **matrix_multiply** - Dense matrix multiplication
5. **hash_table** - Hash table with collision handling
6. **binary_tree** - Binary search tree operations
7. **string_search** - Boyer-Moore string searching
8. **numerical** - Floating point mathematical computations

### Compilation Tests

1. **large_file** - Single large source file (10K+ lines)
2. **many_functions** - Many small functions (1000+)
3. **deep_recursion** - Deep call chains
4. **complex_expressions** - Nested arithmetic expressions
5. **template_heavy** - Generic/template-like constructs

## Metrics Measured

### Compilation Speed

- **Parse time** - Lexing + parsing duration
- **Semantic time** - Type checking + analysis
- **Codegen time** - IR generation + optimization + assembly
- **Total time** - End-to-end compilation
- **Memory peak** - Maximum memory usage during compilation
- **Throughput** - Lines of code per second

### Runtime Performance

- **Execution time** - Program runtime (wall clock)
- **CPU cycles** - Processor cycles consumed
- **Cache performance** - L1/L2/L3 cache hit rates
- **Memory allocations** - Heap allocations and frees
- **Binary size** - Executable file size

### Quality Metrics

- **Correctness** - Output matches reference
- **Optimization effectiveness** - vs unoptimized version
- **Regression detection** - Performance changes over time

## Usage Examples

### Benchmark Single Program

```powershell
# Compile fibonacci with all compilers and measure
.\tools\runner.ps1 -Program fibonacci -Verbose

# Results saved to:
# results/compilation/fibonacci_YYYY-MM-DD.json
# results/runtime/fibonacci_YYYY-MM-DD.json
```

### Custom Benchmark

```powershell
# Add your program to programs/flash/ and programs/c/
# Then run:
.\tools\runner.ps1 -Program my_program
```

### Continuous Benchmarking

```powershell
# Run benchmarks and store results with git commit hash
.\tools\runner.ps1 -StoreResults -GitHash $(git rev-parse HEAD)
```

## Interpreting Results

### Good Performance Indicators

- **Compilation**: Flash 2-5x faster than GCC/Clang
- **Runtime**: Flash within 5% of GCC -O3 performance
- **Memory**: Flash uses <50% memory vs other compilers
- **Binary**: Flash produces smaller executables

### Warning Indicators

- **Compilation**: Flash slower than GCC -O0
- **Runtime**: Flash >20% slower than GCC -O3
- **Memory**: Flash uses more memory than expected
- **Binary**: Flash produces significantly larger binaries

## Adding New Benchmarks

### 1. Create Flash Version

```flash
// programs/flash/my_benchmark.fl
fn main() -> i32 {
    // Your benchmark code
    return 0;
}
```

### 2. Create C Version

```c
// programs/c/my_benchmark.c
int main() {
    // Equivalent C code
    return 0;
}
```

### 3. Add Expected Output

```
// programs/results/my_benchmark.txt
Expected program output here
```

### 4. Update Configuration

Edit `config/benchmarks.json` to include your benchmark.

## Performance Targets

Based on Flash compiler goals:

| Metric | Target | Baseline |
|--------|---------|----------|
| Compilation Speed | 2-5x faster | GCC -O0 |
| Runtime Performance | 95-100% | GCC -O3 |
| Memory Usage | <50% | GCC peak memory |
| Binary Size | Smaller | GCC output |
| Build Time | <10s | Total benchmark suite |

## Troubleshooting

### Common Issues

1. **Compiler not found**: Ensure all compilers are in PATH
2. **Permission errors**: Run PowerShell as Administrator
3. **Timing inconsistent**: Run multiple iterations
4. **Memory profiling fails**: Install Windows Performance Toolkit

### Debug Mode

```powershell
.\tools\runner.ps1 -Debug -Verbose
```

Shows detailed execution steps and intermediate results.

## Contributing

1. Add new benchmark programs following the structure
2. Ensure both Flash and C versions produce identical output
3. Update documentation for new benchmarks
4. Run full suite to verify no regressions

## Results Archive

Historical benchmark results are stored in `results/` with timestamps and git hashes for regression analysis and performance tracking over time.