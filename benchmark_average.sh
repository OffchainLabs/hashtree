#!/bin/bash

# Script to run hashtree benchmarks multiple times and calculate averages

NUM_RUNS=10
OUTPUT_FILE="benchmark_results.txt"

echo "Running benchmark $NUM_RUNS times..."
echo "============================================"

# Clear output file
> "$OUTPUT_FILE"

# Run benchmarks and collect results
for i in $(seq 1 $NUM_RUNS); do
    echo -n "Run $i/$NUM_RUNS... "
    ./build/bench | grep -E "^\[       OK \]" >> "$OUTPUT_FILE"
    echo "done"
done

echo ""
echo "============================================"
echo "BENCHMARK RESULTS SUMMARY"
echo "============================================"
echo ""

# Extract and process results for each test
echo "Test Name                                    | Avg Time (ms) | Min (ms) | Max (ms)"
echo "--------------------------------------------------------------------------"

# Get unique test names
TEST_NAMES=$(grep -E "^\[       OK \]" "$OUTPUT_FILE" | sed -E 's/\[       OK \] ([^ ]+) .*/\1/' | sort -u)

for test in $TEST_NAMES; do
    # Extract all times for this test
    TIMES=$(grep "$test " "$OUTPUT_FILE" | sed -E 's/.*mean ([0-9.]+)ms.*/\1/')
    
    # Calculate statistics using awk
    STATS=$(echo "$TIMES" | awk '
        {
            sum += $1
            if (NR == 1 || $1 < min) min = $1
            if (NR == 1 || $1 > max) max = $1
            count++
        }
        END {
            avg = sum / count
            printf "%.3f %.3f %.3f", avg, min, max
        }
    ')
    
    AVG=$(echo $STATS | cut -d' ' -f1)
    MIN=$(echo $STATS | cut -d' ' -f2)
    MAX=$(echo $STATS | cut -d' ' -f3)
    
    printf "%-44s | %13s | %8s | %8s\n" "$test" "$AVG" "$MIN" "$MAX"
done

echo ""
echo "============================================"
echo "GROUPED BY IMPLEMENTATION TYPE"
echo "============================================"

echo -e "\nGENERIC:"
grep "generic.generic " "$OUTPUT_FILE" | sed -E 's/.*mean ([0-9.]+)ms.*/\1/' | \
    awk '{sum+=$1; count++} END {printf "  Average: %.3f ms\n", sum/count}'

echo -e "\nSSE:"
for test in "sse.sse_x1_one_at_time" "sse.sse_x1"; do
    if grep -q "$test " "$OUTPUT_FILE"; then
        AVG=$(grep "$test " "$OUTPUT_FILE" | sed -E 's/.*mean ([0-9.]+)ms.*/\1/' | \
            awk '{sum+=$1; count++} END {printf "%.3f", sum/count}')
        printf "  %-35s %8s ms\n" "$test" "$AVG"
    fi
done

echo -e "\nAVX:"
for test in "avx.avx_x1_one_at_time" "avx.avx_x1" "avx.avx_x4" "avx.avx_x8" "avx.avx_x16"; do
    if grep -q "$test " "$OUTPUT_FILE"; then
        AVG=$(grep "$test " "$OUTPUT_FILE" | sed -E 's/.*mean ([0-9.]+)ms.*/\1/' | \
            awk '{sum+=$1; count++} END {printf "%.3f", sum/count}')
        printf "  %-35s %8s ms\n" "$test" "$AVG"
    fi
done

echo -e "\nSHA-NI:"
for test in "shani.shani" "shani.shani_one_at_time"; do
    if grep -q "$test " "$OUTPUT_FILE"; then
        AVG=$(grep "$test " "$OUTPUT_FILE" | sed -E 's/.*mean ([0-9.]+)ms.*/\1/' | \
            awk '{sum+=$1; count++} END {printf "%.3f", sum/count}')
        printf "  %-35s %8s ms\n" "$test" "$AVG"
    fi
done

