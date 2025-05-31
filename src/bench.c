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
    if (!(c & bit_AVX)) {
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
    if (!(c & bit_AVX)) {
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
    if (!(c & bit_AVX)) {
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
    if (!(b & bit_AVX2)) {
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
    if (!(b & bit_AVX512F) || !(b & bit_AVX512VL)) {
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
