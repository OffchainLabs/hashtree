/*
MIT License

Copyright (c) 2021-2025 Offchain Labs

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

This code is based on Intel's implementation found in
        https://github.com/intel/intel-ipsec-mb
Such software is licensed under the BSD 3-Clause License and is
Copyright (c) 2012-2023, Intel Corporation
*/

#include <stdint.h>

// Branch prediction optimization macros
#ifdef __GNUC__
#define LIKELY(x)   __builtin_expect(!!(x), 1)
#define UNLIKELY(x) __builtin_expect(!!(x), 0)
#define PREFETCH_READ(addr, locality) __builtin_prefetch((addr), 0, (locality))
#define PREFETCH_WRITE(addr, locality) __builtin_prefetch((addr), 1, (locality))
#define FORCE_INLINE __attribute__((always_inline)) static inline
#define ALIGN_CACHELINE __attribute__((aligned(64)))
#define RESTRICT __restrict__
#else
#define LIKELY(x) (x)
#define UNLIKELY(x) (x)
#define PREFETCH_READ(addr, locality)
#define PREFETCH_WRITE(addr, locality)
#define FORCE_INLINE static inline
#define ALIGN_CACHELINE
#define RESTRICT
#endif

// Cache-aligned constants for better performance
static const uint32_t ALIGN_CACHELINE init[] = {
    0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19,
};

static const uint32_t ALIGN_CACHELINE K[] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
};

static const uint32_t ALIGN_CACHELINE P[] = {
    0xc28a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf374,
    0x649b69c1, 0xf0fe4786, 0x0fe1edc6, 0x240cf254, 0x4fe9346f, 0x6cc984be, 0x61b9411e, 0x16f988fa,
    0xf2c65152, 0xa88e5a6d, 0xb019fc65, 0xb9d99ec7, 0x9a1231c3, 0xe70eeaa0, 0xfdb1232b, 0xc7353eb0,
    0x3069bad5, 0xcb976d5f, 0x5a0f118f, 0xdc1eeefd, 0x0a35b689, 0xde0b7a04, 0x58f4ca9d, 0xe15d5b16,
    0x007f3e86, 0x37088980, 0xa507ea32, 0x6fab9537, 0x17406110, 0x0d8cd6f1, 0xcdaa3b6d, 0xc0bbbe37,
    0x83613bda, 0xdb48a363, 0x0b02e931, 0x6fd15ca7, 0x521afaca, 0x31338431, 0x6ed41a95, 0x6d437890,
    0xc39c91f2, 0x9eccabbd, 0xb5c9a0e6, 0x532fb63c, 0xd2c741c6, 0x07237ea3, 0xa4954b68, 0x4c191d76,
};

// Optimized rotation with compiler intrinsics when available
FORCE_INLINE uint32_t rotr(uint32_t x, int r) { 
#if defined(__x86_64__) && defined(__GNUC__) && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 9))
    // Use GCC rotation builtin when available (GCC 4.9+)
    return (x >> r) | (x << (32 - r));
#elif defined(__x86_64__) && defined(__clang__)
    // Clang has rotate intrinsics
    return __builtin_rotateright32(x, r);
#else
    // Standard rotation implementation
    return (x >> r) | (x << (32 - r)); 
#endif
}

// Optimized big-endian conversion
FORCE_INLINE uint32_t be32(const unsigned char* RESTRICT b) {
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    return *(const uint32_t*)b;
#elif defined(__x86_64__)
    return __builtin_bswap32(*(const uint32_t*)b);
#else
    return ((uint32_t)b[0] << 24) | ((uint32_t)b[1] << 16) | ((uint32_t)b[2] << 8) | b[3];
#endif
}

// Optimized SHA-256 round functions
FORCE_INLINE uint32_t sha256_ch(uint32_t x, uint32_t y, uint32_t z) {
    return (x & y) ^ (~x & z);
}

FORCE_INLINE uint32_t sha256_maj(uint32_t x, uint32_t y, uint32_t z) {
    return (x & y) ^ (x & z) ^ (y & z);
}

FORCE_INLINE uint32_t sha256_s0(uint32_t x) {
    return rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
}

FORCE_INLINE uint32_t sha256_s1(uint32_t x) {
    return rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
}

FORCE_INLINE uint32_t sha256_r0(uint32_t x) {
    return rotr(x, 7) ^ rotr(x, 18) ^ (x >> 3);
}

FORCE_INLINE uint32_t sha256_r1(uint32_t x) {
    return rotr(x, 17) ^ rotr(x, 19) ^ (x >> 10);
}

void hashtree_sha256_generic(unsigned char* RESTRICT output, const unsigned char* RESTRICT input, uint64_t count) {
    // Prefetch constant tables for better cache locality
    PREFETCH_READ(&K[0], 3);
    PREFETCH_READ(&P[0], 3);
    PREFETCH_READ(&init[0], 3);
    
    // Cache-aligned working set for better performance
    uint32_t w[16] ALIGN_CACHELINE;
    
    for (uint64_t k = 0; k < count; k++) {
        // Advanced prefetching strategy
        if (LIKELY(k + 1 < count)) {
            PREFETCH_READ(&input[(k + 1) * 64], 2);
        }
        if (LIKELY(k + 2 < count)) {
            PREFETCH_READ(&input[(k + 2) * 64], 1);
        }
        
        // Prefetch output location
        PREFETCH_WRITE(&output[k * 32], 2);
        // Initialize state variables
        uint32_t a = init[0], b = init[1], c = init[2], d = init[3];
        uint32_t e = init[4], f = init[5], g = init[6], h = init[7];
        
        const unsigned char* RESTRICT block = &input[k * 64];
        
        // First 16 rounds with optimized functions and loop unrolling (4 rounds at a time)
        for (int i = 0; i < 16; i += 4) {
            // Round i
            w[i] = be32(&block[i << 2]);
            uint32_t t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + K[i] + w[i];
            uint32_t t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
            
            // Round i+1
            w[i+1] = be32(&block[(i+1) << 2]);
            t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + K[i+1] + w[i+1];
            t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
            
            // Round i+2
            w[i+2] = be32(&block[(i+2) << 2]);
            t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + K[i+2] + w[i+2];
            t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
            
            // Round i+3
            w[i+3] = be32(&block[(i+3) << 2]);
            t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + K[i+3] + w[i+3];
            t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
        }

        // Last 48 rounds with optimized message schedule and unrolling
        for (int i = 16; i < 64; i += 4) {
            // Message schedule expansion and round i
            w[i & 0xF] += sha256_r1(w[(i - 2) & 0xF]) + w[(i - 7) & 0xF] + sha256_r0(w[(i - 15) & 0xF]);
            uint32_t t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + K[i] + w[i & 0xF];
            uint32_t t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;

            // Message schedule expansion and round i+1
            w[(i + 1) & 0xF] += sha256_r1(w[(i - 1) & 0xF]) + w[(i - 6) & 0xF] + sha256_r0(w[(i - 14) & 0xF]);
            t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + K[i + 1] + w[(i + 1) & 0xF];
            t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;

            // Message schedule expansion and round i+2
            w[(i + 2) & 0xF] += sha256_r1(w[i & 0xF]) + w[(i - 5) & 0xF] + sha256_r0(w[(i - 13) & 0xF]);
            t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + K[i + 2] + w[(i + 2) & 0xF];
            t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;

            // Message schedule expansion and round i+3
            w[(i + 3) & 0xF] += sha256_r1(w[(i + 1) & 0xF]) + w[(i - 4) & 0xF] + sha256_r0(w[(i - 12) & 0xF]);
            t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + K[i + 3] + w[(i + 3) & 0xF];
            t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
        }
        // Add original digest
        a += init[0]; b += init[1]; c += init[2]; d += init[3];
        e += init[4]; f += init[5]; g += init[6]; h += init[7];

        // Store intermediate hash values for padding rounds
        uint32_t h0 = a, h1 = b, h2 = c, h3 = d;
        uint32_t h4 = e, h5 = f, h6 = g, h7 = h;
        
        // Padding rounds with aggressive loop unrolling (8 rounds at a time)
        for (int i = 0; i < 64; i += 8) {
            // Rounds i through i+7 unrolled
            uint32_t t1, t2;
            
            t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + P[i];
            t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
            
            t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + P[i + 1];
            t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
            
            t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + P[i + 2];
            t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
            
            t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + P[i + 3];
            t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
            
            t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + P[i + 4];
            t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
            
            t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + P[i + 5];
            t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
            
            t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + P[i + 6];
            t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
            
            t1 = h + sha256_s1(e) + sha256_ch(e, f, g) + P[i + 7];
            t2 = sha256_s0(a) + sha256_maj(a, b, c);
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
        }

        // Final addition and optimized output
        h0 += a; h1 += b; h2 += c; h3 += d;
        h4 += e; h5 += f; h6 += g; h7 += h;
        
        // Optimized output with potential vector stores
        uint32_t* RESTRICT out32 = (uint32_t* RESTRICT)&output[k * 32];
        
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
        out32[0] = h0; out32[1] = h1; out32[2] = h2; out32[3] = h3;
        out32[4] = h4; out32[5] = h5; out32[6] = h6; out32[7] = h7;
#elif defined(__x86_64__)
        out32[0] = __builtin_bswap32(h0); out32[1] = __builtin_bswap32(h1);
        out32[2] = __builtin_bswap32(h2); out32[3] = __builtin_bswap32(h3);
        out32[4] = __builtin_bswap32(h4); out32[5] = __builtin_bswap32(h5);
        out32[6] = __builtin_bswap32(h6); out32[7] = __builtin_bswap32(h7);
#else
        unsigned char* RESTRICT out = &output[k * 32];
        out[0] = h0 >> 24; out[1] = h0 >> 16; out[2] = h0 >> 8; out[3] = h0;
        out[4] = h1 >> 24; out[5] = h1 >> 16; out[6] = h1 >> 8; out[7] = h1;
        out[8] = h2 >> 24; out[9] = h2 >> 16; out[10] = h2 >> 8; out[11] = h2;
        out[12] = h3 >> 24; out[13] = h3 >> 16; out[14] = h3 >> 8; out[15] = h3;
        out[16] = h4 >> 24; out[17] = h4 >> 16; out[18] = h4 >> 8; out[19] = h4;
        out[20] = h5 >> 24; out[21] = h5 >> 16; out[22] = h5 >> 8; out[23] = h5;
        out[24] = h6 >> 24; out[25] = h6 >> 16; out[26] = h6 >> 8; out[27] = h6;
        out[28] = h7 >> 24; out[29] = h7 >> 16; out[30] = h7 >> 8; out[31] = h7;
#endif
    }
}