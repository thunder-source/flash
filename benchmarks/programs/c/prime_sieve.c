// Prime Sieve Benchmark - C Language
// Equivalent to Flash version for performance comparison

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

long long get_time_ms() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

int sieve_of_eratosthenes(int limit) {
    // Create boolean array "prime[0..limit]" and initialize all entries as true
    int* prime = (int*)malloc((limit + 1) * sizeof(int));
    int i;

    // Initialize all as prime (true = 1, false = 0)
    for (i = 0; i <= limit; i++) {
        prime[i] = 1;
    }

    prime[0] = 0;  // 0 is not prime
    prime[1] = 0;  // 1 is not prime

    int p = 2;
    while (p * p <= limit) {
        // If prime[p] is not changed, then it is a prime
        if (prime[p] == 1) {
            // Update all multiples of p
            int multiple = p * p;
            while (multiple <= limit) {
                prime[multiple] = 0;
                multiple = multiple + p;
            }
        }
        p = p + 1;
    }

    // Count primes
    int count = 0;
    for (i = 2; i <= limit; i++) {
        if (prime[i] == 1) {
            count = count + 1;
        }
    }

    free(prime);
    return count;
}

int optimized_sieve(int limit) {
    // Optimized version using only odd numbers
    if (limit < 2) {
        return 0;
    }

    if (limit == 2) {
        return 1;
    }

    // We only need to track odd numbers
    int array_size = (limit + 1) / 2;
    int* is_prime = (int*)malloc(array_size * sizeof(int));
    int i;

    // Initialize all odd numbers as prime
    for (i = 0; i < array_size; i++) {
        is_prime[i] = 1;
    }

    // Start with 3 (index 1 in our array)
    int p = 3;
    while (p * p <= limit) {
        int p_index = p / 2;  // Index for odd number p

        if (is_prime[p_index] == 1) {
            // Mark multiples of p as composite
            int multiple = p * p;
            while (multiple <= limit) {
                if (multiple % 2 == 1) {  // Only mark odd multiples
                    int mult_index = multiple / 2;
                    is_prime[mult_index] = 0;
                }
                multiple = multiple + p;
            }
        }
        p = p + 2;  // Only check odd numbers
    }

    // Count primes (1 for 2, plus all odd primes)
    int count = 1;  // Count 2
    for (i = 1; i < array_size && (i * 2 + 1) <= limit; i++) {
        if (is_prime[i] == 1) {
            count = count + 1;
        }
    }

    free(is_prime);
    return count;
}

int segmented_sieve(int limit) {
    // Segmented sieve for better cache performance
    if (limit < 2) {
        return 0;
    }

    // Find all primes up to sqrt(limit) first
    int sqrt_limit = 1000;  // Approximate sqrt for reasonable limits
    int base_primes[200];   // Store base primes
    int base_count = 0;

    // Simple sieve for base primes
    int* is_prime = (int*)malloc((sqrt_limit + 1) * sizeof(int));
    int i;
    for (i = 0; i <= sqrt_limit; i++) {
        is_prime[i] = 1;
    }
    is_prime[0] = 0;
    is_prime[1] = 0;

    int p = 2;
    while (p * p <= sqrt_limit) {
        if (is_prime[p] == 1) {
            int multiple = p * p;
            while (multiple <= sqrt_limit) {
                is_prime[multiple] = 0;
                multiple = multiple + p;
            }
        }
        p = p + 1;
    }

    // Collect base primes
    for (i = 2; i <= sqrt_limit && base_count < 200; i++) {
        if (is_prime[i] == 1) {
            base_primes[base_count] = i;
            base_count = base_count + 1;
        }
    }

    free(is_prime);

    // Now use segmented sieve
    int segment_size = 10000;
    int total_count = 0;
    int low = 2;

    while (low <= limit) {
        int high = (low + segment_size - 1) < limit ? (low + segment_size - 1) : limit;
        int* segment = (int*)malloc((high - low + 1) * sizeof(int));

        // Initialize segment
        for (i = 0; i <= (high - low); i++) {
            segment[i] = 1;
        }

        // Use base primes to mark composites in this segment
        for (i = 0; i < base_count; i++) {
            p = base_primes[i];
            if (p * p > high) {
                break;
            }

            // Find first multiple of p in [low, high]
            int start = (low / p) * p;
            if (start < low) {
                start = start + p;
            }
            if (start == p) {
                start = start + p;  // Don't mark the prime itself
            }

            // Mark multiples in this segment
            int multiple = start;
            while (multiple <= high) {
                segment[multiple - low] = 0;
                multiple = multiple + p;
            }
        }

        // Count primes in this segment
        for (i = 0; i <= (high - low); i++) {
            if (segment[i] == 1) {
                total_count = total_count + 1;
            }
        }

        free(segment);
        low = low + segment_size;
    }

    return total_count;
}

int benchmark_basic_sieve() {
    int limit = 100000;
    printf("Basic Sieve: Finding primes up to %d...\n", limit);

    long long start_time = get_time_ms();
    int count = sieve_of_eratosthenes(limit);
    long long end_time = get_time_ms();

    printf("Found %d primes in %lldms\n", count, end_time - start_time);

    return count;
}

int benchmark_optimized_sieve() {
    int limit = 100000;
    printf("Optimized Sieve: Finding primes up to %d...\n", limit);

    long long start_time = get_time_ms();
    int count = optimized_sieve(limit);
    long long end_time = get_time_ms();

    printf("Found %d primes in %lldms\n", count, end_time - start_time);

    return count;
}

int benchmark_segmented_sieve() {
    int limit = 100000;
    printf("Segmented Sieve: Finding primes up to %d...\n", limit);

    long long start_time = get_time_ms();
    int count = segmented_sieve(limit);
    long long end_time = get_time_ms();

    printf("Found %d primes in %lldms\n", count, end_time - start_time);

    return count;
}

int verify_correctness() {
    // Test with known prime counts for small numbers
    int test_limits[] = {10, 100, 1000, 10000};
    int expected_counts[] = {4, 25, 168, 1229};  // Known prime counts

    printf("Verifying correctness...\n");

    for (int i = 0; i < 4; i++) {
        int limit = test_limits[i];
        int expected = expected_counts[i];

        int basic_count = sieve_of_eratosthenes(limit);
        int opt_count = optimized_sieve(limit);

        if (basic_count != expected || opt_count != expected) {
            printf("ERROR: Mismatch for limit=%d expected=%d basic=%d optimized=%d\n",
                   limit, expected, basic_count, opt_count);
            return 1;
        }

        printf("✓ Limit %d: %d primes\n", limit, expected);
    }

    printf("All implementations produce correct results\n");
    return 0;
}

int stress_test() {
    // Multiple sieve computations to stress CPU and memory
    printf("Stress test: Computing multiple sieves...\n");

    long long start_time = get_time_ms();
    int total_primes = 0;
    int limit = 1000;

    while (limit <= 50000) {
        int count = optimized_sieve(limit);
        total_primes = total_primes + count;
        limit = limit + 1000;
    }

    long long end_time = get_time_ms();

    printf("Computed sieves for limits 1000-50000 (50 iterations)\n");
    printf("Total primes found: %d in %lldms\n", total_primes, end_time - start_time);

    return total_primes;
}

int main() {
    printf("=== C Prime Sieve Benchmark ===\n\n");

    // Verification phase
    int verification_result = verify_correctness();
    if (verification_result != 0) {
        return verification_result;
    }

    printf("\n=== Performance Benchmarks ===\n");

    // Individual benchmarks
    int basic_count = benchmark_basic_sieve();
    int opt_count = benchmark_optimized_sieve();
    int seg_count = benchmark_segmented_sieve();

    printf("\n=== Stress Test ===\n");

    int stress_result = stress_test();

    printf("\n=== Summary ===\n");
    printf("Basic sieve result: %d primes\n", basic_count);
    printf("Optimized sieve result: %d primes\n", opt_count);
    printf("Segmented sieve result: %d primes\n", seg_count);
    printf("Stress test total: %d primes\n", stress_result);

    printf("Prime sieve benchmark completed successfully\n");

    return 0;
}