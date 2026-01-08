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

This code is based on Intel's implementation found in
	https://github.com/intel/intel-ipsec-mb
Such software is licensed under the BSD 3-Clause License and is 
Copyright (c) 2012-2023, Intel Corporation
*/

#ifdef __x86_64__
.intel_syntax noprefix
.section .rodata
.align 64

.LK256_4:
	.quad	0x428a2f98428a2f98, 0x428a2f98428a2f98
	.quad	0x7137449171374491, 0x7137449171374491
	.quad	0xb5c0fbcfb5c0fbcf, 0xb5c0fbcfb5c0fbcf
	.quad	0xe9b5dba5e9b5dba5, 0xe9b5dba5e9b5dba5
	.quad	0x3956c25b3956c25b, 0x3956c25b3956c25b
	.quad	0x59f111f159f111f1, 0x59f111f159f111f1
	.quad	0x923f82a4923f82a4, 0x923f82a4923f82a4
	.quad	0xab1c5ed5ab1c5ed5, 0xab1c5ed5ab1c5ed5
	.quad	0xd807aa98d807aa98, 0xd807aa98d807aa98
	.quad	0x12835b0112835b01, 0x12835b0112835b01
	.quad	0x243185be243185be, 0x243185be243185be
	.quad	0x550c7dc3550c7dc3, 0x550c7dc3550c7dc3
	.quad	0x72be5d7472be5d74, 0x72be5d7472be5d74
	.quad	0x80deb1fe80deb1fe, 0x80deb1fe80deb1fe
	.quad	0x9bdc06a79bdc06a7, 0x9bdc06a79bdc06a7
	.quad	0xc19bf174c19bf174, 0xc19bf174c19bf174
	.quad	0xe49b69c1e49b69c1, 0xe49b69c1e49b69c1
	.quad	0xefbe4786efbe4786, 0xefbe4786efbe4786
	.quad	0x0fc19dc60fc19dc6, 0x0fc19dc60fc19dc6
	.quad	0x240ca1cc240ca1cc, 0x240ca1cc240ca1cc
	.quad	0x2de92c6f2de92c6f, 0x2de92c6f2de92c6f
	.quad	0x4a7484aa4a7484aa, 0x4a7484aa4a7484aa
	.quad	0x5cb0a9dc5cb0a9dc, 0x5cb0a9dc5cb0a9dc
	.quad	0x76f988da76f988da, 0x76f988da76f988da
	.quad	0x983e5152983e5152, 0x983e5152983e5152
	.quad	0xa831c66da831c66d, 0xa831c66da831c66d
	.quad	0xb00327c8b00327c8, 0xb00327c8b00327c8
	.quad	0xbf597fc7bf597fc7, 0xbf597fc7bf597fc7
	.quad	0xc6e00bf3c6e00bf3, 0xc6e00bf3c6e00bf3
	.quad	0xd5a79147d5a79147, 0xd5a79147d5a79147
	.quad	0x06ca635106ca6351, 0x06ca635106ca6351
	.quad	0x1429296714292967, 0x1429296714292967
	.quad	0x27b70a8527b70a85, 0x27b70a8527b70a85
	.quad	0x2e1b21382e1b2138, 0x2e1b21382e1b2138
	.quad	0x4d2c6dfc4d2c6dfc, 0x4d2c6dfc4d2c6dfc
	.quad	0x53380d1353380d13, 0x53380d1353380d13
	.quad	0x650a7354650a7354, 0x650a7354650a7354
	.quad	0x766a0abb766a0abb, 0x766a0abb766a0abb
	.quad	0x81c2c92e81c2c92e, 0x81c2c92e81c2c92e
	.quad	0x92722c8592722c85, 0x92722c8592722c85
	.quad	0xa2bfe8a1a2bfe8a1, 0xa2bfe8a1a2bfe8a1
	.quad	0xa81a664ba81a664b, 0xa81a664ba81a664b
	.quad	0xc24b8b70c24b8b70, 0xc24b8b70c24b8b70
	.quad	0xc76c51a3c76c51a3, 0xc76c51a3c76c51a3
	.quad	0xd192e819d192e819, 0xd192e819d192e819
	.quad	0xd6990624d6990624, 0xd6990624d6990624
	.quad	0xf40e3585f40e3585, 0xf40e3585f40e3585
	.quad	0x106aa070106aa070, 0x106aa070106aa070
	.quad	0x19a4c11619a4c116, 0x19a4c11619a4c116
	.quad	0x1e376c081e376c08, 0x1e376c081e376c08
	.quad	0x2748774c2748774c, 0x2748774c2748774c
	.quad	0x34b0bcb534b0bcb5, 0x34b0bcb534b0bcb5
	.quad	0x391c0cb3391c0cb3, 0x391c0cb3391c0cb3
	.quad	0x4ed8aa4a4ed8aa4a, 0x4ed8aa4a4ed8aa4a
	.quad	0x5b9cca4f5b9cca4f, 0x5b9cca4f5b9cca4f
	.quad	0x682e6ff3682e6ff3, 0x682e6ff3682e6ff3
	.quad	0x748f82ee748f82ee, 0x748f82ee748f82ee
	.quad	0x78a5636f78a5636f, 0x78a5636f78a5636f
	.quad	0x84c8781484c87814, 0x84c8781484c87814
	.quad	0x8cc702088cc70208, 0x8cc702088cc70208
	.quad	0x90befffa90befffa, 0x90befffa90befffa
	.quad	0xa4506ceba4506ceb, 0xa4506ceba4506ceb
	.quad	0xbef9a3f7bef9a3f7, 0xbef9a3f7bef9a3f7
	.quad	0xc67178f2c67178f2, 0xc67178f2c67178f2

.LPADDING_4:
        .quad      0xc28a2f98c28a2f98, 0xc28a2f98c28a2f98
        .quad      0x7137449171374491, 0x7137449171374491
        .quad      0xb5c0fbcfb5c0fbcf, 0xb5c0fbcfb5c0fbcf
        .quad      0xe9b5dba5e9b5dba5, 0xe9b5dba5e9b5dba5
        .quad      0x3956c25b3956c25b, 0x3956c25b3956c25b
        .quad      0x59f111f159f111f1, 0x59f111f159f111f1
        .quad      0x923f82a4923f82a4, 0x923f82a4923f82a4
        .quad      0xab1c5ed5ab1c5ed5, 0xab1c5ed5ab1c5ed5
        .quad      0xd807aa98d807aa98, 0xd807aa98d807aa98
        .quad      0x12835b0112835b01, 0x12835b0112835b01
        .quad      0x243185be243185be, 0x243185be243185be
        .quad      0x550c7dc3550c7dc3, 0x550c7dc3550c7dc3
        .quad      0x72be5d7472be5d74, 0x72be5d7472be5d74
        .quad      0x80deb1fe80deb1fe, 0x80deb1fe80deb1fe
        .quad      0x9bdc06a79bdc06a7, 0x9bdc06a79bdc06a7
        .quad      0xc19bf374c19bf374, 0xc19bf374c19bf374
        .quad      0x649b69c1649b69c1, 0x649b69c1649b69c1
        .quad      0xf0fe4786f0fe4786, 0xf0fe4786f0fe4786
        .quad      0x0fe1edc60fe1edc6, 0x0fe1edc60fe1edc6
        .quad      0x240cf254240cf254, 0x240cf254240cf254
        .quad      0x4fe9346f4fe9346f, 0x4fe9346f4fe9346f
        .quad      0x6cc984be6cc984be, 0x6cc984be6cc984be
        .quad      0x61b9411e61b9411e, 0x61b9411e61b9411e
        .quad      0x16f988fa16f988fa, 0x16f988fa16f988fa
        .quad      0xf2c65152f2c65152, 0xf2c65152f2c65152
        .quad      0xa88e5a6da88e5a6d, 0xa88e5a6da88e5a6d
        .quad      0xb019fc65b019fc65, 0xb019fc65b019fc65
        .quad      0xb9d99ec7b9d99ec7, 0xb9d99ec7b9d99ec7
        .quad      0x9a1231c39a1231c3, 0x9a1231c39a1231c3
        .quad      0xe70eeaa0e70eeaa0, 0xe70eeaa0e70eeaa0
        .quad      0xfdb1232bfdb1232b, 0xfdb1232bfdb1232b
        .quad      0xc7353eb0c7353eb0, 0xc7353eb0c7353eb0
        .quad      0x3069bad53069bad5, 0x3069bad53069bad5
        .quad      0xcb976d5fcb976d5f, 0xcb976d5fcb976d5f
        .quad      0x5a0f118f5a0f118f, 0x5a0f118f5a0f118f
        .quad      0xdc1eeefddc1eeefd, 0xdc1eeefddc1eeefd
        .quad      0x0a35b6890a35b689, 0x0a35b6890a35b689
        .quad      0xde0b7a04de0b7a04, 0xde0b7a04de0b7a04
        .quad      0x58f4ca9d58f4ca9d, 0x58f4ca9d58f4ca9d
        .quad      0xe15d5b16e15d5b16, 0xe15d5b16e15d5b16
        .quad      0x007f3e86007f3e86, 0x007f3e86007f3e86
        .quad      0x3708898037088980, 0x3708898037088980
        .quad      0xa507ea32a507ea32, 0xa507ea32a507ea32
        .quad      0x6fab95376fab9537, 0x6fab95376fab9537
        .quad      0x1740611017406110, 0x1740611017406110
        .quad      0x0d8cd6f10d8cd6f1, 0x0d8cd6f10d8cd6f1
        .quad      0xcdaa3b6dcdaa3b6d, 0xcdaa3b6dcdaa3b6d
        .quad      0xc0bbbe37c0bbbe37, 0xc0bbbe37c0bbbe37
        .quad      0x83613bda83613bda, 0x83613bda83613bda
        .quad      0xdb48a363db48a363, 0xdb48a363db48a363
        .quad      0x0b02e9310b02e931, 0x0b02e9310b02e931
        .quad      0x6fd15ca76fd15ca7, 0x6fd15ca76fd15ca7
        .quad      0x521afaca521afaca, 0x521afaca521afaca
        .quad      0x3133843131338431, 0x3133843131338431
        .quad      0x6ed41a956ed41a95, 0x6ed41a956ed41a95
        .quad      0x6d4378906d437890, 0x6d4378906d437890
        .quad      0xc39c91f2c39c91f2, 0xc39c91f2c39c91f2
        .quad      0x9eccabbd9eccabbd, 0x9eccabbd9eccabbd
        .quad      0xb5c9a0e6b5c9a0e6, 0xb5c9a0e6b5c9a0e6
        .quad      0x532fb63c532fb63c, 0x532fb63c532fb63c
        .quad      0xd2c741c6d2c741c6, 0xd2c741c6d2c741c6
        .quad      0x07237ea307237ea3, 0x07237ea307237ea3
        .quad      0xa4954b68a4954b68, 0xa4954b68a4954b68
        .quad      0x4c191d764c191d76, 0x4c191d764c191d76

.LDIGEST_4:
        .long   0x6a09e667, 0x6a09e667, 0x6a09e667, 0x6a09e667
	.long 	0xbb67ae85, 0xbb67ae85, 0xbb67ae85, 0xbb67ae85 
	.long   0x3c6ef372, 0x3c6ef372, 0x3c6ef372, 0x3c6ef372 
	.long 	0xa54ff53a, 0xa54ff53a, 0xa54ff53a, 0xa54ff53a 
	.long	0x510e527f, 0x510e527f, 0x510e527f, 0x510e527f
	.long 	0x9b05688c, 0x9b05688c, 0x9b05688c, 0x9b05688c 
	.long	0x1f83d9ab, 0x1f83d9ab, 0x1f83d9ab, 0x1f83d9ab
        .long   0x5be0cd19, 0x5be0cd19, 0x5be0cd19, 0x5be0cd19

.LPSHUFFLE_BYTE_FLIP_MASK:
	.quad 0x0405060700010203, 0x0c0d0e0f08090a0b

#ifdef __WIN64__
	#define OUTPUT_PTR rcx
	#define DATA_PTR rdx
	#define NUM_BLKS r8
	#define TBL rax
#else
	#define OUTPUT_PTR rdi
	#define DATA_PTR rsi
	#define NUM_BLKS rdx
	#define TBL rcx
#endif

#define ROUND r9

#define INI_a xmm0
#define INI_b xmm1
#define INI_c xmm2
#define INI_d xmm3
#define INI_e xmm4
#define INI_f xmm5
#define INI_g xmm6
#define INI_h xmm7

// Aliases for non-macro code (at initial rotation state)
#define a INI_a
#define b INI_b
#define c INI_c
#define d INI_d
#define e INI_e
#define f INI_f
#define g INI_g
#define h INI_h

#define a0 xmm8
#define a1 xmm9
#define a2 xmm10

#define TT0 xmm14
#define TT1 xmm13
#define TT2 xmm12
#define TT3 xmm11
#define TT4 xmm10
#define TT5 xmm9

#define T1 xmm14
#define TMP xmm15

#define SZ4 16
#define SHA256_DIGEST_WORD_SIZE 4
#define NUM_SHA256_DIGEST_WORDS 8
#define ROUNDS 1024

// stack usage
#define _DATA 0
#define _DIGEST 256
#ifdef __WIN64__
	#define _XMM_SAVE 384
	#define sha256_avx_4_stack_size 568
#else
	#define sha256_avx_4_stack_size 408
#endif

#define VMOVPS	vmovups

.macro TRANSPOSE r0, r1, r2, r3, t0, t1
	vshufps	\t0, \r0, \r1, 0x44	// t0 = {b1 b0 a1 a0}
	vshufps	\r0, \r0, \r1, 0xEE	// r0 = {b3 b2 a3 a2}

	vshufps	\t1, \r2, \r3, 0x44	// t1 = {d1 d0 c1 c0}
	vshufps	\r2, \r2, \r3, 0xEE	// r2 = {d3 d2 c3 c2}

	vshufps	\r1, \t0, \t1, 0xDD	// r1 = {d1 c1 b1 a1}

	vshufps	\r3, \r0, \r2, 0xDD	// r3 = {d3 c3 b3 a3}

	vshufps	\r0, \r0, \r2, 0x88	// r0 = {d2 c2 b2 a2}
	vshufps	\t0, \t0, \t1, 0x88	// t0 = {d0 c0 b0 a0}
.endm


.macro PRORD3 reg, imm, tmp
	vpslld	\tmp, \reg, (32-(\imm))
	vpsrld	\reg, \reg, \imm
	vpor	\reg, \reg, \tmp
.endm

.macro PRORD_nd4 reg, imm, tmp, src
	vpslld	\tmp, \src, (32-(\imm))
	vpsrld	\reg, \src, \imm
	vpor	\reg, \reg, \tmp
.endm

.macro PRORD src, imm
	PRORD3	\src, \imm, TMP
.endm

.macro PRORD_nd dst, src, amt
	PRORD_nd4	\dst, \amt, TMP, \src
.endm

// Parameterized ROUND_00_15 - takes all 8 XMM registers as parameters
// No rotation at end - caller handles register rotation by passing different args
.macro ROUND_00_15_P ra, rb, rc, rd, re, rf, rg, rh, T1_reg, index, is_padding
	PRORD_nd	a0, \re, (11-6)	// sig1: a0 = (e >> 5)

	vpxor	a2, \rf, \rg	// ch: a2 = f^g
	vpand	a2, a2, \re	// ch: a2 = (f^g)&e
	vpxor	a2, a2, \rg	// a2 = ch

	PRORD_nd	a1, \re, 25		// sig1: a1 = (e >> 25)
.if \is_padding - 1
	vmovdqa	[SZ4*(\index&0xf) + rsp + _DATA], \T1_reg
	vpaddd	\T1_reg, \T1_reg, [TBL + ROUND]	// T1 = W + K
.else
        vmovdqa \T1_reg, [TBL + ROUND]
.endif
	vpxor	a0, a0, \re	// sig1: a0 = e ^ (e >> 5)
	PRORD	a0, 6		// sig1: a0 = (e >> 6) ^ (e >> 11)
	vpaddd	\rh, \rh, a2	// h = h + ch
	PRORD_nd	a2, \ra, (13-2)	// sig0: a2 = (a >> 11)
	vpaddd	\rh, \rh, \T1_reg	// h = h + ch + W + K
	vpxor	a0, a0, a1	// a0 = sigma1
	PRORD_nd	a1, \ra, 22	// sig0: a1 = (a >> 22)
	vpxor	\T1_reg, \ra, \rc	// maj: T1 = a^c
	add	ROUND, SZ4	// ROUND++
	vpand	\T1_reg, \T1_reg, \rb	// maj: T1 = (a^c)&b
	vpaddd	\rh, \rh, a0

	vpaddd	\rd, \rd, \rh

	vpxor	a2, a2, \ra	// sig0: a2 = a ^ (a >> 11)
	PRORD	a2, 2		// sig0: a2 = (a >> 2) ^ (a >> 13)
	vpxor	a2, a2, a1	// a2 = sig0
	vpand	a1, \ra, \rc	// maj: a1 = a&c
	vpor	a1, a1, \T1_reg	// a1 = maj
	vpaddd	\rh, \rh, a1	// h = h + ch + W + K + maj
	vpaddd	\rh, \rh, a2	// h = h + ch + W + K + maj + sigma0
.endm


// Parameterized ROUND_16_XX - takes all 8 XMM registers as parameters
.macro ROUND_16_XX_P ra, rb, rc, rd, re, rf, rg, rh, T1_reg, index
	vmovdqa	\T1_reg, [SZ4*((\index-15)&0xf) + rsp + _DATA]
	vmovdqa	a1, [SZ4*((\index-2)&0xf) + rsp + _DATA]
	vmovdqa	a0, \T1_reg
	PRORD	\T1_reg, 18-7
	vmovdqa	a2, a1
	PRORD	a1, 19-17
	vpxor	\T1_reg, \T1_reg, a0
	PRORD	\T1_reg, 7
	vpxor	a1, a1, a2
	PRORD	a1, 17
	vpsrld	a0, a0, 3
	vpxor	\T1_reg, \T1_reg, a0
	vpsrld	a2, a2, 10
	vpxor	a1, a1, a2
	vpaddd	\T1_reg, \T1_reg, [SZ4*((\index-16)&0xf) + rsp + _DATA]
	vpaddd	a1, a1, [SZ4*((\index-7)&0xf) + rsp + _DATA]
	vpaddd	\T1_reg, \T1_reg, a1

	ROUND_00_15_P \ra, \rb, \rc, \rd, \re, \rf, \rg, \rh, \T1_reg, \index, 0
.endm

.text 
.global hashtree_sha256_avx_x4
#ifndef __WIN64__
.type   hashtree_sha256_avx_x4,%function
#endif
.align 16
hashtree_sha256_avx_x4:
        endbr64
	cmp	NUM_BLKS, 0
	jne	.Lstart_routine
	ret
.Lstart_routine:
	sub	rsp, sha256_avx_4_stack_size
#ifdef __WIN64__
	vmovdqa	[rsp + _XMM_SAVE + 0*16],xmm6
	vmovdqa	[rsp + _XMM_SAVE + 1*16],xmm7
	vmovdqa	[rsp + _XMM_SAVE + 2*16],xmm8
	vmovdqa	[rsp + _XMM_SAVE + 3*16],xmm9
	vmovdqa	[rsp + _XMM_SAVE + 4*16],xmm10
	vmovdqa	[rsp + _XMM_SAVE + 5*16],xmm11
	vmovdqa	[rsp + _XMM_SAVE + 6*16],xmm12
	vmovdqa	[rsp + _XMM_SAVE + 7*16],xmm13
	vmovdqa	[rsp + _XMM_SAVE + 8*16],xmm14
	vmovdqa	[rsp + _XMM_SAVE + 9*16],xmm15
#endif

.Lsha256_4_avx_loop:
	cmp 	NUM_BLKS, 4
	jl 	.Lsha256_4_avx_epilog

	xor	ROUND, ROUND

	// Load the pre-transposed incoming digest.
	lea TBL, [rip + .LDIGEST_4]
	vmovdqa	a,[TBL + 0*SZ4]
	vmovdqa	b,[TBL + 1*SZ4]
	vmovdqa	c,[TBL + 2*SZ4]
	vmovdqa	d,[TBL + 3*SZ4]
	vmovdqa	e,[TBL + 4*SZ4]
	vmovdqa	f,[TBL + 5*SZ4]
	vmovdqa	g,[TBL + 6*SZ4]
	vmovdqa	h,[TBL + 7*SZ4]

	lea	TBL, [rip + .LK256_4]

//; Rounds 0-15: Load and process data (4 iterations of 4 rounds each)
	//; Iteration 0: rounds 0-3
	vmovdqa	TMP, [rip + .LPSHUFFLE_BYTE_FLIP_MASK]
	VMOVPS	TT2,[DATA_PTR + 0*64 + 0*16]
	VMOVPS	TT1,[DATA_PTR + 1*64 + 0*16]
	VMOVPS	TT4,[DATA_PTR + 2*64 + 0*16]
	VMOVPS	TT3,[DATA_PTR + 3*64 + 0*16]
	TRANSPOSE	TT2, TT1, TT4, TT3, TT0, TT5
	vpshufb	TT0, TT0, TMP
	vpshufb	TT1, TT1, TMP
	vpshufb	TT2, TT2, TMP
	vpshufb	TT3, TT3, TMP
	ROUND_00_15_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, TT0, 0, 0
	ROUND_00_15_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, TT1, 1, 0
	ROUND_00_15_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, TT2, 2, 0
	ROUND_00_15_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, TT3, 3, 0

	//; Iteration 1: rounds 4-7
	vmovdqa	TMP, [rip + .LPSHUFFLE_BYTE_FLIP_MASK]
	VMOVPS	TT2,[DATA_PTR + 0*64 + 1*16]
	VMOVPS	TT1,[DATA_PTR + 1*64 + 1*16]
	VMOVPS	TT4,[DATA_PTR + 2*64 + 1*16]
	VMOVPS	TT3,[DATA_PTR + 3*64 + 1*16]
	TRANSPOSE	TT2, TT1, TT4, TT3, TT0, TT5
	vpshufb	TT0, TT0, TMP
	vpshufb	TT1, TT1, TMP
	vpshufb	TT2, TT2, TMP
	vpshufb	TT3, TT3, TMP
	ROUND_00_15_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, TT0, 4, 0
	ROUND_00_15_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, TT1, 5, 0
	ROUND_00_15_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, TT2, 6, 0
	ROUND_00_15_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, TT3, 7, 0

	//; Iteration 2: rounds 8-11
	vmovdqa	TMP, [rip + .LPSHUFFLE_BYTE_FLIP_MASK]
	VMOVPS	TT2,[DATA_PTR + 0*64 + 2*16]
	VMOVPS	TT1,[DATA_PTR + 1*64 + 2*16]
	VMOVPS	TT4,[DATA_PTR + 2*64 + 2*16]
	VMOVPS	TT3,[DATA_PTR + 3*64 + 2*16]
	TRANSPOSE	TT2, TT1, TT4, TT3, TT0, TT5
	vpshufb	TT0, TT0, TMP
	vpshufb	TT1, TT1, TMP
	vpshufb	TT2, TT2, TMP
	vpshufb	TT3, TT3, TMP
	ROUND_00_15_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, TT0, 8, 0
	ROUND_00_15_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, TT1, 9, 0
	ROUND_00_15_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, TT2, 10, 0
	ROUND_00_15_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, TT3, 11, 0

	//; Iteration 3: rounds 12-15
	vmovdqa	TMP, [rip + .LPSHUFFLE_BYTE_FLIP_MASK]
	VMOVPS	TT2,[DATA_PTR + 0*64 + 3*16]
	VMOVPS	TT1,[DATA_PTR + 1*64 + 3*16]
	VMOVPS	TT4,[DATA_PTR + 2*64 + 3*16]
	VMOVPS	TT3,[DATA_PTR + 3*64 + 3*16]
	TRANSPOSE	TT2, TT1, TT4, TT3, TT0, TT5
	vpshufb	TT0, TT0, TMP
	vpshufb	TT1, TT1, TMP
	vpshufb	TT2, TT2, TMP
	vpshufb	TT3, TT3, TMP
	ROUND_00_15_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, TT0, 12, 0
	ROUND_00_15_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, TT1, 13, 0
	ROUND_00_15_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, TT2, 14, 0
	ROUND_00_15_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, TT3, 15, 0

	jmp	.Lrounds_16_xx
.align 16
.Lrounds_16_xx:
//; Rounds 16-31 (16 rounds, rotating registers)
	ROUND_16_XX_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, T1, 16
	ROUND_16_XX_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, T1, 17
	ROUND_16_XX_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, T1, 18
	ROUND_16_XX_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, T1, 19
	ROUND_16_XX_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, T1, 20
	ROUND_16_XX_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, T1, 21
	ROUND_16_XX_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, T1, 22
	ROUND_16_XX_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, T1, 23
	ROUND_16_XX_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, T1, 24
	ROUND_16_XX_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, T1, 25
	ROUND_16_XX_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, T1, 26
	ROUND_16_XX_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, T1, 27
	ROUND_16_XX_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, T1, 28
	ROUND_16_XX_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, T1, 29
	ROUND_16_XX_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, T1, 30
	ROUND_16_XX_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, T1, 31

	cmp	ROUND,ROUNDS
	jb	.Lrounds_16_xx

	// add old digest
	lea TBL, [rip + .LDIGEST_4]
	vpaddd	a, a, [TBL + 0*SZ4]
	vpaddd	b, b, [TBL + 1*SZ4]
	vpaddd	c, c, [TBL + 2*SZ4]
	vpaddd	d, d, [TBL + 3*SZ4]
	vpaddd	e, e, [TBL + 4*SZ4]
	vpaddd	f, f, [TBL + 5*SZ4]
	vpaddd	g, g, [TBL + 6*SZ4]
	vpaddd	h, h, [TBL + 7*SZ4]

        // rounds with padding
        
        // save old digest
        
	vmovdqa	[rsp + _DIGEST + 0*SZ4], a
	vmovdqa	[rsp + _DIGEST + 1*SZ4], b
	vmovdqa	[rsp + _DIGEST + 2*SZ4], c
	vmovdqa	[rsp + _DIGEST + 3*SZ4], d
	vmovdqa	[rsp + _DIGEST + 4*SZ4], e
	vmovdqa	[rsp + _DIGEST + 5*SZ4], f
	vmovdqa	[rsp + _DIGEST + 6*SZ4], g
	vmovdqa	[rsp + _DIGEST + 7*SZ4], h

        lea   TBL, [rip + .LPADDING_4]
        xor   ROUND,ROUND
        jmp   .Lrounds_padding

.align 16
.Lrounds_padding:
//; 64 padding rounds - fully unrolled with explicit registers
	//; Rounds 0-7 (cycle 1)
	ROUND_00_15_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, T1, 0, 1
	ROUND_00_15_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, T1, 0, 1
	ROUND_00_15_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, T1, 0, 1
	ROUND_00_15_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, T1, 0, 1
	ROUND_00_15_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, T1, 0, 1
	ROUND_00_15_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, T1, 0, 1
	ROUND_00_15_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, T1, 0, 1
	ROUND_00_15_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, T1, 0, 1
	//; Rounds 8-15 (cycle 2)
	ROUND_00_15_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, T1, 0, 1
	ROUND_00_15_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, T1, 0, 1
	ROUND_00_15_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, T1, 0, 1
	ROUND_00_15_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, T1, 0, 1
	ROUND_00_15_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, T1, 0, 1
	ROUND_00_15_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, T1, 0, 1
	ROUND_00_15_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, T1, 0, 1
	ROUND_00_15_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, T1, 0, 1
	//; Rounds 16-23 (cycle 3)
	ROUND_00_15_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, T1, 0, 1
	ROUND_00_15_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, T1, 0, 1
	ROUND_00_15_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, T1, 0, 1
	ROUND_00_15_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, T1, 0, 1
	ROUND_00_15_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, T1, 0, 1
	ROUND_00_15_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, T1, 0, 1
	ROUND_00_15_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, T1, 0, 1
	ROUND_00_15_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, T1, 0, 1
	//; Rounds 24-31 (cycle 4)
	ROUND_00_15_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, T1, 0, 1
	ROUND_00_15_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, T1, 0, 1
	ROUND_00_15_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, T1, 0, 1
	ROUND_00_15_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, T1, 0, 1
	ROUND_00_15_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, T1, 0, 1
	ROUND_00_15_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, T1, 0, 1
	ROUND_00_15_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, T1, 0, 1
	ROUND_00_15_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, T1, 0, 1
	//; Rounds 32-39 (cycle 5)
	ROUND_00_15_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, T1, 0, 1
	ROUND_00_15_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, T1, 0, 1
	ROUND_00_15_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, T1, 0, 1
	ROUND_00_15_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, T1, 0, 1
	ROUND_00_15_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, T1, 0, 1
	ROUND_00_15_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, T1, 0, 1
	ROUND_00_15_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, T1, 0, 1
	ROUND_00_15_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, T1, 0, 1
	//; Rounds 40-47 (cycle 6)
	ROUND_00_15_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, T1, 0, 1
	ROUND_00_15_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, T1, 0, 1
	ROUND_00_15_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, T1, 0, 1
	ROUND_00_15_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, T1, 0, 1
	ROUND_00_15_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, T1, 0, 1
	ROUND_00_15_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, T1, 0, 1
	ROUND_00_15_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, T1, 0, 1
	ROUND_00_15_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, T1, 0, 1
	//; Rounds 48-55 (cycle 7)
	ROUND_00_15_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, T1, 0, 1
	ROUND_00_15_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, T1, 0, 1
	ROUND_00_15_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, T1, 0, 1
	ROUND_00_15_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, T1, 0, 1
	ROUND_00_15_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, T1, 0, 1
	ROUND_00_15_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, T1, 0, 1
	ROUND_00_15_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, T1, 0, 1
	ROUND_00_15_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, T1, 0, 1
	//; Rounds 56-63 (cycle 8)
	ROUND_00_15_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, T1, 0, 1
	ROUND_00_15_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, T1, 0, 1
	ROUND_00_15_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, T1, 0, 1
	ROUND_00_15_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, T1, 0, 1
	ROUND_00_15_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, T1, 0, 1
	ROUND_00_15_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, T1, 0, 1
	ROUND_00_15_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, T1, 0, 1
	ROUND_00_15_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, T1, 0, 1 

	// add old digest
	vpaddd	a, a, [rsp + _DIGEST + 0*SZ4]
	vpaddd	b, b, [rsp + _DIGEST + 1*SZ4]
	vpaddd	c, c, [rsp + _DIGEST + 2*SZ4]
	vpaddd	d, d, [rsp + _DIGEST + 3*SZ4]
	vpaddd	e, e, [rsp + _DIGEST + 4*SZ4]
	vpaddd	f, f, [rsp + _DIGEST + 5*SZ4]
	vpaddd	g, g, [rsp + _DIGEST + 6*SZ4]
	vpaddd	h, h, [rsp + _DIGEST + 7*SZ4]

	// transpose the digest and convert to little endian to get the registers correctly

	TRANSPOSE a, b, c, d, TT0, TT1
        TRANSPOSE e, f, g, h, TT2, TT1

	vmovdqa	TMP, [rip + .LPSHUFFLE_BYTE_FLIP_MASK]
        vpshufb TT0, TT0, TMP
        vpshufb TT2, TT2, TMP
        vpshufb b, b, TMP
        vpshufb f, f, TMP
        vpshufb a, a, TMP
        vpshufb e, e, TMP
        vpshufb d, d, TMP
        vpshufb h, h, TMP


	// write to output

	vmovdqu	[OUTPUT_PTR + 0*SZ4],TT0
	vmovdqu	[OUTPUT_PTR + 1*SZ4],TT2
	vmovdqu	[OUTPUT_PTR + 2*SZ4],b
	vmovdqu	[OUTPUT_PTR + 3*SZ4],f
	vmovdqu	[OUTPUT_PTR + 4*SZ4],a
	vmovdqu	[OUTPUT_PTR + 5*SZ4],e
	vmovdqu	[OUTPUT_PTR + 6*SZ4],d
	vmovdqu	[OUTPUT_PTR + 7*SZ4],h

	// update pointers and loop

        add 	DATA_PTR, 64*4
	add 	OUTPUT_PTR, 32*4
	sub 	NUM_BLKS, 4
        jmp     .Lsha256_4_avx_loop

.Lsha256_4_avx_epilog:
#ifdef __WIN64__
	vmovdqa	xmm6,[rsp + _XMM_SAVE + 0*16]
	vmovdqa	xmm7,[rsp + _XMM_SAVE + 1*16]
	vmovdqa	xmm8,[rsp + _XMM_SAVE + 2*16]
	vmovdqa	xmm9,[rsp + _XMM_SAVE + 3*16]
	vmovdqa	xmm10,[rsp + _XMM_SAVE + 4*16]
	vmovdqa	xmm11,[rsp + _XMM_SAVE + 5*16]
	vmovdqa	xmm12,[rsp + _XMM_SAVE + 6*16]
	vmovdqa	xmm13,[rsp + _XMM_SAVE + 7*16]
	vmovdqa	xmm14,[rsp + _XMM_SAVE + 8*16]
	vmovdqa	xmm15,[rsp + _XMM_SAVE + 9*16]
#endif 

	add	rsp, sha256_avx_4_stack_size
        jmp     hashtree_sha256_avx_x1
#ifdef __linux__ 
.size hashtree_sha256_avx_x4,.-hashtree_sha256_avx_x4
.section .note.GNU-stack,"",@progbits
#endif
#endif
