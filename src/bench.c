/*
MIT License

Copyright (c) 2021 Prysmatic Labs

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
#ifdef __x86_64__
#include <cpuid.h>
#endif
#include <stdlib.h>

#include "hashtree.h"
#include "ubench.h"

#ifdef __riscv
#include <sys/syscall.h>
#include <unistd.h>

/* riscv_hwprobe(2), Linux 6.4+. These are the bits hashtree_detect() checks. */
#ifndef __NR_riscv_hwprobe
#define __NR_riscv_hwprobe 258
#endif
#define RISCV_HWPROBE_KEY_IMA_EXT_0 4
#define RISCV_HWPROBE_EXT_ZBB (1ULL << 4)
#define RISCV_HWPROBE_EXT_ZBKB (1ULL << 8)
#define RISCV_HWPROBE_EXT_ZKNH (1ULL << 13)

/* Extension bitmap of the CPU, or 0 if the kernel cannot report it. */
static uint64_t riscv_extensions(void) {
    struct {
        int64_t key;
        uint64_t value;
    } pair = {.key = RISCV_HWPROBE_KEY_IMA_EXT_0};

    if (syscall(__NR_riscv_hwprobe, &pair, 1, 0, NULL, 0) != 0) {
        return 0;
    }
    return pair.value;
}

static int riscv_has_zbb(void) { return (riscv_extensions() & RISCV_HWPROBE_EXT_ZBB) != 0; }

static int riscv_has_zknh(void) {
    uint64_t ext = riscv_extensions();
    return (ext & RISCV_HWPROBE_EXT_ZKNH) && (ext & RISCV_HWPROBE_EXT_ZBKB);
}
#endif
#ifdef HAVE_OPENSSL
#include <openssl/sha.h>
#endif

#define buffer_size 4800000

#ifdef __aarch64__
UBENCH_EX(armv8, neon_x1_one_at_time) {
    int *buffer = (int *)malloc(buffer_size);
    unsigned char digest[32];
    for (int i = 0; i < buffer_size / sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() {
        for (int i = 0; i < buffer_size; i += 64) {
            hashtree_sha256_neon_x1(digest, (unsigned char *)(buffer + i / sizeof(int)), 1);
        }
    }
    free(buffer);
}

UBENCH_EX(armv8, neon_x1) {
    int *buffer = (int *)malloc(buffer_size);
    unsigned char *digest = (unsigned char *)malloc(buffer_size / 2);
    for (int i = 0; i < buffer_size / sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() { hashtree_sha256_neon_x1(digest, (unsigned char *)buffer, buffer_size / 64); }
    free(buffer);
    free(digest);
}

UBENCH_EX(armv8, neon_x4) {
    int *buffer = (int *)malloc(buffer_size);
    unsigned char *digest = (unsigned char *)malloc(buffer_size / 2);
    for (int i = 0; i < buffer_size / sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() { hashtree_sha256_neon_x4(digest, (unsigned char *)buffer, buffer_size / 64); }
    free(buffer);
    free(digest);
}

UBENCH_EX(armv8, crypto) {
    int *buffer = (int *)malloc(buffer_size);
    unsigned char *digest = (unsigned char *)malloc(buffer_size / 2);
    for (int i = 0; i < buffer_size / sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() { hashtree_sha256_sha_x1(digest, (unsigned char *)buffer, buffer_size / 64); }
    free(buffer);
    free(digest);
}

#endif

UBENCH_EX(generic, generic) {
    int *buffer = (int *)malloc(buffer_size);
    unsigned char digest[32];
    for (int i = 0; i < buffer_size / sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() {
        for (int i = 0; i < buffer_size; i += 64) {
            hashtree_sha256_generic(digest, (unsigned char *)(buffer + i / sizeof(int)), 1);
        }
    }
    free(buffer);
}

#ifdef __x86_64__
/* The kernels are benchmarked directly, so repeat the checks of
 * hashtree_detect(): AVX/AVX-512 need the OS to have enabled the YMM/ZMM
 * state, and avx512_x16 also needs AVX512BW and AVX2. */
static uint64_t x86_xcr0() {
    uint32_t a = 0, b = 0, c = 0, d = 0;
    uint32_t eax, edx;
    __get_cpuid_count(1, 0, &a, &b, &c, &d);
    if (!(c & bit_OSXSAVE)) {
        return 0;
    }
    __asm__ __volatile__("xgetbv" : "=a"(eax), "=d"(edx) : "c"(0));
    return ((uint64_t)edx << 32) | eax;
}

static int x86_avx_ok() { return (x86_xcr0() & 0x6) == 0x6; }

static int x86_avx512_ok(uint32_t b) {
    return (b & bit_AVX512F) && (b & bit_AVX512VL) && (b & bit_AVX512BW) && (b & bit_AVX2) &&
           (x86_xcr0() & 0xE0) == 0xE0;
}

UBENCH_EX(sse, sse_x1_one_at_time) {
    int *buffer = (int *)malloc(buffer_size);
    unsigned char digest[32];
    for (int i = 0; i < buffer_size / sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() {
        for (int i = 0; i < buffer_size; i += 64) {
            hashtree_sha256_sse_x1(digest, (unsigned char *)(buffer + i / sizeof(int)), 1);
        }
    }
    free(buffer);
}

UBENCH_EX(sse, sse_x1) {
    int *buffer = (int *)malloc(buffer_size);
    unsigned char *digest = (unsigned char *)malloc(buffer_size / 2);
    for (int i = 0; i < buffer_size / sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() { hashtree_sha256_sse_x1(digest, (unsigned char *)buffer, buffer_size / 64); }
    free(buffer);
    free(digest);
}

UBENCH_EX(avx, avx_x1_one_at_time) {
    uint32_t a = 0, b = 0, c = 0, d = 0;
    __get_cpuid_count(1, 0, &a, &b, &c, &d);
    if (!(c & bit_AVX) || !x86_avx_ok()) {
        return;
    }
    int *buffer = (int *)malloc(buffer_size);
    unsigned char digest[32];
    for (int i = 0; i < buffer_size / sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() {
        for (int i = 0; i < buffer_size; i += 64) {
            hashtree_sha256_avx_x1(digest, (unsigned char *)(buffer + i / sizeof(int)), 1);
        }
    }
    free(buffer);
}

UBENCH_EX(avx, avx_x1) {
    uint32_t a = 0, b = 0, c = 0, d = 0;
    __get_cpuid_count(1, 0, &a, &b, &c, &d);
    if (!(c & bit_AVX) || !x86_avx_ok()) {
        return;
    }

    int *buffer = (int *)malloc(buffer_size);
    unsigned char *digest = (unsigned char *)malloc(buffer_size / 2);
    for (int i = 0; i < buffer_size / sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() { hashtree_sha256_avx_x1(digest, (unsigned char *)buffer, buffer_size / 64); }
    free(buffer);
    free(digest);
}

UBENCH_EX(avx, avx_x4) {
    uint32_t a = 0, b = 0, c = 0, d = 0;
    __get_cpuid_count(1, 0, &a, &b, &c, &d);
    if (!(c & bit_AVX) || !x86_avx_ok()) {
        return;
    }

    int *buffer = (int *)malloc(buffer_size);
    unsigned char *digest = (unsigned char *)malloc(buffer_size / 2);
    for (int i = 0; i < buffer_size / sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() { hashtree_sha256_avx_x4(digest, (unsigned char *)buffer, buffer_size / 64); }
    free(buffer);
    free(digest);
}

UBENCH_EX(avx, avx_x8) {
    uint32_t a = 0, b = 0, c = 0, d = 0;
    __get_cpuid_count(7, 0, &a, &b, &c, &d);
    if (!(b & bit_AVX2) || !x86_avx_ok()) {
        return;
    }

    int *buffer = (int *)malloc(buffer_size);
    unsigned char *digest = (unsigned char *)malloc(buffer_size / 2);
    for (int i = 0; i < buffer_size / sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() { hashtree_sha256_avx2_x8(digest, (unsigned char *)buffer, buffer_size / 64); }
    free(buffer);
    free(digest);
}

UBENCH_EX(avx, avx_x16) {
    uint32_t a = 0, b = 0, c = 0, d = 0;
    __get_cpuid_count(7, 0, &a, &b, &c, &d);
    if (!x86_avx512_ok(b)) {
        return;
    }

    int *buffer = (int *)malloc(buffer_size);
    unsigned char *digest = (unsigned char *)malloc(buffer_size / 2);
    for (int i = 0; i < buffer_size / sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() { hashtree_sha256_avx512_x16(digest, (unsigned char *)buffer, buffer_size / 64); }
    free(buffer);
    free(digest);
}

UBENCH_EX(shani, shani) {
    uint32_t a = 0, b = 0, c = 0, d = 0;
    __get_cpuid_count(7, 0, &a, &b, &c, &d);
    if (!(b & bit_SHA)) {
        return;
    }

    int *buffer = (int *)malloc(buffer_size);
    unsigned char *digest = (unsigned char *)malloc(buffer_size / 2);
    for (int i = 0; i < buffer_size / sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() { hashtree_sha256_shani_x2(digest, (unsigned char *)buffer, buffer_size / 64); }
    free(buffer);
    free(digest);
}

UBENCH_EX(shani, shani_one_at_time) {
    uint32_t a = 0, b = 0, c = 0, d = 0;
    __get_cpuid_count(7, 0, &a, &b, &c, &d);
    if (!(b & bit_SHA)) {
        return;
    }
    int *buffer = (int *)malloc(buffer_size);
    unsigned char digest[32];
    for (int i = 0; i < buffer_size / sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() {
        for (int i = 0; i < buffer_size; i += 64) {
            hashtree_sha256_shani_x2(digest, (unsigned char *)(buffer + i / sizeof(int)), 1);
        }
    }
    free(buffer);
}
#endif
#ifdef __riscv
UBENCH_EX(riscv, riscv_x1) {
    int * buffer  = (int *) malloc(buffer_size);
    unsigned char * digest = (unsigned char *) malloc(buffer_size/2);
    for (int i = 0; i < buffer_size/sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() {
        hashtree_sha256_riscv_x1(digest, (unsigned char *)buffer, buffer_size/64);
    }
    free(buffer);
    free(digest);
}
UBENCH_EX(riscv, riscv_zbb_x1) {
    if (!riscv_has_zbb()) {
        return;
    }
    int * buffer  = (int *) malloc(buffer_size);
    unsigned char * digest = (unsigned char *) malloc(buffer_size/2);
    for (int i = 0; i < buffer_size/sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() {
        hashtree_sha256_riscv_zbb_x1(digest, (unsigned char *)buffer, buffer_size/64);
    }
    free(buffer);
    free(digest);
}
UBENCH_EX(riscv, riscv_crypto) {
    if (!riscv_has_zknh()) {
        return;
    }
    int * buffer  = (int *) malloc(buffer_size);
    unsigned char * digest = (unsigned char *) malloc(buffer_size/2);
    for (int i = 0; i < buffer_size/sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() {
        hashtree_sha256_riscv_crypto(digest, (unsigned char *)buffer, buffer_size/64);
    }
    free(buffer);
    free(digest);
}
#endif

#ifdef HAVE_OPENSSL
UBENCH_EX(openssl, openssl_one_at_time) {
    int *buffer = (int *)malloc(buffer_size);
    unsigned char digest[32];
    for (int i = 0; i < buffer_size / sizeof(int); i++) {
        buffer[i] = rand();
    }
    UBENCH_DO_BENCHMARK() {
        for (int i = 0; i < buffer_size; i += 64) {
            SHA256((unsigned char *)(buffer + i / sizeof(int)), 64, digest);
        }
    }
    free(buffer);
}
#endif

UBENCH_MAIN()
