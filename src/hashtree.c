/*
MIT License

Copyright (c) 2021-2024 Prysmatic Labs

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include "hashtree.h"

#include <assert.h>
#ifdef __x86_64__
#include <cpuid.h>
#endif
#ifdef __aarch64__
#ifndef __APPLE__
#include <asm/hwcap.h>
#include <sys/auxv.h>
#endif
#endif

static void init_and_hash(unsigned char *output, const unsigned char *input, uint64_t count);

static hashtree_hash_fcn hash_ptr = init_and_hash;

// Enhanced microarchitecture detection
static int is_intel_cpu() {
#ifdef __x86_64__
    uint32_t eax = 0, ebx = 0, ecx = 0, edx = 0;
    __get_cpuid(0, &eax, &ebx, &ecx, &edx);
    // Intel signature: "GenuineIntel"
    return (ebx == 0x756e6547 && edx == 0x49656e69 && ecx == 0x6c65746e);
#endif
    return 0;
}

static int is_amd_cpu() {
#ifdef __x86_64__
    uint32_t eax = 0, ebx = 0, ecx = 0, edx = 0;
    __get_cpuid(0, &eax, &ebx, &ecx, &edx);
    // AMD signature: "AuthenticAMD"
    return (ebx == 0x68747541 && edx == 0x69746e65 && ecx == 0x444d4163);
#endif
    return 0;
}


static hashtree_hash_fcn hashtree_detect() {
#ifdef __x86_64__
    uint32_t a = 0, b = 0, c = 0, d = 0;
    __get_cpuid_count(7, 0, &a, &b, &c, &d);

    int intel = is_intel_cpu();
    int amd = is_amd_cpu();

    if (b & bit_SHA) {
        /* SHANI provides excellent single-thread performance across both Intel and AMD.
        On Intel, it outperforms AVX512 for small to medium workloads.
        On AMD, it's consistently fast and power-efficient. */
        return &hashtree_sha256_shani_x2;
    }
    
    if ((b & bit_AVX512F) && (b & bit_AVX512VL)) {
        /* AVX512 optimization strategy:
        - Intel: Good for large parallel workloads, but watch for frequency scaling
        - AMD: Zen 4+ has good AVX512, but prefer for large datasets only */
        if (intel) {
            // Intel AVX512 is mature and well-optimized
            return &hashtree_sha256_avx512_x16;
        } else if (amd) {
            // AMD Zen 4+ AVX512 is newer, use conservatively
            return &hashtree_sha256_avx512_x16;
        }
    }
    
    if (b & bit_AVX2) {
        /* AVX2 is the sweet spot for most modern CPUs:
        - Intel: Excellent performance from Haswell onwards
        - AMD: Strong performance from Zen onwards */
        return &hashtree_sha256_avx2_x8;
    }
    
    __get_cpuid_count(1, 0, &a, &b, &c, &d);
    if (c & bit_AVX) {
        /* First-gen AVX:
        - Intel: Sandy Bridge/Ivy Bridge era
        - AMD: Bulldozer family - less optimal, but still good */
        return &hashtree_sha256_avx_x4;
    }
    
    if (c & bit_SSE2) {
        /* SSE2 fallback - universally supported on x86_64 */
        return &hashtree_sha256_sse_x1;
    }
#endif
#ifdef __aarch64__
    /* ARM64/AArch64 detection */
#ifdef __APPLE__
    /* Apple Silicon always has crypto extensions */
    return &hashtree_sha256_sha_x1;
#else
    /* Linux ARM64 - check capabilities */
    long hwcaps = getauxval(AT_HWCAP);
    if (hwcaps & HWCAP_SHA2) {
        /* ARM crypto extensions available */
        return &hashtree_sha256_sha_x1;
    }

    if (hwcaps & HWCAP_ASIMD) {
        /* NEON SIMD available */
        return &hashtree_sha256_neon_x4;
    }
    /* Fallback to generic if no SIMD available */
#endif
#endif
    
    /* Ultimate fallback for any undetected architecture:
     * - Non-x86_64 and non-ARM64 architectures
     * - x86_64 without SSE2 (extremely rare)
     * - ARM without NEON (older 32-bit ARM)
     * - Any future architectures not yet supported
     * The generic implementation uses pure C code that works everywhere */
    return &hashtree_sha256_generic;
}

// Helper function to get the name of the current implementation
const char* hashtree_get_impl_name() {
    if (hash_ptr == &hashtree_sha256_generic) return "generic";
#ifdef __x86_64__
    if (hash_ptr == &hashtree_sha256_sse_x1) return "sse_x1";
    if (hash_ptr == &hashtree_sha256_avx_x1) return "avx_x1";
    if (hash_ptr == &hashtree_sha256_avx_x4) return "avx_x4";
    if (hash_ptr == &hashtree_sha256_avx2_x8) return "avx2_x8";
    if (hash_ptr == &hashtree_sha256_avx512_x16) return "avx512_x16";
    if (hash_ptr == &hashtree_sha256_shani_x2) return "shani_x2";
#endif
#ifdef __aarch64__
    if (hash_ptr == &hashtree_sha256_sha_x1) return "arm_sha_x1";
    if (hash_ptr == &hashtree_sha256_neon_x1) return "arm_neon_x1";
    if (hash_ptr == &hashtree_sha256_neon_x4) return "arm_neon_x4";
#endif
    return "unknown";
}

void hashtree_init(hashtree_hash_fcn override) {
    if (override) {
        hash_ptr = override;
    } else {
        hash_ptr = hashtree_detect();
    }
}

void hashtree_hash(unsigned char *output, const unsigned char *input, uint64_t count) {
    (*hash_ptr)(output, input, count);
}

static void init_and_hash(unsigned char *output, const unsigned char *input, uint64_t count) {
    hash_ptr = hashtree_detect();
    assert(hash_ptr);

    hashtree_hash(output, input, count);
}
