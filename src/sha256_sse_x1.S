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
Copied parts are
	Copyright (c) 2012-2021, Intel Corporation
*/

#ifdef __x86_64__
.intel_syntax noprefix

.section .rodata
.align 64
.LK256:
	.long	0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5
	.long	0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5
	.long	0xd807aa98,0x12835b01,0x243185be,0x550c7dc3
	.long	0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174
	.long	0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc
	.long	0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da
	.long	0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7
	.long	0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967
	.long	0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13
	.long	0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85
	.long	0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3
	.long	0xd192e819,0xd6990624,0xf40e3585,0x106aa070
	.long	0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5
	.long	0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3
	.long	0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208
	.long	0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2

.LDIGEST:
        .long   0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
	.long	0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

.LPADDING:
        .long      0xc28a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5
        .long      0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
        .long      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3
        .long      0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf374
        .long      0x649b69c1, 0xf0fe4786, 0x0fe1edc6, 0x240cf254
        .long      0x4fe9346f, 0x6cc984be, 0x61b9411e, 0x16f988fa
        .long      0xf2c65152, 0xa88e5a6d, 0xb019fc65, 0xb9d99ec7
        .long      0x9a1231c3, 0xe70eeaa0, 0xfdb1232b, 0xc7353eb0
        .long      0x3069bad5, 0xcb976d5f, 0x5a0f118f, 0xdc1eeefd
        .long      0x0a35b689, 0xde0b7a04, 0x58f4ca9d, 0xe15d5b16
        .long      0x007f3e86, 0x37088980, 0xa507ea32, 0x6fab9537
        .long      0x17406110, 0x0d8cd6f1, 0xcdaa3b6d, 0xc0bbbe37
        .long      0x83613bda, 0xdb48a363, 0x0b02e931, 0x6fd15ca7
        .long      0x521afaca, 0x31338431, 0x6ed41a95, 0x6d437890
        .long      0xc39c91f2, 0x9eccabbd, 0xb5c9a0e6, 0x532fb63c
        .long      0xd2c741c6, 0x07237ea3, 0xa4954b68, 0x4c191d76


.LPSHUFFLE_BYTE_FLIP_MASK: //.longq 0x0c0d0e0f08090a0b0405060700010203
	.quad 0x0405060700010203, 0x0c0d0e0f08090a0b

// shuffle xBxA -> 00BA
.L_SHUF_00BA:              //d.quad 0xFFFFFFFFFFFFFFFF0b0a090803020100
	.quad 0x0b0a090803020100, 0xFFFFFFFFFFFFFFFF

// shuffle xDxC -> DC00
.L_SHUF_DC00:              //d.quad 0x0b0a090803020100FFFFFFFFFFFFFFFF
	.quad 0xFFFFFFFFFFFFFFFF, 0x0b0a090803020100


#define	MOVDQ movdqu 

.macro COPY_XMM_AND_BSWAP t1, t2, t3
	MOVDQ \t1, \t2
	pshufb \t1, \t3
.endm


.equ X0, xmm4
.equ X1, xmm5
.equ X2, xmm6
.equ X3, xmm7

.equiv XTMP0, xmm0
.equiv XTMP1, xmm1
.equiv XTMP2, xmm2
.equiv XTMP3, xmm3
.equiv XTMP4, xmm8
.equiv XFER , xmm9

.equiv SHUF_00BA, xmm10
.equiv SHUF_DC00, xmm11
.equiv BYTE_FLIP_MASK, xmm12

#ifdef __WIN64__
                    .equiv OUTPUT_PTR, rcx
                    .equiv DATA_PTR, rdx
                    .equiv count, r8
                    .equ c, edi
                    .equ d, esi
#else
                    .equiv OUTPUT_PTR, rdi
                    .equiv DATA_PTR, rsi
                    .equiv count, rdx
                    .equ c, ecx
                    .equ d, r8d
#endif
.equiv TBL, rbp
.equ a, eax
.equ b, ebx
.equ f, r9d
.equ g, r10d
.equ h, r11d
.equ e, r12d

.equiv y0, r13d
.equiv y1, r14d
.equiv y2, r15d

# stack usage
#ifdef __WIN64__
                    #define _XMM_SAVE 64
                    #define STACK_SIZE 192
#else
                    #define STACK_SIZE 88
#endif 
#define _DIGEST 32
.macro ROTATE_ARGS
.equ TMP_, h
.equ h, g
.equ g, f
.equ f, e
.equ e, d
.equ d, c
.equ c, b
.equ b, a
.equ a, TMP_
.endm

.macro rotate_Xs
.equ X_, X0
.equ X0, X1
.equ X1, X2
.equ X2, X3
.equ X3, X_
.endm

.macro FOUR_ROUNDS_AND_SCHED
		# compute s0 four at a time and s1 two at a time
		# compute W[-16] + W[-7] 4 at a time
		movdqa	XTMP0, X3
		palignr	XTMP0, X2, 4	// XTMP0 = W[-7]
		movdqa	XTMP1, X1
		palignr	XTMP1, X0, 4	// XTMP1 = W[-15]
		paddd	XTMP0, X0	// XTMP0 = W[-7] + W[-16]
		
		# Overlap CPU and SIMD operations for better scheduling
	mov	y0, e		// y0 = e
		movdqa	XTMP2, XTMP1	// XTMP2 = W[-15]
	mov	y1, a		// y1 = a
		movdqa	XTMP3, XTMP1	// XTMP3 = W[-15]
	ror	y0, (25-11)	// y0 = e >> (25-11)
		pslld	XTMP1, (32-7)
	ror	y1, (22-13)	// y1 = a >> (22-13)
		psrld	XTMP2, 7
	xor	y0, e		// y0 = e ^ (e >> (25-11))
		por	XTMP1, XTMP2	// XTMP1 = W[-15] ror 7
	mov	y2, f		// y2 = f
	ror	y0, (11-6)	// y0 = (e >> (11-6)) ^ (e >> (25-6))
	xor	y1, a		// y1 = a ^ (a >> (22-13))
	xor	y2, g		// y2 = f^g
	xor	y0, e		// y0 = e ^ (e >> (11-6)) ^ (e >> (25-6))
	and	y2, e		// y2 = (f^g)&e
	ror	y1, (13-2)	// y1 = (a >> (13-2)) ^ (a >> (22-2))
	xor	y1, a		// y1 = a ^ (a >> (13-2)) ^ (a >> (22-2))
	ror	y0, 6		// y0 = S1 = (e>>6) & (e>>11) ^ (e>>25)
	xor	y2, g		// y2 = CH = ((f^g)&e)^g
	ror	y1, 2		// y1 = S0 = (a>>2) ^ (a>>13) ^ (a>>22)
	add	y2, y0		// y2 = S1 + CH
	add	y2, [rsp + 0*4]	// y2 = k + w + S1 + CH
	mov	y0, a		// y0 = a
	add	h, y2		// h = h + S1 + CH + k + w
	mov	y2, a		// y2 = a
	or	y0, c		// y0 = a|c
	add	d, h		// d = d + h + S1 + CH + k + w
	and	y2, c		// y2 = a&c
	and	y0, b		// y0 = (a|c)&b
	add	h, y1		// h = h + S1 + CH + k + w + S0
	or	y0, y2		// y0 = MAJ = (a|c)&b)|(a&c)
	add	h, y0		// h = h + S1 + CH + k + w + S0 + MAJ

ROTATE_ARGS
		# Continue with second round - better scheduling
		movdqa	XTMP2, XTMP3	// XTMP2 = W[-15]
		movdqa	XTMP4, XTMP3	// XTMP4 = W[-15]
		pslld	XTMP3, (32-18)
		psrld	XTMP2, 18
		psrld	XTMP4, 3	// XTMP4 = W[-15] >> 3
		pxor	XTMP1, XTMP3
		pxor	XTMP1, XTMP2	// XTMP1 = W[-15] ror 7 ^ W[-15] ror 18
		pxor	XTMP1, XTMP4	// XTMP1 = s0
		
	mov	y0, e		// y0 = e
	mov	y1, a		// y1 = a
	ror	y0, (25-11)	// y0 = e >> (25-11)
	xor	y0, e		// y0 = e ^ (e >> (25-11))
	mov	y2, f		// y2 = f
	ror	y1, (22-13)	// y1 = a >> (22-13)
	xor	y1, a		// y1 = a ^ (a >> (22-13))
	ror	y0, (11-6)	// y0 = (e >> (11-6)) ^ (e >> (25-6))
	xor	y2, g		// y2 = f^g
	ror	y1, (13-2)	// y1 = (a >> (13-2)) ^ (a >> (22-2))
	xor	y0, e		// y0 = e ^ (e >> (11-6)) ^ (e >> (25-6))
	and	y2, e		// y2 = (f^g)&e
	ror	y0, 6		// y0 = S1 = (e>>6) & (e>>11) ^ (e>>25)
	xor	y1, a		// y1 = a ^ (a >> (13-2)) ^ (a >> (22-2))
	xor	y2, g		// y2 = CH = ((f^g)&e)^g
	add	y2, y0		// y2 = S1 + CH
	ror	y1, 2		// y1 = S0 = (a>>2) ^ (a>>13) ^ (a>>22)
	add	y2, [rsp + 1*4]	// y2 = k + w + S1 + CH
	mov	y0, a		// y0 = a
	add	h, y2		// h = h + S1 + CH + k + w
	mov	y2, a		// y2 = a
		# compute low s1
		pshufd	XTMP2, X3, 0b11111010	// XTMP2 = W[-2] {BBAA}
	or	y0, c		// y0 = a|c
	add	d, h		// d = d + h + S1 + CH + k + w
	and	y2, c		// y2 = a&c
	and	y0, b		// y0 = (a|c)&b
	add	h, y1		// h = h + S1 + CH + k + w + S0
		paddd	XTMP0, XTMP1	// XTMP0 = W[-16] + W[-7] + s0
	or	y0, y2		// y0 = MAJ = (a|c)&b)|(a&c)
	add	h, y0		// h = h + S1 + CH + k + w + S0 + MAJ

ROTATE_ARGS
		movdqa	XTMP3, XTMP2	// XTMP3 = W[-2] {BBAA}
	mov	y0, e		// y0 = e
	mov	y1, a		// y1 = a
	ror	y0, (25-11)	// y0 = e >> (25-11)
		movdqa	XTMP4, XTMP2	// XTMP4 = W[-2] {BBAA}
	xor	y0, e		// y0 = e ^ (e >> (25-11))
	ror	y1, (22-13)	// y1 = a >> (22-13)
	mov	y2, f		// y2 = f
	xor	y1, a		// y1 = a ^ (a >> (22-13)
	ror	y0, (11-6)	// y0 = (e >> (11-6)) ^ (e >> (25-6))
		psrlq	XTMP2, 17	// XTMP2 = W[-2] ror 17 {xBxA}
	xor	y2, g		// y2 = f^g
		psrlq	XTMP3, 19	// XTMP3 = W[-2] ror 19 {xBxA}
	xor	y0, e		// y0 = e ^ (e >> (11-6)) ^ (e >> (25-6))
	and	y2, e		// y2 = (f^g)&e
		psrld	XTMP4, 10	// XTMP4 = W[-2] >> 10 {BBAA}
	ror	y1, (13-2)	// y1 = (a >> (13-2)) ^ (a >> (22-2))
	xor	y1, a		// y1 = a ^ (a >> (13-2)) ^ (a >> (22-2))
	xor	y2, g		// y2 = CH = ((f^g)&e)^g
	ror	y0, 6		// y0 = S1 = (e>>6) & (e>>11) ^ (e>>25)
		pxor	XTMP2, XTMP3
	add	y2, y0		// y2 = S1 + CH
	ror	y1, 2		// y1 = S0 = (a>>2) ^ (a>>13) ^ (a>>22)
	add	y2, [rsp + 2*4]	// y2 = k + w + S1 + CH
		pxor	XTMP4, XTMP2	// XTMP4 = s1 {xBxA}
	mov	y0, a		// y0 = a
	add	h, y2		// h = h + S1 + CH + k + w
	mov	y2, a		// y2 = a
		pshufb	XTMP4, SHUF_00BA	// XTMP4 = s1 {00BA}
	or	y0, c		// y0 = a|c
	add	d, h		// d = d + h + S1 + CH + k + w
	and	y2, c		// y2 = a&c
		paddd	XTMP0, XTMP4	// XTMP0 = {..., ..., W[1], W[0]}
	and	y0, b		// y0 = (a|c)&b
	add	h, y1		// h = h + S1 + CH + k + w + S0
		# compute high s1
		pshufd	XTMP2, XTMP0, 0b01010000	// XTMP2 = W[-2] {DDCC}
	or	y0, y2		// y0 = MAJ = (a|c)&b)|(a&c)
	add	h, y0		// h = h + S1 + CH + k + w + S0 + MAJ

ROTATE_ARGS
		movdqa	XTMP3, XTMP2	// XTMP3 = W[-2] {DDCC}
	mov	y0, e		// y0 = e
	ror	y0, (25-11)	// y0 = e >> (25-11)
	mov	y1, a		// y1 = a
		movdqa	X0,    XTMP2	// X0    = W[-2] {DDCC}
	ror	y1, (22-13)	// y1 = a >> (22-13)
	xor	y0, e		// y0 = e ^ (e >> (25-11))
	mov	y2, f		// y2 = f
	ror	y0, (11-6)	// y0 = (e >> (11-6)) ^ (e >> (25-6))
		psrlq	XTMP2, 17	// XTMP2 = W[-2] ror 17 {xDxC}
	xor	y1, a		// y1 = a ^ (a >> (22-13)
	xor	y2, g		// y2 = f^g
		psrlq	XTMP3, 19	// XTMP3 = W[-2] ror 19 {xDxC}
	xor	y0, e		// y0 = e ^ (e >> (11-6)) ^ (e >> (25-6))
	and	y2, e		// y2 = (f^g)&e
	ror	y1, (13-2)	// y1 = (a >> (13-2)) ^ (a >> (22-2))
		psrld	X0,    10	// X0 = W[-2] >> 10 {DDCC}
	xor	y1, a		// y1 = a ^ (a >> (13-2)) ^ (a >> (22-2))
	ror	y0, 6		// y0 = S1 = (e>>6) & (e>>11) ^ (e>>25)
	xor	y2, g		// y2 = CH = ((f^g)&e)^g
		pxor	XTMP2, XTMP3
	ror	y1, 2		// y1 = S0 = (a>>2) ^ (a>>13) ^ (a>>22)
	add	y2, y0		// y2 = S1 + CH
	add	y2, [rsp + 3*4]	// y2 = k + w + S1 + CH
		pxor	X0, XTMP2	// X0 = s1 {xDxC}
	mov	y0, a		// y0 = a
	add	h, y2		// h = h + S1 + CH + k + w
	mov	y2, a		// y2 = a
		pshufb	X0, SHUF_DC00	// X0 = s1 {DC00}
	or	y0, c		// y0 = a|c
	add	d, h		// d = d + h + S1 + CH + k + w
	and	y2, c		// y2 = a&c
		paddd	X0, XTMP0	// X0 = {W[3], W[2], W[1], W[0]}
	and	y0, b		// y0 = (a|c)&b
	add	h, y1		// h = h + S1 + CH + k + w + S0
	or	y0, y2		// y0 = MAJ = (a|c)&b)|(a&c)
	add	h, y0		// h = h + S1 + CH + k + w + S0 + MAJ
ROTATE_ARGS
rotate_Xs
.endm

.macro DO_ROUND base, offset
	mov	y0, e		// y0 = e
	ror	y0, (25-11)	// y0 = e >> (25-11)
	mov	y1, a		// y1 = a
	xor	y0, e		// y0 = e ^ (e >> (25-11))
	ror	y1, (22-13)	// y1 = a >> (22-13)
	mov	y2, f		// y2 = f
	xor	y1, a		// y1 = a ^ (a >> (22-13)
	ror	y0, (11-6)	// y0 = (e >> (11-6)) ^ (e >> (25-6))
	xor	y2, g		// y2 = f^g
	xor	y0, e		// y0 = e ^ (e >> (11-6)) ^ (e >> (25-6))
	ror	y1, (13-2)	// y1 = (a >> (13-2)) ^ (a >> (22-2))
	and	y2, e		// y2 = (f^g)&e
	xor	y1, a		// y1 = a ^ (a >> (13-2)) ^ (a >> (22-2))
	ror	y0, 6		// y0 = S1 = (e>>6) & (e>>11) ^ (e>>25)
	xor	y2, g		// y2 = CH = ((f^g)&e)^g
	add	y2, y0		// y2 = S1 + CH
	ror	y1, 2		// y1 = S0 = (a>>2) ^ (a>>13) ^ (a>>22)
	add	y2, [\base + \offset]	// y2 = k + w + S1 + CH
	mov	y0, a		// y0 = a
	add	h, y2		// h = h + S1 + CH + k + w
	mov	y2, a		// y2 = a
	or	y0, c		// y0 = a|c
	add	d, h		// d = d + h + S1 + CH + k + w
	and	y2, c		// y2 = a&c
	and	y0, b		// y0 = (a|c)&b
	add	h, y1		// h = h + S1 + CH + k + w + S0
	or	y0, y2		// y0 = MAJ = (a|c)&b)|(a&c)
	add	h, y0		// h = h + S1 + CH + k + w + S0 + MAJ
	ROTATE_ARGS
.endm

.text
.global hashtree_sha256_sse_x1
#ifndef __WIN64__
.type hashtree_sha256_sse_x1,%function
#endif
.align 32
hashtree_sha256_sse_x1:
	push	rbx
#ifdef __WIN64__
        push    r8
	push	rsi
	push	rdi
#endif
	push	rbp
        push    r12
	push	r13
	push	r14
	push	r15

	sub	rsp,STACK_SIZE
#ifdef __WIN64__
	movdqa	[rsp + _XMM_SAVE + 0*16],xmm6
	movdqa	[rsp + _XMM_SAVE + 1*16],xmm7
	movdqa	[rsp + _XMM_SAVE + 2*16],xmm8
	movdqa	[rsp + _XMM_SAVE + 3*16],xmm9
	movdqa	[rsp + _XMM_SAVE + 4*16],xmm10
	movdqa	[rsp + _XMM_SAVE + 5*16],xmm11
	movdqa	[rsp + _XMM_SAVE + 6*16],xmm12
	movdqa	[rsp + _XMM_SAVE + 7*16],xmm13
#endif
	movdqa	BYTE_FLIP_MASK, [rip + .LPSHUFFLE_BYTE_FLIP_MASK]
	movdqa	SHUF_00BA, [rip + .L_SHUF_00BA]
	movdqa	SHUF_DC00, [rip + .L_SHUF_DC00]

        shl     count, 5
        add     count, OUTPUT_PTR

.Lsha256_sse_1_block_loop:
        cmp     OUTPUT_PTR, count
        je      .Lsha256_1_sse_epilog

	# load initial digest
	lea	TBL,[rip + .LDIGEST]
	mov	a, [4*0 + TBL]
	mov	b, [4*1 + TBL]
	mov	c, [4*2 + TBL]
	mov	d, [4*3 + TBL]
	mov	e, [4*4 + TBL]
	mov	f, [4*5 + TBL]
	mov	g, [4*6 + TBL]
	mov	h, [4*7 + TBL]

        lea     TBL,[rip + .LK256]

	# byte swap first 16 dwords with multi-level prefetching
	prefetchnta	[DATA_PTR + 512]		# L3 prefetch 8 blocks ahead
	prefetcht2	[DATA_PTR + 256]		# L2 prefetch 4 blocks ahead
	prefetcht0	[DATA_PTR + 128]		# L1 prefetch 2 blocks ahead
	COPY_XMM_AND_BSWAP	X0, [DATA_PTR + 0*16], BYTE_FLIP_MASK
	COPY_XMM_AND_BSWAP	X1, [DATA_PTR + 1*16], BYTE_FLIP_MASK
	COPY_XMM_AND_BSWAP	X2, [DATA_PTR + 2*16], BYTE_FLIP_MASK
	COPY_XMM_AND_BSWAP	X3, [DATA_PTR + 3*16], BYTE_FLIP_MASK

	# schedule 48 input dwords, by doing 3 rounds of 16 each
	# optimized with better alignment and prefetching

.rept 3
.align 32
	# Process 4 blocks with optimized scheduling
	movdqa	XFER, [TBL + 0*16]
	paddd	XFER, X0
	movdqa	[rsp], XFER
	prefetcht0	[TBL + 8*16]		# prefetch K constants to L1 cache
	FOUR_ROUNDS_AND_SCHED

	movdqa	XFER, [TBL + 1*16]
	paddd	XFER, X0
	movdqa	[rsp], XFER
	FOUR_ROUNDS_AND_SCHED

	movdqa	XFER, [TBL + 2*16]
	paddd	XFER, X0
	movdqa	[rsp], XFER
	FOUR_ROUNDS_AND_SCHED

	movdqa	XFER, [TBL + 3*16]
	paddd	XFER, X0
	movdqa	[rsp], XFER
	add	TBL, 4*16
	FOUR_ROUNDS_AND_SCHED
.endr

.rept 2
	paddd	X0, [TBL + 0*16]
	movdqa	[rsp], X0
	DO_ROUND	rsp, 0
	DO_ROUND	rsp, 4
	DO_ROUND	rsp, 8
	DO_ROUND	rsp, 12
	paddd	X1, [TBL + 1*16]
	movdqa	[rsp], X1
	add	TBL, 2*16
	DO_ROUND	rsp, 0
	DO_ROUND	rsp, 4
	DO_ROUND	rsp, 8
	DO_ROUND	rsp, 12

	movdqa	X0, X2
	movdqa	X1, X3
.endr 

        lea     TBL,[rip + .LDIGEST]
	add	a, [TBL + 0*4]
	add	b, [TBL + 1*4]
	add	c, [TBL + 2*4]
	add	d, [TBL + 3*4]
	add	e, [TBL + 4*4]
	add	f, [TBL + 5*4]
	add	g, [TBL + 6*4]
	add	h, [TBL + 7*4]

        // rounds with padding
        
        // save old digest
        mov    [rsp + _DIGEST + 0*4], a
        mov    [rsp + _DIGEST + 1*4], b
        mov    [rsp + _DIGEST + 2*4], c
        mov    [rsp + _DIGEST + 3*4], d
        mov    [rsp + _DIGEST + 4*4], e
        mov    [rsp + _DIGEST + 5*4], f
        mov    [rsp + _DIGEST + 6*4], g
        mov    [rsp + _DIGEST + 7*4], h
       
        lea     TBL,[rip + .LPADDING]
       
.set .Li, 0
.rept 64
                    DO_ROUND TBL, .Li
	            .set .Li, .Li+4
.endr

        // add the previous digest
        add   a, [rsp + _DIGEST + 0*4]
        add   b, [rsp + _DIGEST + 1*4]
        add   c, [rsp + _DIGEST + 2*4]
        add   d, [rsp + _DIGEST + 3*4]
        add   e, [rsp + _DIGEST + 4*4]
        add   f, [rsp + _DIGEST + 5*4]
        add   g, [rsp + _DIGEST + 6*4]
        add   h, [rsp + _DIGEST + 7*4]

        // shuffle the bytes to little endian
        bswap  a
        bswap  b
        bswap  c
        bswap  d
        bswap  e
        bswap  f
        bswap  g
        bswap  h

        // write resulting hash
        mov   [OUTPUT_PTR + 0*4], a
        mov   [OUTPUT_PTR + 1*4], b
        mov   [OUTPUT_PTR + 2*4], c
        mov   [OUTPUT_PTR + 3*4], d
        mov   [OUTPUT_PTR + 4*4], e
        mov   [OUTPUT_PTR + 5*4], f
        mov   [OUTPUT_PTR + 6*4], g
        mov   [OUTPUT_PTR + 7*4], h

        add   OUTPUT_PTR, 32
        add   DATA_PTR, 64
        jmp   .Lsha256_sse_1_block_loop

.Lsha256_1_sse_epilog:

#ifdef __WIN64__
	vmovdqa	xmm6,[rsp + _XMM_SAVE + 0*16]
	vmovdqa	xmm7,[rsp + _XMM_SAVE + 1*16]
	vmovdqa	xmm8,[rsp + _XMM_SAVE + 2*16]
	vmovdqa	xmm9,[rsp + _XMM_SAVE + 3*16]
	vmovdqa	xmm10,[rsp + _XMM_SAVE + 4*16]
	vmovdqa	xmm11,[rsp + _XMM_SAVE + 5*16]
	vmovdqa	xmm12,[rsp + _XMM_SAVE + 6*16]
	vmovdqa	xmm13,[rsp + _XMM_SAVE + 7*16]
#endif 

	add	rsp, STACK_SIZE

	pop	r15
	pop	r14
	pop	r13
        pop     r12
	pop	rbp
#ifdef __WIN64__
	pop	rdi
	pop	rsi
        pop     r8
#endif
	pop	rbx

	ret
#ifdef __linux__ 
.size hashtree_sha256_sse_x1,.-hashtree_sha256_sse_x1
.section .note.GNU-stack,"",@progbits
#endif
#endif
