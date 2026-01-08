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
.align 16
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

.text
# define VMOVDQ vmovdqu

.macro MY_ROR src, shf
	shld        \src, \src, (32-\shf)
.endm

// COPY_XMM_AND_BSWAP xmm, [mem], byte_flip_mask
// Load xmm with mem and byte swap each dword
.macro COPY_XMM_AND_BSWAP dst, src, msk
	VMOVDQ      \dst, \src
	vpshufb     \dst, \dst, \msk
.endm

#define INI_X0 xmm4
#define INI_X1 xmm5
#define INI_X2 xmm6
#define INI_X3 xmm7

#define XTMP0 xmm0
#define XTMP1 xmm1
#define XTMP2 xmm2
#define XTMP3 xmm3
#define XTMP4 xmm8
#define XFER xmm9
#define XTMP5 xmm11

#define SHUF_00BA	xmm10 // shuffle xBxA -> 00BA
#define SHUF_DC00	xmm12 // shuffle xDxC -> DC00
#define BYTE_FLIP_MASK	xmm13

#ifdef __WIN64__
                    #define OUTPUT_PTR rcx            // 1st arg
                    #define DATA_PTR rdx              // 2nd arg
                    #define INI_d ebp
                    #define count r8                  // 3rd arg

                    #define TBL rsi
                    #define INI_c edi
                    #define _XMM_SAVE 64
                    #define stack_size 192
#else
                    #define OUTPUT_PTR rdi            // 1st arg
                    #define DATA_PTR rsi              // 2nd arg
                    #define INI_c ebp
                    #define count rdx                 // 3rd arg

                    #define TBL rcx
                    #define INI_d r8d
                    #define stack_size 88
#endif

#define _DIGEST 32

#define INI_a eax
#define INI_b ebx
#define INI_e r9d
#define INI_f r10d
#define INI_g r11d
#define INI_h r12d

#define y0 r13d
#define y1 r14d
#define y2 r15d

// These aliases are used for non-macro code where rotation state is at initial
#define a_ INI_a
#define b_ INI_b
#define c_ INI_c
#define d_ INI_d
#define e_ INI_e
#define f_ INI_f
#define g_ INI_g
#define h_ INI_h
#define X0 INI_X0
#define X1 INI_X1
#define X2 INI_X2
#define X3 INI_X3

// Rotation macros removed - using parameterized macros instead

// Parameterized FOUR_ROUNDS_AND_SCHED
// Takes 12 params: 8 GPR (a-h) and 4 XMM (x0-x3)
// After this macro: GPR state rotates by 4 (a,b,c,d,e,f,g,h) -> (e,f,g,h,a,b,c,d)
//                   XMM state rotates by 1 (x0,x1,x2,x3) -> (x1,x2,x3,x0)
.macro FOUR_ROUNDS_AND_SCHED_P ra, rb, rc, rd, re, rf, rg, rh, x0, x1, x2, x3
	// Round 0: a=ra, b=rb, c=rc, d=rd, e=re, f=rf, g=rg, h=rh
	mov	y0, \re
	MY_ROR	y0, (25-11)
	mov	y1, \ra
		vpalignr	XTMP0, \x3, \x2, 4
	MY_ROR	y1, (22-13)
	xor	y0, \re
	mov	y2, \rf
	MY_ROR	y0, (11-6)
	xor	y1, \ra
	xor	y2, \rg
		vpaddd	XTMP0, XTMP0, \x0
	xor	y0, \re
	and	y2, \re
	MY_ROR	y1, (13-2)
		vpalignr	XTMP1, \x1, \x0, 4
	xor	y1, \ra
	MY_ROR	y0, 6
	xor	y2, \rg
	MY_ROR	y1, 2
	add	y2, y0
	add	y2, [rsp + 0*4]
	mov	y0, \ra
	add	\rh, y2
	mov	y2, \ra
		vpsrld	XTMP2, XTMP1, 7
	or	y0, \rc
	add	\rd, \rh
	and	y2, \rc
		vpslld	XTMP3, XTMP1, (32-7)
	and	y0, \rb
	add	\rh, y1
		vpor	XTMP3, XTMP3, XTMP2
	or	y0, y2
	add	\rh, y0

	// Round 1: a=rh, b=ra, c=rb, d=rc, e=rd, f=re, g=rf, h=rg
	mov	y0, \rd
	mov	y1, \rh
	MY_ROR	y0, (25-11)
	xor	y0, \rd
	mov	y2, \re
	MY_ROR	y1, (22-13)
		vpsrld	XTMP2, XTMP1,18
	xor	y1, \rh
	MY_ROR	y0, (11-6)
	xor	y2, \rf
		vpsrld	XTMP4, XTMP1, 3
	MY_ROR	y1, (13-2)
	xor	y0, \rd
	and	y2, \rd
	MY_ROR	y0, 6
		vpslld	XTMP1, XTMP1, (32-18)
	xor	y1, \rh
	xor	y2, \rf
		vpxor	XTMP3, XTMP3, XTMP1
	add	y2, y0
	add	y2, [rsp + 1*4]
	MY_ROR	y1, 2
		vpxor	XTMP3, XTMP3, XTMP2
	mov	y0, \rh
	add	\rg, y2
	mov	y2, \rh
		vpxor	XTMP1, XTMP3, XTMP4
	or	y0, \rb
	add	\rc, \rg
	and	y2, \rb
		vpshufd	XTMP2, \x3, 0b11111010
	and	y0, \ra
	add	\rg, y1
		vpaddd	XTMP0, XTMP0, XTMP1
	or	y0, y2
	add	\rg, y0

	// Round 2: a=rg, b=rh, c=ra, d=rb, e=rc, f=rd, g=re, h=rf
	mov	y0, \rc
	mov	y1, \rg
	MY_ROR	y0, (25-11)
	xor	y0, \rc
	MY_ROR	y1, (22-13)
	mov	y2, \rd
	xor	y1, \rg
	MY_ROR	y0, (11-6)
		vpsrld	XTMP4, XTMP2, 10
	xor	y2, \re
		vpsrlq	XTMP3, XTMP2, 19
	xor	y0, \rc
	and	y2, \rc
		vpsrlq	XTMP2, XTMP2, 17
	MY_ROR	y1, (13-2)
	xor	y1, \rg
	xor	y2, \re
	MY_ROR	y0, 6
		vpxor	XTMP2, XTMP2, XTMP3
	add	y2, y0
	MY_ROR	y1, 2
	add	y2, [rsp + 2*4]
		vpxor	XTMP4, XTMP4, XTMP2
	mov	y0, \rg
	add	\rf, y2
	mov	y2, \rg
		vpshufb	XTMP4, XTMP4, SHUF_00BA
	or	y0, \ra
	add	\rb, \rf
	and	y2, \ra
		vpaddd	XTMP0, XTMP0, XTMP4
	and	y0, \rh
	add	\rf, y1
		vpshufd	XTMP2, XTMP0, 0b01010000
	or	y0, y2
	add	\rf, y0

	// Round 3: a=rf, b=rg, c=rh, d=ra, e=rb, f=rc, g=rd, h=re
	mov	y0, \rb
	MY_ROR	y0, (25-11)
	mov	y1, \rf
	MY_ROR	y1, (22-13)
	xor	y0, \rb
	mov	y2, \rc
	MY_ROR	y0, (11-6)
		vpsrld	XTMP5, XTMP2, 10
	xor	y1, \rf
	xor	y2, \rd
		vpsrlq	XTMP3, XTMP2, 19
	xor	y0, \rb
	and	y2, \rb
	MY_ROR	y1, (13-2)
		vpsrlq	XTMP2, XTMP2, 17
	xor	y1, \rf
	MY_ROR	y0, 6
	xor	y2, \rd
		vpxor	XTMP2, XTMP2, XTMP3
	MY_ROR	y1, 2
	add	y2, y0
	add	y2, [rsp + 3*4]
		vpxor	XTMP5, XTMP5, XTMP2
	mov	y0, \rf
	add	\re, y2
	mov	y2, \rf
		vpshufb	XTMP5, XTMP5, SHUF_DC00
	or	y0, \rh
	add	\ra, \re
	and	y2, \rh
		vpaddd	\x0, XTMP5, XTMP0
	and	y0, \rg
	add	\re, y1
	or	y0, y2
	add	\re, y0
.endm

// Parameterized DO_ROUND - takes all 8 working registers as parameters
// No rotation at end - caller handles register rotation by passing different args
.macro DO_ROUND_P ra, rb, rc, rd, re, rf, rg, rh, base, offset
	mov	y0, \re		// y0 = e
	MY_ROR	y0, (25-11)	// y0 = e >> (25-11)
	mov	y1, \ra		// y1 = a
	xor	y0, \re		// y0 = e ^ (e >> (25-11))
	MY_ROR	y1, (22-13)	// y1 = a >> (22-13)
	mov	y2, \rf		// y2 = f
	xor	y1, \ra		// y1 = a ^ (a >> (22-13)
	MY_ROR	y0, (11-6)	// y0 = (e >> (11-6)) ^ (e >> (25-6))
	xor	y2, \rg		// y2 = f^g
	xor	y0, \re		// y0 = e ^ (e >> (11-6)) ^ (e >> (25-6))
	MY_ROR	y1, (13-2)	// y1 = (a >> (13-2)) ^ (a >> (22-2))
	and	y2, \re		// y2 = (f^g)&e
	xor	y1, \ra		// y1 = a ^ (a >> (13-2)) ^ (a >> (22-2))
	MY_ROR	y0, 6		// y0 = S1 = (e>>6) & (e>>11) ^ (e>>25)
	xor	y2, \rg		// y2 = CH = ((f^g)&e)^g
	add	y2, y0		// y2 = S1 + CH
	MY_ROR	y1, 2		// y1 = S0 = (a>>2) ^ (a>>13) ^ (a>>22)
	add	y2, [\base + \offset]	// y2 = k + w + S1 + CH
	mov	y0, \ra		// y0 = a
	add	\rh, y2		// h = h + S1 + CH + k + w
	mov	y2, \ra		// y2 = a
	or	y0, \rc		// y0 = a|c
	add	\rd, \rh	// d = d + h + S1 + CH + k + w
	and	y2, \rc		// y2 = a&c
	and	y0, \rb		// y0 = (a|c)&b
	add	\rh, y1		// h = h + S1 + CH + k + w + S0
	or	y0, y2		// y0 = MAJ = (a|c)&b)|(a&c)
	add	\rh, y0		// h = h + S1 + CH + k + w + S0 + MAJ
.endm

.global hashtree_sha256_avx_x1
#ifndef __WIN64__
.type   hashtree_sha256_avx_x1,%function
#endif
.align 32
hashtree_sha256_avx_x1:
        endbr64
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

	sub	rsp, stack_size
#ifdef __WIN64__
	vmovdqa	[rsp + _XMM_SAVE + 0*16],xmm6
	vmovdqa	[rsp + _XMM_SAVE + 1*16],xmm7
	vmovdqa	[rsp + _XMM_SAVE + 2*16],xmm8
	vmovdqa	[rsp + _XMM_SAVE + 3*16],xmm9
	vmovdqa	[rsp + _XMM_SAVE + 4*16],xmm10
	vmovdqa	[rsp + _XMM_SAVE + 5*16],xmm11
	vmovdqa	[rsp + _XMM_SAVE + 6*16],xmm12
	vmovdqa	[rsp + _XMM_SAVE + 7*16],xmm13
#endif
	vmovdqa	BYTE_FLIP_MASK, [rip + .LPSHUFFLE_BYTE_FLIP_MASK]
	vmovdqa	SHUF_00BA, [rip + .L_SHUF_00BA]
	vmovdqa	SHUF_DC00, [rip + .L_SHUF_DC00]
   
        shl         count, 5
        add         count, OUTPUT_PTR

.Lsha256_avx_1_block_loop:
        cmp     OUTPUT_PTR, count
        je      .Lsha256_1_avx_epilog

	//; load initial digest
	lea TBL,[rip + .LDIGEST]
	mov	a_, [TBL + 0*4]
	mov	b_, [TBL + 1*4] 
	mov	c_, [TBL + 2*4] 
	mov	d_, [TBL + 3*4] 
	mov	e_, [TBL + 4*4] 
	mov	f_, [TBL + 5*4] 
	mov	g_, [TBL + 6*4] 
	mov	h_, [TBL + 7*4] 

	lea	TBL,[rip + .LK256]

	//; byte swap first 16 dwords
	COPY_XMM_AND_BSWAP	X0, [DATA_PTR + 0*16], BYTE_FLIP_MASK
	COPY_XMM_AND_BSWAP	X1, [DATA_PTR + 1*16], BYTE_FLIP_MASK
	COPY_XMM_AND_BSWAP	X2, [DATA_PTR + 2*16], BYTE_FLIP_MASK
	COPY_XMM_AND_BSWAP	X3, [DATA_PTR + 3*16], BYTE_FLIP_MASK

	//; schedule 48 input dwords, by doing 3 rounds of 16 each
	//; Rep 1 of 3
.align 32
	vpaddd	XFER, INI_X0, [TBL + 0*16]
	vmovdqa	[rsp], XFER
	FOUR_ROUNDS_AND_SCHED_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_X0, INI_X1, INI_X2, INI_X3

	vpaddd	XFER, INI_X1, [TBL + 1*16]
	vmovdqa	[rsp], XFER
	FOUR_ROUNDS_AND_SCHED_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_X1, INI_X2, INI_X3, INI_X0

	vpaddd	XFER, INI_X2, [TBL + 2*16]
	vmovdqa	[rsp], XFER
	FOUR_ROUNDS_AND_SCHED_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_X2, INI_X3, INI_X0, INI_X1

	vpaddd	XFER, INI_X3, [TBL + 3*16]
	vmovdqa	[rsp], XFER
	add	TBL, 4*16
	FOUR_ROUNDS_AND_SCHED_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_X3, INI_X0, INI_X1, INI_X2

	//; Rep 2 of 3
.align 32
	vpaddd	XFER, INI_X0, [TBL + 0*16]
	vmovdqa	[rsp], XFER
	FOUR_ROUNDS_AND_SCHED_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_X0, INI_X1, INI_X2, INI_X3

	vpaddd	XFER, INI_X1, [TBL + 1*16]
	vmovdqa	[rsp], XFER
	FOUR_ROUNDS_AND_SCHED_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_X1, INI_X2, INI_X3, INI_X0

	vpaddd	XFER, INI_X2, [TBL + 2*16]
	vmovdqa	[rsp], XFER
	FOUR_ROUNDS_AND_SCHED_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_X2, INI_X3, INI_X0, INI_X1

	vpaddd	XFER, INI_X3, [TBL + 3*16]
	vmovdqa	[rsp], XFER
	add	TBL, 4*16
	FOUR_ROUNDS_AND_SCHED_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_X3, INI_X0, INI_X1, INI_X2

	//; Rep 3 of 3
.align 32
	vpaddd	XFER, INI_X0, [TBL + 0*16]
	vmovdqa	[rsp], XFER
	FOUR_ROUNDS_AND_SCHED_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_X0, INI_X1, INI_X2, INI_X3

	vpaddd	XFER, INI_X1, [TBL + 1*16]
	vmovdqa	[rsp], XFER
	FOUR_ROUNDS_AND_SCHED_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_X1, INI_X2, INI_X3, INI_X0

	vpaddd	XFER, INI_X2, [TBL + 2*16]
	vmovdqa	[rsp], XFER
	FOUR_ROUNDS_AND_SCHED_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_X2, INI_X3, INI_X0, INI_X1

	vpaddd	XFER, INI_X3, [TBL + 3*16]
	vmovdqa	[rsp], XFER
	add	TBL, 4*16
	FOUR_ROUNDS_AND_SCHED_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_X3, INI_X0, INI_X1, INI_X2

//; Rounds 48-63 (2 reps of 8 rounds each)
	//; Rep 1: rounds 48-55
	vpaddd	XFER, X0, [TBL + 0*16]
	vmovdqa	[rsp], XFER
	DO_ROUND_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, rsp, 0
	DO_ROUND_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, rsp, 4
	DO_ROUND_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, rsp, 8
	DO_ROUND_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, rsp, 12

	vpaddd	XFER, X1, [TBL + 1*16]
	vmovdqa	[rsp], XFER
	add	TBL, 2*16
	DO_ROUND_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, rsp, 0
	DO_ROUND_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, rsp, 4
	DO_ROUND_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, rsp, 8
	DO_ROUND_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, rsp, 12

	vmovdqa	X0, X2
	vmovdqa	X1, X3

	//; Rep 2: rounds 56-63
	vpaddd	XFER, X0, [TBL + 0*16]
	vmovdqa	[rsp], XFER
	DO_ROUND_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, rsp, 0
	DO_ROUND_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, rsp, 4
	DO_ROUND_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, rsp, 8
	DO_ROUND_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, rsp, 12

	vpaddd	XFER, X1, [TBL + 1*16]
	vmovdqa	[rsp], XFER
	add	TBL, 2*16
	DO_ROUND_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, rsp, 0
	DO_ROUND_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, rsp, 4
	DO_ROUND_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, rsp, 8
	DO_ROUND_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, rsp, 12

	vmovdqa	X0, X2
	vmovdqa	X1, X3
 
        // add old digest

	lea TBL,[rip + .LDIGEST]
	add	a_, [TBL + 0*4]
	add	b_, [TBL + 1*4]
	add	c_, [TBL + 2*4]
	add	d_, [TBL + 3*4]
	add	e_, [TBL + 4*4]
	add	f_, [TBL + 5*4]
	add	g_, [TBL + 6*4]
	add	h_, [TBL + 7*4]


        // rounds with padding
        
        // save old digest
        //
        mov    [rsp + _DIGEST + 0*4], a_
        mov    [rsp + _DIGEST + 1*4], b_
        mov    [rsp + _DIGEST + 2*4], c_
        mov    [rsp + _DIGEST + 3*4], d_
        mov    [rsp + _DIGEST + 4*4], e_
        mov    [rsp + _DIGEST + 5*4], f_
        mov    [rsp + _DIGEST + 6*4], g_
        mov    [rsp + _DIGEST + 7*4], h_
       
        lea     TBL,[rip + .LPADDING]
       
//; 64 padding rounds - fully unrolled with explicit registers
	//; Rounds 0-7 (cycle 1)
	DO_ROUND_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, TBL, 0
	DO_ROUND_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, TBL, 4
	DO_ROUND_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, TBL, 8
	DO_ROUND_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, TBL, 12
	DO_ROUND_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, TBL, 16
	DO_ROUND_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, TBL, 20
	DO_ROUND_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, TBL, 24
	DO_ROUND_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, TBL, 28
	//; Rounds 8-15 (cycle 2)
	DO_ROUND_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, TBL, 32
	DO_ROUND_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, TBL, 36
	DO_ROUND_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, TBL, 40
	DO_ROUND_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, TBL, 44
	DO_ROUND_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, TBL, 48
	DO_ROUND_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, TBL, 52
	DO_ROUND_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, TBL, 56
	DO_ROUND_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, TBL, 60
	//; Rounds 16-23 (cycle 3)
	DO_ROUND_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, TBL, 64
	DO_ROUND_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, TBL, 68
	DO_ROUND_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, TBL, 72
	DO_ROUND_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, TBL, 76
	DO_ROUND_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, TBL, 80
	DO_ROUND_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, TBL, 84
	DO_ROUND_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, TBL, 88
	DO_ROUND_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, TBL, 92
	//; Rounds 24-31 (cycle 4)
	DO_ROUND_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, TBL, 96
	DO_ROUND_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, TBL, 100
	DO_ROUND_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, TBL, 104
	DO_ROUND_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, TBL, 108
	DO_ROUND_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, TBL, 112
	DO_ROUND_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, TBL, 116
	DO_ROUND_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, TBL, 120
	DO_ROUND_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, TBL, 124
	//; Rounds 32-39 (cycle 5)
	DO_ROUND_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, TBL, 128
	DO_ROUND_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, TBL, 132
	DO_ROUND_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, TBL, 136
	DO_ROUND_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, TBL, 140
	DO_ROUND_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, TBL, 144
	DO_ROUND_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, TBL, 148
	DO_ROUND_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, TBL, 152
	DO_ROUND_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, TBL, 156
	//; Rounds 40-47 (cycle 6)
	DO_ROUND_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, TBL, 160
	DO_ROUND_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, TBL, 164
	DO_ROUND_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, TBL, 168
	DO_ROUND_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, TBL, 172
	DO_ROUND_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, TBL, 176
	DO_ROUND_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, TBL, 180
	DO_ROUND_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, TBL, 184
	DO_ROUND_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, TBL, 188
	//; Rounds 48-55 (cycle 7)
	DO_ROUND_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, TBL, 192
	DO_ROUND_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, TBL, 196
	DO_ROUND_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, TBL, 200
	DO_ROUND_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, TBL, 204
	DO_ROUND_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, TBL, 208
	DO_ROUND_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, TBL, 212
	DO_ROUND_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, TBL, 216
	DO_ROUND_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, TBL, 220
	//; Rounds 56-63 (cycle 8)
	DO_ROUND_P INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, TBL, 224
	DO_ROUND_P INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, TBL, 228
	DO_ROUND_P INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, INI_f, TBL, 232
	DO_ROUND_P INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, INI_e, TBL, 236
	DO_ROUND_P INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, INI_d, TBL, 240
	DO_ROUND_P INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, INI_c, TBL, 244
	DO_ROUND_P INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, INI_b, TBL, 248
	DO_ROUND_P INI_b, INI_c, INI_d, INI_e, INI_f, INI_g, INI_h, INI_a, TBL, 252

        //; add the previous digest
        add   a_, [rsp + _DIGEST + 0*4]
        add   b_, [rsp + _DIGEST + 1*4]
        add   c_, [rsp + _DIGEST + 2*4]
        add   d_, [rsp + _DIGEST + 3*4]
        add   e_, [rsp + _DIGEST + 4*4]
        add   f_, [rsp + _DIGEST + 5*4]
        add   g_, [rsp + _DIGEST + 6*4]
        add   h_, [rsp + _DIGEST + 7*4]

        //; shuffle the bytes to little endian
        bswap  a_
        bswap  b_
        bswap  c_
        bswap  d_
        bswap  e_
        bswap  f_
        bswap  g_
        bswap  h_

        //; write resulting hash
        mov   [OUTPUT_PTR + 0*4], a_
        mov   [OUTPUT_PTR + 1*4], b_
        mov   [OUTPUT_PTR + 2*4], c_
        mov   [OUTPUT_PTR + 3*4], d_
        mov   [OUTPUT_PTR + 4*4], e_
        mov   [OUTPUT_PTR + 5*4], f_
        mov   [OUTPUT_PTR + 6*4], g_
        mov   [OUTPUT_PTR + 7*4], h_

        add   OUTPUT_PTR, 32
        add   DATA_PTR, 64
        jmp   .Lsha256_avx_1_block_loop

.Lsha256_1_avx_epilog:

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

	add	rsp, stack_size

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
.size hashtree_sha256_avx_x1,.-hashtree_sha256_avx_x1
.section .note.GNU-stack,"",@progbits
#endif
#endif
