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

static const uint32_t init[] = {
    0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19,
};

static const uint32_t K[] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
};

static const uint32_t P[] = {
    0xc28a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf374,
    0x649b69c1, 0xf0fe4786, 0x0fe1edc6, 0x240cf254, 0x4fe9346f, 0x6cc984be, 0x61b9411e, 0x16f988fa,
    0xf2c65152, 0xa88e5a6d, 0xb019fc65, 0xb9d99ec7, 0x9a1231c3, 0xe70eeaa0, 0xfdb1232b, 0xc7353eb0,
    0x3069bad5, 0xcb976d5f, 0x5a0f118f, 0xdc1eeefd, 0x0a35b689, 0xde0b7a04, 0x58f4ca9d, 0xe15d5b16,
    0x007f3e86, 0x37088980, 0xa507ea32, 0x6fab9537, 0x17406110, 0x0d8cd6f1, 0xcdaa3b6d, 0xc0bbbe37,
    0x83613bda, 0xdb48a363, 0x0b02e931, 0x6fd15ca7, 0x521afaca, 0x31338431, 0x6ed41a95, 0x6d437890,
    0xc39c91f2, 0x9eccabbd, 0xb5c9a0e6, 0x532fb63c, 0xd2c741c6, 0x07237ea3, 0xa4954b68, 0x4c191d76,
};

static inline uint32_t rotr(uint32_t x, int r) { return (x >> r) | (x << (32 - r)); }

static inline uint32_t be32(const unsigned char* b) {
    return ((uint32_t)b[0] << 24) | ((uint32_t)b[1] << 16) | ((uint32_t)b[2] << 8) | b[3];
}

void hashtree_sha256_generic(unsigned char* output, const unsigned char* input, uint64_t count) {
    uint32_t w[16];
    for (int k = 0; k < count; k++) {
        // First 16 roudnds
        uint32_t a = init[0];
        uint32_t b = init[1];
        uint32_t c = init[2];
        uint32_t d = init[3];
        uint32_t e = init[4];
        uint32_t f = init[5];
        uint32_t g = init[6];
        uint32_t h = init[7];
        for (int i = 0; i < 16; i++) {
            w[i] = be32(&input[k * 64 + (i << 2)]);
            uint32_t t1 = h + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + K[i] + w[i];
            uint32_t t2 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c));
            h = g;
            g = f;
            f = e;
            e = d + t1;
            d = c;
            c = b;
            b = a;
            a = t1 + t2;
        }

        // Last 48 rounds with loop unrolling (4 rounds at a time)
        for (int i = 16; i < 64; i += 4) {
            // Round i
            uint32_t v1 = w[(i - 2) & 0xF];
            uint32_t t1 = rotr(v1, 17) ^ rotr(v1, 19) ^ (v1 >> 10);
            uint32_t v2 = w[(i - 15) & 0xF];
            uint32_t t2 = rotr(v2, 7) ^ rotr(v2, 18) ^ (v2 >> 3);
            w[i & 0xF] += t1 + w[(i - 7) & 0xF] + t2;
            
            t1 = h + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + K[i] + w[i & 0xF];
            t2 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c));
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;

            // Round i+1
            v1 = w[(i + 1 - 2) & 0xF];
            t1 = rotr(v1, 17) ^ rotr(v1, 19) ^ (v1 >> 10);
            v2 = w[(i + 1 - 15) & 0xF];
            t2 = rotr(v2, 7) ^ rotr(v2, 18) ^ (v2 >> 3);
            w[(i + 1) & 0xF] += t1 + w[(i + 1 - 7) & 0xF] + t2;
            
            t1 = h + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + K[i + 1] + w[(i + 1) & 0xF];
            t2 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c));
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;

            // Round i+2
            v1 = w[(i + 2 - 2) & 0xF];
            t1 = rotr(v1, 17) ^ rotr(v1, 19) ^ (v1 >> 10);
            v2 = w[(i + 2 - 15) & 0xF];
            t2 = rotr(v2, 7) ^ rotr(v2, 18) ^ (v2 >> 3);
            w[(i + 2) & 0xF] += t1 + w[(i + 2 - 7) & 0xF] + t2;
            
            t1 = h + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + K[i + 2] + w[(i + 2) & 0xF];
            t2 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c));
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;

            // Round i+3
            v1 = w[(i + 3 - 2) & 0xF];
            t1 = rotr(v1, 17) ^ rotr(v1, 19) ^ (v1 >> 10);
            v2 = w[(i + 3 - 15) & 0xF];
            t2 = rotr(v2, 7) ^ rotr(v2, 18) ^ (v2 >> 3);
            w[(i + 3) & 0xF] += t1 + w[(i + 3 - 7) & 0xF] + t2;
            
            t1 = h + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + K[i + 3] + w[(i + 3) & 0xF];
            t2 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c));
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
        }
        // Add original digest
        a += init[0];
        b += init[1];
        c += init[2];
        d += init[3];
        e += init[4];
        f += init[5];
        g += init[6];
        h += init[7];

        // Rounds with padding
        uint32_t h0 = a;
        uint32_t h1 = b;
        uint32_t h2 = c;
        uint32_t h3 = d;
        uint32_t h4 = e;
        uint32_t h5 = f;
        uint32_t h6 = g;
        uint32_t h7 = h;
        // Padding rounds with loop unrolling (4 rounds at a time)
        for (int i = 0; i < 64; i += 4) {
            // Round i
            uint32_t t1 = h + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + P[i];
            uint32_t t2 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c));
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;

            // Round i+1
            t1 = h + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + P[i + 1];
            t2 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c));
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;

            // Round i+2
            t1 = h + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + P[i + 2];
            t2 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c));
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;

            // Round i+3
            t1 = h + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + P[i + 3];
            t2 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c));
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
        }

        h0 += a;
        h1 += b;
        h2 += c;
        h3 += d;
        h4 += e;
        h5 += f;
        h6 += g;
        h7 += h;
        unsigned char* out = &output[k * 32];
        out[0] = h0 >> 24; out[1] = h0 >> 16; out[2] = h0 >> 8; out[3] = h0;
        out[4] = h1 >> 24; out[5] = h1 >> 16; out[6] = h1 >> 8; out[7] = h1;
        out[8] = h2 >> 24; out[9] = h2 >> 16; out[10] = h2 >> 8; out[11] = h2;
        out[12] = h3 >> 24; out[13] = h3 >> 16; out[14] = h3 >> 8; out[15] = h3;
        out[16] = h4 >> 24; out[17] = h4 >> 16; out[18] = h4 >> 8; out[19] = h4;
        out[20] = h5 >> 24; out[21] = h5 >> 16; out[22] = h5 >> 8; out[23] = h5;
        out[24] = h6 >> 24; out[25] = h6 >> 16; out[26] = h6 >> 8; out[27] = h6;
        out[28] = h7 >> 24; out[29] = h7 >> 16; out[30] = h7 >> 8; out[31] = h7;
    }
}
