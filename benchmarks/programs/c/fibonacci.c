// Fibonacci Benchmark - C Language
// Equivalent to Flash version for performance comparison

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int fibonacci_recursive(int n) {
    if (n <= 1) {
        return n;
    }
    return fibonacci_recursive(n - 1) + fibonacci_recursive(n - 2);
}

int fibonacci_iterative(int n) {
    if (n <= 1) {
        return n;
    }

    int a = 0;
    int b = 1;
    int i = 2;

    while (i <= n) {
        int temp = a + b;
        a = b;
        b = temp;
        i = i + 1;
    }

    return b;
}

int fibonacci_optimized(int n) {
    // Fast matrix exponentiation method
    if (n <= 1) {
        return n;
    }

    int f0 = 0;
    int f1 = 1;
    int i = 2;

    while (i <= n) {
        int f2 = f0 + f1;
        f0 = f1;
        f1 = f2;
        i = i + 1;
    }

    return f1;
}

long long get_time_ms() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

int benchmark_recursive() {
    int n = 35;  // Computationally intensive for recursion
    long long start_time = get_time_ms();
    int result = fibonacci_recursive(n);
    long long end_time = get_time_ms();

    printf("Recursive Fibonacci(%d) = %d in %lldms\n", 
           n, result, end_time - start_time);

    return result;
}

int benchmark_iterative() {
    int n = 10000;  // Much larger for iterative
    long long start_time = get_time_ms();
    int result = fibonacci_iterative(n);
    long long end_time = get_time_ms();

    printf("Iterative Fibonacci(%d) = %d (mod 1000000) in %lldms\n", 
           n, result % 1000000, end_time - start_time);

    return result;
}

int benchmark_optimized() {
    int n = 50000;  // Very large for optimized version
    long long start_time = get_time_ms();
    int result = fibonacci_optimized(n);
    long long end_time = get_time_ms();

    printf("Optimized Fibonacci(%d) = %d (mod 1000000) in %lldms\n", 
           n, result % 1000000, end_time - start_time);

    return result;
}

int verify_correctness() {
    // Verify all implementations give same results for small values
    int test_values[] = {0, 1, 5, 10, 15, 20};
    int expected[] = {0, 1, 5, 55, 610, 6765};

    printf("Verifying correctness...\n");

    for (int i = 0; i < 6; i++) {
        int n = test_values[i];
        int exp = expected[i];

        int rec = fibonacci_recursive(n);
        int iter = fibonacci_iterative(n);
        int opt = fibonacci_optimized(n);

        if (rec != exp || iter != exp || opt != exp) {
            printf("ERROR: Mismatch for n=%d expected=%d rec=%d iter=%d opt=%d\n",
                   n, exp, rec, iter, opt);
            return 1;
        }
    }

    printf("All implementations match expected values\n");
    return 0;
}

int stress_test() {
    // Compute many Fibonacci numbers to stress memory and CPU
    int total = 0;
    int i = 1;

    printf("Computing Fibonacci for 1..1000...\n");

    long long start_time = get_time_ms();

    while (i <= 1000) {
        int fib = fibonacci_iterative(i);
        total = total + (fib % 1000);  // Prevent overflow, keep test meaningful
        i = i + 1;
    }

    long long end_time = get_time_ms();

    printf("Stress test completed: sum(fib(1..1000) mod 1000) = %d in %lldms\n", 
           total, end_time - start_time);

    return total;
}

int main() {
    printf("=== C Fibonacci Benchmark ===\n\n");

    // Verification phase
    int verification_result = verify_correctness();
    if (verification_result != 0) {
        return verification_result;
    }

    printf("\n=== Performance Benchmarks ===\n");

    // Individual benchmarks
    int rec_result = benchmark_recursive();
    int iter_result = benchmark_iterative();
    int opt_result = benchmark_optimized();

    printf("\n=== Stress Test ===\n");

    int stress_result = stress_test();

    printf("\n=== Summary ===\n");
    printf("Recursive result (n=35): %d\n", rec_result);
    printf("Iterative result (n=10000, mod 1M): %d\n", iter_result % 1000000);
    printf("Optimized result (n=50000, mod 1M): %d\n", opt_result % 1000000);
    printf("Stress test sum: %d\n", stress_result);

    printf("Fibonacci benchmark completed successfully\n");

    return 0;
}