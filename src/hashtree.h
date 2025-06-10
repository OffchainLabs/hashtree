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
#ifndef HASHTREE_H
#define HASHTREE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*hashtree_hash_fcn)(unsigned char*, const unsigned char*, uint64_t);

/** Initialize the library to use the given hash tree function or perform
 * auto-detection based on the CPU if `NULL` is given.
 *
 * Calling this function is optional - if it is not called, auto-detection happens
 * automatically on the first hash computation.
 */
void hashtree_init(hashtree_hash_fcn override);

/* Undefined behavior if called without appropriate hardware support */
void hashtree_hash(unsigned char* output, const unsigned char* input, uint64_t count);
void hashtree_sha256_generic(unsigned char* output, const unsigned char* input, uint64_t count);

#ifdef __aarch64__
void hashtree_sha256_neon_x1(unsigned char* output, const unsigned char* input, uint64_t count);
void hashtree_sha256_neon_x4(unsigned char* output, const unsigned char* input, uint64_t count);
void hashtree_sha256_sha_x1(unsigned char* output, const unsigned char* input, uint64_t count);
#endif

#ifdef __riscv
void hashtree_sha256_riscv_x1(unsigned char* output, const unsigned char* input, uint64_t count);
void hashtree_sha256_riscv_zbb_x1(unsigned char* output, const unsigned char* input, uint64_t count);
void hashtree_sha256_riscv_crypto(unsigned char* output, const unsigned char* input, uint64_t count);
#endif

#ifdef __x86_64__
void hashtree_sha256_sse_x1(unsigned char* output, const unsigned char* input, uint64_t count);
void hashtree_sha256_avx_x1(unsigned char* output, const unsigned char* input, uint64_t count);
void hashtree_sha256_avx_x4(unsigned char* output, const unsigned char* input, uint64_t count);
void hashtree_sha256_avx2_x8(unsigned char* output, const unsigned char* input, uint64_t count);
void hashtree_sha256_avx512_x16(unsigned char* output, const unsigned char* input, uint64_t count);
void hashtree_sha256_shani_x2(unsigned char* output, const unsigned char* input, uint64_t count);
#endif
#ifdef __cplusplus
}
#endif
#endif
