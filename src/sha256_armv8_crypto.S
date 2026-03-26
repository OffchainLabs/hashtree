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


#########################################################################################################
#
#   void sha256_armv8_crypto(unsigned char *output, unsigned char *input, size_t count)
#
#   armv8-a implementation with crypto extensions
#   as in the Apple Silicon M1
#
#   There are no bound checks, caller is responsible to check that memory up to output + 32*count
#   is writable.
# 
#   Used registers: x0, x1, x2, x3, x4, x5
# 
#   SIMD registers: all vector registers except v12-v15
#
########################################################################################################

#ifdef __aarch64__
.text
.arch armv8-a+sha2
.altmacro 

output .req x0
input .req x1
count .req x2
last  .req x2

digest .req x3
k256 .req x4
padding .req x5


.macro hashupdate WORD
		    sha256h		q2, q3, \WORD
		    sha256h2		q3, q8, \WORD
		    mov			v8.16b, v2.16b
.endm 

.macro schedule	    A, B, C, D, E, WORD
		    add			\WORD, \B, \A
		    sha256su0		\B, \C
		    sha256su1		\E, \C, \D
		    hashupdate		\WORD
.endm

#ifdef __APPLE__
.global _hashtree_sha256_sha_x1
#else
.global hashtree_sha256_sha_x1
#endif
#ifndef __APPLE__
.type hashtree_sha256_sha_x1,%function
#endif
.align 5
#ifdef __APPLE__
_hashtree_sha256_sha_x1:
#else
hashtree_sha256_sha_x1:
#endif
		    // Set up stack, need to save the clobbered registers d8-d11
		    sub			sp, sp, #32
		    stp			d8, d9, [sp]

#ifdef __APPLE__
		    adrp		digest, .LDIGEST@PAGE
		    add			digest, digest, .LDIGEST@PAGEOFF
		    adrp		k256, .LK256@PAGE
		    add			k256, k256, .LK256@PAGEOFF
#else
		    adrp		digest, .LDIGEST
		    add			digest, digest, #:lo12:.LDIGEST
		    adrp		k256, .LK256
		    add			k256, k256, #:lo12:.LK256
#endif
		    stp			d10, d11, [sp, #16]
#ifdef __APPLE__
		    adrp		padding, .LPADDING@PAGE
		    add			padding, padding, .LPADDING@PAGEOFF
#else
		    adrp		padding, .LPADDING
		    add			padding, padding, #:lo12:.LPADDING
#endif
		    add			last, output, count, lsl #5

		    ld1			{v0.4s, v1.4s}, [digest]

.Lshani_loop:
		    cmp			last, output
		    beq			.Lshani_finish

		    // Load all K constants
		    ld1			{v16.4s, v17.4s, v18.4s, v19.4s}, [k256], #64
		    ld1			{v20.4s, v21.4s, v22.4s, v23.4s}, [k256], #64
		    ld1			{v24.4s, v25.4s, v26.4s, v27.4s}, [k256], #64
		    ld1			{v28.4s, v29.4s, v30.4s, v31.4s}, [k256] 
		    sub			k256, k256, #192

		    // Load one block
		    ld1			{v4.4s, v5.4s, v6.4s, v7.4s}, [input], #64
		    mov			v2.16b, v0.16b
		    mov			v3.16b, v1.16b
		    mov			v8.16b, v2.16b

		    // Reverse endinanness
		    rev32		v4.16b, v4.16b
		    rev32		v5.16b, v5.16b
		    rev32		v6.16b, v6.16b
		    rev32		v7.16b, v7.16b

		    add			v9.4s, v4.4s, v16.4s
		    sha256su0		v4.4s, v5.4s
		    hashupdate		v9.4s

		    schedule		v17.4s, v5.4s, v6.4s, v7.4s, v4.4s, v9.4s
		    schedule		v18.4s, v6.4s, v7.4s, v4.4s, v5.4s, v9.4s
		    schedule		v19.4s, v7.4s, v4.4s, v5.4s, v6.4s, v9.4s
		    schedule		v20.4s, v4.4s, v5.4s, v6.4s, v7.4s, v9.4s
		    schedule		v21.4s, v5.4s, v6.4s, v7.4s, v4.4s, v9.4s
		    schedule		v22.4s, v6.4s, v7.4s, v4.4s, v5.4s, v9.4s
		    schedule		v23.4s, v7.4s, v4.4s, v5.4s, v6.4s, v9.4s
		    schedule		v24.4s, v4.4s, v5.4s, v6.4s, v7.4s, v9.4s
		    schedule		v25.4s, v5.4s, v6.4s, v7.4s, v4.4s, v9.4s
		    schedule		v26.4s, v6.4s, v7.4s, v4.4s, v5.4s, v9.4s
		    schedule		v27.4s, v7.4s, v4.4s, v5.4s, v6.4s, v9.4s

		    add			v9.4s, v4.4s, v28.4s
		    hashupdate		v9.4s
		    sha256su1		v7.4s, v5.4s, v6.4s
		    add			v9.4s, v5.4s, v29.4s
		    hashupdate		v9.4s
		    add			v9.4s, v6.4s, v30.4s
		    hashupdate		v9.4s
		    add			v9.4s, v7.4s, v31.4s
		    hashupdate		v9.4s

		    // Add initial digest and back it up
		    add			v2.4s, v0.4s, v2.4s
		    add			v3.4s, v1.4s, v3.4s
		    mov			v10.16b, v2.16b
		    mov			v11.16b, v3.16b

		    // Rounds with padding

		    // Load prescheduled constants
		    ld1			{v16.4s, v17.4s, v18.4s, v19.4s}, [padding], #64
		    ld1			{v20.4s, v21.4s, v22.4s, v23.4s}, [padding], #64
		    mov			v8.16b, v2.16b
		    ld1			{v24.4s, v25.4s, v26.4s, v27.4s}, [padding], #64
		    ld1			{v28.4s, v29.4s, v30.4s, v31.4s}, [padding]
		    sub			padding, padding, #192

		    hashupdate		v16.4s
		    hashupdate		v17.4s
		    hashupdate		v18.4s
		    hashupdate		v19.4s
		    hashupdate		v20.4s
		    hashupdate		v21.4s
		    hashupdate		v22.4s
		    hashupdate		v23.4s
		    hashupdate		v24.4s
		    hashupdate		v25.4s
		    hashupdate		v26.4s
		    hashupdate		v27.4s
		    hashupdate		v28.4s
		    hashupdate		v29.4s
		    hashupdate		v30.4s
		    hashupdate		v31.4s

		    // Add backed up digest
		    add			v2.4s, v10.4s, v2.4s
		    add			v3.4s, v11.4s, v3.4s

		    rev32		v2.16b, v2.16b
		    rev32		v3.16b, v3.16b
		    st1			{v2.4s, v3.4s}, [output], #32
		    
		    b			.Lshani_loop

.Lshani_finish:
		    ldp			d8,d9, [sp], #16
		    ldp			d10, d11, [sp], #16
		    ret

.section .rodata, "a"
.align 4
.LDIGEST:
.word		    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,\
		    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
.LK256:
.word		    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,\
		    0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,\
		    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,\
		    0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,\
		    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,\
		    0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,\
		    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,\
		    0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,\
		    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,\
		    0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,\
		    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,\
		    0xd192e819,0xd6990624,0xf40e3585,0x106aa070,\
		    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,\
		    0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,\
		    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,\
		    0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2

.LPADDING:
.word		    0xc28a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,\
		    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,\
		    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,\
		    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf374,\
		    0x649b69c1, 0xf0fe4786, 0xfe1edc6, 0x240cf254,\
		    0x4fe9346f, 0x6cc984be, 0x61b9411e, 0x16f988fa,\
		    0xf2c65152, 0xa88e5a6d, 0xb019fc65, 0xb9d99ec7,\
		    0x9a1231c3, 0xe70eeaa0, 0xfdb1232b, 0xc7353eb0,\
		    0x3069bad5, 0xcb976d5f, 0x5a0f118f, 0xdc1eeefd,\
		    0xa35b689, 0xde0b7a04, 0x58f4ca9d, 0xe15d5b16,\
		    0x7f3e86, 0x37088980, 0xa507ea32, 0x6fab9537,\
		    0x17406110, 0xd8cd6f1, 0xcdaa3b6d, 0xc0bbbe37,\
		    0x83613bda, 0xdb48a363, 0xb02e931, 0x6fd15ca7,\
		    0x521afaca, 0x31338431, 0x6ed41a95, 0x6d437890,\
		    0xc39c91f2, 0x9eccabbd, 0xb5c9a0e6, 0x532fb63c,\
		    0xd2c741c6, 0x7237ea3, 0xa4954b68, 0x4c191d76
#endif 
