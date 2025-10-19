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

.LPSHUFFLE_BYTE_FLIP_MASK:
#ifdef __APPLE__
        .quad 0x0405060700010203
        .quad 0x0c0d0e0f08090a0b
#else
        .octa 0x0c0d0e0f08090a0b0405060700010203
#endif

.LDIGEST:
#ifdef __APPLE__
        .quad      0x510e527f9b05688c
        .quad      0x6a09e667bb67ae85
        .quad      0x1f83d9ab5be0cd19
        .quad      0x3c6ef372a54ff53a
#else
        .octa      0x6a09e667bb67ae85510e527f9b05688c
        .octa      0x3c6ef372a54ff53a1f83d9ab5be0cd19
#endif

.LPADDING:
        .long      0xc28a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5
        .long      0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
        .long      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3
        .long      0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf374
        .long      0x649b69c1, 0xf0fe4786, 0xfe1edc6, 0x240cf254
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

#ifdef __WIN64__
                    .equiv OUTPUT_PTR,rcx 	// 1st arg
                    .equiv DATA_PTR, rdx 	// 2nd arg
                    .equiv NUM_BLKS, r8	        // 3rd arg
                    .equiv SHA256PADDING, r9
		    #define _DIGEST 160
                    #define frame_size 248
#else
                    .equiv OUTPUT_PTR, rdi	// 1st arg
                    .equiv DATA_PTR, rsi	// 2nd arg
                    .equiv NUM_BLKS, rdx	// 3rd arg
                    .equiv SHA256PADDING, rcx
		    #define _DIGEST 0
		    #define frame_size 88
#endif

.equiv SHA256CONSTANTS,	rax

.equiv MSG,		xmm0
.equiv STATE0,		xmm1
.equiv STATE1,		xmm2
.equiv MSGTMP0,		xmm3
.equiv MSGTMP1,		xmm4
.equiv MSGTMP2,		xmm5
.equiv MSGTMP3,		xmm6
.equiv MSGTMP4,		xmm7
.equiv SHUF_MASK,	xmm8
.equiv ABEF_SAVE,	xmm9
.equiv CDGH_SAVE,	xmm10
.equiv STATE0b,         xmm9
.equiv STATE1b,         xmm10
.equiv MSGTMP0b,	xmm11
.equiv MSGTMP1b,	xmm12
.equiv MSGTMP2b,	xmm13
.equiv MSGTMP3b,	xmm14
.equiv MSGTMP4b,	xmm15

.text
#ifdef __APPLE__
.global _hashtree_sha256_shani_x2
#else
.global hashtree_sha256_shani_x2
#endif
#if !defined(__WIN64__) && !defined(__APPLE__)
.type   hashtree_sha256_shani_x2,%function
#endif
.align 16
#ifdef __APPLE__
_hashtree_sha256_shani_x2:
#else
hashtree_sha256_shani_x2:
#endif
	sub		rsp, frame_size
#ifdef __WIN64__
	movdqa		[rsp + 0*16], xmm6
	movdqa		[rsp + 1*16], xmm7
	movdqa		[rsp + 2*16], xmm8
	movdqa		[rsp + 3*16], xmm9
	movdqa		[rsp + 4*16], xmm10
	movdqa		[rsp + 5*16], xmm11
	movdqa		[rsp + 6*16], xmm12
	movdqa		[rsp + 7*16], xmm13
	movdqa		[rsp + 8*16], xmm14
	movdqa		[rsp + 9*16], xmm15
#endif

	movdqa		SHUF_MASK, [rip + .LPSHUFFLE_BYTE_FLIP_MASK]
	lea		SHA256CONSTANTS,[rip + .LK256]
	lea		SHA256PADDING,[rip + .LPADDING]

.Lsha256_shani_loop:
        cmp             NUM_BLKS, 2
	jl		.Lsha256_shani_x1

        movdqa          STATE0, [rip + .LDIGEST]
        movdqa          STATE1, [rip + .LDIGEST + 16]

        movdqa          STATE0b, [rip + .LDIGEST]
        movdqa          STATE1b, [rip +.LDIGEST + 16]

	# Rounds 0-3
	movdqu		MSG, [DATA_PTR + 0*16]
	pshufb		MSG, SHUF_MASK
	movdqa		MSGTMP0, MSG
		paddd		MSG, [SHA256CONSTANTS + 0*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	movdqu		MSG, [DATA_PTR + 4*16]
	pshufb		MSG, SHUF_MASK
	movdqa		MSGTMP0b, MSG
		paddd		MSG, [SHA256CONSTANTS + 0*16]
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b


	# Rounds 4-7
	movdqu		MSG, [DATA_PTR + 1*16]
	pshufb		MSG, SHUF_MASK
	movdqa		MSGTMP1, MSG
		paddd		MSG, [SHA256CONSTANTS + 1*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP0, MSGTMP1
	movdqu		MSG, [DATA_PTR + 5*16]
	pshufb		MSG, SHUF_MASK
	movdqa		MSGTMP1b, MSG
		paddd		MSG, [SHA256CONSTANTS + 1*16]
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b
	sha256msg1	MSGTMP0b, MSGTMP1b
	# Rounds 8-11
	movdqu		MSG, [DATA_PTR + 2*16]
	pshufb		MSG, SHUF_MASK
	movdqa		MSGTMP2, MSG
		paddd		MSG, [SHA256CONSTANTS + 2*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP1, MSGTMP2
	movdqu		MSG, [DATA_PTR + 6*16]
	pshufb		MSG, SHUF_MASK
	movdqa		MSGTMP2b, MSG
		paddd		MSG, [SHA256CONSTANTS + 2*16]
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b
	sha256msg1	MSGTMP1b, MSGTMP2b
	# Rounds 12-15
	movdqu		MSG, [DATA_PTR + 3*16]
	pshufb		MSG, SHUF_MASK
	movdqa		MSGTMP3, MSG
		paddd		MSG, [SHA256CONSTANTS + 3*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP3
	palignr		MSGTMP4, MSGTMP2, 4
	paddd		MSGTMP0, MSGTMP4
	sha256msg2	MSGTMP0, MSGTMP3
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP2, MSGTMP3
	movdqu		MSG, [DATA_PTR + 7*16]
	pshufb		MSG, SHUF_MASK
	movdqa		MSGTMP3b, MSG
		paddd		MSG, [SHA256CONSTANTS + 3*16]
		sha256rnds2	STATE1b, STATE0b
	movdqa		MSGTMP4b, MSGTMP3b
	palignr		MSGTMP4b, MSGTMP2b, 4
	paddd		MSGTMP0b, MSGTMP4b
	sha256msg2	MSGTMP0b, MSGTMP3b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b
	sha256msg1	MSGTMP2b, MSGTMP3b

	# Rounds 16-19
	movdqa		MSG, MSGTMP0
		paddd		MSG, [SHA256CONSTANTS + 4*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP0
	palignr		MSGTMP4, MSGTMP3, 4
	paddd		MSGTMP1, MSGTMP4
	sha256msg2	MSGTMP1, MSGTMP0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP3, MSGTMP0
	movdqa		MSG, MSGTMP0b
		paddd		MSG, [SHA256CONSTANTS + 4*16]
		sha256rnds2	STATE1b, STATE0b
	movdqa		MSGTMP4b, MSGTMP0b
	palignr		MSGTMP4b, MSGTMP3b, 4
	paddd		MSGTMP1b, MSGTMP4b
	sha256msg2	MSGTMP1b, MSGTMP0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b
	sha256msg1	MSGTMP3b, MSGTMP0b

	# Rounds 20-23
	movdqa		MSG, MSGTMP1
		paddd		MSG, [SHA256CONSTANTS + 5*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP1
	palignr		MSGTMP4, MSGTMP0, 4
	paddd		MSGTMP2, MSGTMP4
	sha256msg2	MSGTMP2, MSGTMP1
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP0, MSGTMP1
	movdqa		MSG, MSGTMP1b
		paddd		MSG, [SHA256CONSTANTS + 5*16]
		sha256rnds2	STATE1b, STATE0b
	movdqa		MSGTMP4b, MSGTMP1b
	palignr		MSGTMP4b, MSGTMP0b, 4
	paddd		MSGTMP2b, MSGTMP4b
	sha256msg2	MSGTMP2b, MSGTMP1b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b
	sha256msg1	MSGTMP0b, MSGTMP1b

	# Rounds 24-27
	movdqa		MSG, MSGTMP2
		paddd		MSG, [SHA256CONSTANTS + 6*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP2
	palignr		MSGTMP4, MSGTMP1, 4
	paddd		MSGTMP3, MSGTMP4
	sha256msg2	MSGTMP3, MSGTMP2
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP1, MSGTMP2

	movdqa		MSG, MSGTMP2b
		paddd		MSG, [SHA256CONSTANTS + 6*16]
		sha256rnds2	STATE1b, STATE0b
	movdqa		MSGTMP4b, MSGTMP2b
	palignr		MSGTMP4b, MSGTMP1b, 4
	paddd		MSGTMP3b, MSGTMP4b
	sha256msg2	MSGTMP3b, MSGTMP2b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b
	sha256msg1	MSGTMP1b, MSGTMP2b

	# Rounds 28-31
	movdqa		MSG, MSGTMP3
		paddd		MSG, [SHA256CONSTANTS + 7*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP3
	palignr		MSGTMP4, MSGTMP2, 4
	paddd		MSGTMP0, MSGTMP4
	sha256msg2	MSGTMP0, MSGTMP3
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP2, MSGTMP3
	movdqa		MSG, MSGTMP3b
		paddd		MSG, [SHA256CONSTANTS + 7*16]
		sha256rnds2	STATE1b, STATE0b
	movdqa		MSGTMP4b, MSGTMP3b
	palignr		MSGTMP4b, MSGTMP2b, 4
	paddd		MSGTMP0b, MSGTMP4b
	sha256msg2	MSGTMP0b, MSGTMP3b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b
	sha256msg1	MSGTMP2b, MSGTMP3b
	# Rounds 32-35
	movdqa		MSG, MSGTMP0
		paddd		MSG, [SHA256CONSTANTS + 8*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP0
	palignr		MSGTMP4, MSGTMP3, 4
	paddd		MSGTMP1, MSGTMP4
	sha256msg2	MSGTMP1, MSGTMP0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP3, MSGTMP0
	movdqa		MSG, MSGTMP0b
		paddd		MSG, [SHA256CONSTANTS + 8*16]
		sha256rnds2	STATE1b, STATE0b
	movdqa		MSGTMP4b, MSGTMP0b
	palignr		MSGTMP4b, MSGTMP3b, 4
	paddd		MSGTMP1b, MSGTMP4b
	sha256msg2	MSGTMP1b, MSGTMP0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b
	sha256msg1	MSGTMP3b, MSGTMP0b

	# Rounds 36-39
	movdqa		MSG, MSGTMP1
		paddd		MSG, [SHA256CONSTANTS + 9*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP1
	palignr		MSGTMP4, MSGTMP0, 4
	paddd		MSGTMP2, MSGTMP4
	sha256msg2	MSGTMP2, MSGTMP1
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP0, MSGTMP1
	movdqa		MSG, MSGTMP1b
		paddd		MSG, [SHA256CONSTANTS + 9*16]
		sha256rnds2	STATE1b, STATE0b
	movdqa		MSGTMP4b, MSGTMP1b
	palignr		MSGTMP4b, MSGTMP0b, 4
	paddd		MSGTMP2b, MSGTMP4b
	sha256msg2	MSGTMP2b, MSGTMP1b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b
	sha256msg1	MSGTMP0b, MSGTMP1b

	# Rounds 40-43
	movdqa		MSG, MSGTMP2
		paddd		MSG, [SHA256CONSTANTS + 10*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP2
	palignr		MSGTMP4, MSGTMP1, 4
	paddd		MSGTMP3, MSGTMP4
	sha256msg2	MSGTMP3, MSGTMP2
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP1, MSGTMP2
	movdqa		MSG, MSGTMP2b
		paddd		MSG, [SHA256CONSTANTS + 10*16]
		sha256rnds2	STATE1b, STATE0b
	movdqa		MSGTMP4b, MSGTMP2b
	palignr		MSGTMP4b, MSGTMP1b, 4
	paddd		MSGTMP3b, MSGTMP4b
	sha256msg2	MSGTMP3b, MSGTMP2b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b
	sha256msg1	MSGTMP1b, MSGTMP2b

	# Rounds 44-47
	movdqa		MSG, MSGTMP3
		paddd		MSG, [SHA256CONSTANTS + 11*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP3
	palignr		MSGTMP4, MSGTMP2, 4
	paddd		MSGTMP0, MSGTMP4
	sha256msg2	MSGTMP0, MSGTMP3
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP2, MSGTMP3
	movdqa		MSG, MSGTMP3b
		paddd		MSG, [SHA256CONSTANTS + 11*16]
		sha256rnds2	STATE1b, STATE0b
	movdqa		MSGTMP4b, MSGTMP3b
	palignr		MSGTMP4b, MSGTMP2b, 4
	paddd		MSGTMP0b, MSGTMP4b
	sha256msg2	MSGTMP0b, MSGTMP3b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b
	sha256msg1	MSGTMP2b, MSGTMP3b
       
	# Rounds 48-51
	movdqa		MSG, MSGTMP0
		paddd		MSG, [SHA256CONSTANTS + 12*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP0
	palignr		MSGTMP4, MSGTMP3, 4
	paddd		MSGTMP1, MSGTMP4
	sha256msg2	MSGTMP1, MSGTMP0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP3, MSGTMP0
	movdqa		MSG, MSGTMP0b
		paddd		MSG, [SHA256CONSTANTS + 12*16]
		sha256rnds2	STATE1b, STATE0b
	movdqa		MSGTMP4b, MSGTMP0b
	palignr		MSGTMP4b, MSGTMP3b, 4
	paddd		MSGTMP1b, MSGTMP4b
	sha256msg2	MSGTMP1b, MSGTMP0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b
	sha256msg1	MSGTMP3b, MSGTMP0b
        
 	# Rounds 52-55
	movdqa		MSG, MSGTMP1
		paddd		MSG, [SHA256CONSTANTS + 13*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP1
	palignr		MSGTMP4, MSGTMP0, 4
	paddd		MSGTMP2, MSGTMP4
	sha256msg2	MSGTMP2, MSGTMP1
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	movdqa		MSG, MSGTMP1b
		paddd		MSG, [SHA256CONSTANTS + 13*16]
		sha256rnds2	STATE1b, STATE0b
	movdqa		MSGTMP4b, MSGTMP1b
	palignr		MSGTMP4b, MSGTMP0b, 4
	paddd		MSGTMP2b, MSGTMP4b
	sha256msg2	MSGTMP2b, MSGTMP1b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b

	# Rounds 56-59
	movdqa		MSG, MSGTMP2
		paddd		MSG, [SHA256CONSTANTS + 14*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP2
	palignr		MSGTMP4, MSGTMP1, 4
	paddd		MSGTMP3, MSGTMP4
	sha256msg2	MSGTMP3, MSGTMP2
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	movdqa		MSG, MSGTMP2b
		paddd		MSG, [SHA256CONSTANTS + 14*16]
		sha256rnds2	STATE1b, STATE0b
	movdqa		MSGTMP4b, MSGTMP2b
	palignr		MSGTMP4b, MSGTMP1b, 4
	paddd		MSGTMP3b, MSGTMP4b
	sha256msg2	MSGTMP3b, MSGTMP2b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b


	# Rounds 60-63
	movdqa		MSG, MSGTMP3
		paddd		MSG, [SHA256CONSTANTS + 15*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	movdqa		MSG, MSGTMP3b
		paddd		MSG, [SHA256CONSTANTS + 15*16]
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0b, STATE1b

       
	paddd		STATE0, [rip + .LDIGEST]
	paddd		STATE1, [rip + .LDIGEST + 16]
	paddd           STATE0b, [rip + .LDIGEST]
	paddd		STATE1b, [rip + .LDIGEST + 16]

        # Rounds with PADDING
        
	# Save hash values for addition after rounds
	movdqa		[rsp + _DIGEST + 0*16], STATE0
	movdqa		[rsp + _DIGEST + 1*16], STATE1
	movdqa		[rsp + _DIGEST + 2*16], STATE0b
	movdqa		[rsp + _DIGEST + 3*16], STATE1b

	# Rounds 0-3
	movdqa		MSG, [SHA256PADDING + 0*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b

	# Rounds 4-7
	movdqa		MSG, [SHA256PADDING + 1*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b


	movdqa		MSG, [SHA256PADDING + 2*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b


	movdqa		MSG, [SHA256PADDING + 3*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b


	movdqa		MSG, [SHA256PADDING + 4*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b


	movdqa		MSG, [SHA256PADDING + 5*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b


	movdqa		MSG, [SHA256PADDING + 6*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b


	movdqa		MSG, [SHA256PADDING + 7*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b


	movdqa		MSG, [SHA256PADDING + 8*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b


	movdqa		MSG, [SHA256PADDING + 9*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b

	movdqa		MSG, [SHA256PADDING + 10*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b


	movdqa		MSG, [SHA256PADDING + 11*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b


	movdqa		MSG, [SHA256PADDING + 12*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b


	movdqa		MSG, [SHA256PADDING + 13*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b

	movdqa		MSG, [SHA256PADDING + 14*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b


	movdqa		MSG, [SHA256PADDING + 15*16]
		sha256rnds2	STATE1, STATE0
		sha256rnds2	STATE1b, STATE0b
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
		sha256rnds2	STATE0b, STATE1b

	paddd		STATE0, [rsp + _DIGEST + 0*16]
	paddd		STATE1, [rsp + _DIGEST + 1*16]
	paddd           STATE0b, [rsp + _DIGEST + 2*16]
	paddd		STATE1b, [rsp + _DIGEST + 3*16]


	# Write hash values back in the correct order
	pshufd		STATE0,  STATE0,  0x1B	// FEBA
	pshufd		STATE1,  STATE1,  0xB1	// DCHG
	pshufd		STATE0b,  STATE0b,  0x1B	// FEBA
	pshufd		STATE1b,  STATE1b,  0xB1	// DCHG
	movdqa		MSGTMP4, STATE0
	movdqa		MSGTMP4b, STATE0b
	pblendw		STATE0,  STATE1,  0xF0	// DCBA
	pblendw		STATE0b,  STATE1b,  0xF0	// DCBA
	palignr		STATE1,  MSGTMP4, 8	// HGFE
	palignr		STATE1b,  MSGTMP4b, 8	// HGFE

        pshufb          STATE0, SHUF_MASK
        pshufb          STATE0b, SHUF_MASK
        pshufb          STATE1, SHUF_MASK
        pshufb          STATE1b, SHUF_MASK


	movdqu		[OUTPUT_PTR + 0*16], STATE0
	movdqu		[OUTPUT_PTR + 1*16], STATE1
	movdqu		[OUTPUT_PTR + 2*16], STATE0b
	movdqu		[OUTPUT_PTR + 3*16], STATE1b

	# Increment data pointer and loop if more to process
	add		DATA_PTR, 128
        add             OUTPUT_PTR, 64
        
	sub		NUM_BLKS,2
        jmp             .Lsha256_shani_loop


.Lsha256_shani_x1:
        test            NUM_BLKS,NUM_BLKS
        jz              .Lsha256_shani_epilog

        movdqa          STATE0, [rip + .LDIGEST]
        movdqa          STATE1, [rip + .LDIGEST + 16]

	# Save hash values for addition after rounds
	movdqa		ABEF_SAVE, STATE0
	movdqa		CDGH_SAVE, STATE1

	# Rounds 0-3
	movdqu		MSG, [DATA_PTR + 0*16]
	pshufb		MSG, SHUF_MASK
	movdqa		MSGTMP0, MSG
		paddd		MSG, [SHA256CONSTANTS + 0*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 4-7
	movdqu		MSG, [DATA_PTR + 1*16]
	pshufb		MSG, SHUF_MASK
	movdqa		MSGTMP1, MSG
		paddd		MSG, [SHA256CONSTANTS + 1*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP0, MSGTMP1

	# Rounds 8-11
	movdqu		MSG, [DATA_PTR + 2*16]
	pshufb		MSG, SHUF_MASK
	movdqa		MSGTMP2, MSG
		paddd		MSG, [SHA256CONSTANTS + 2*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP1, MSGTMP2

	# Rounds 12-15
	movdqu		MSG, [DATA_PTR + 3*16]
	pshufb		MSG, SHUF_MASK
	movdqa		MSGTMP3, MSG
		paddd		MSG, [SHA256CONSTANTS + 3*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP3
	palignr		MSGTMP4, MSGTMP2, 4
	paddd		MSGTMP0, MSGTMP4
	sha256msg2	MSGTMP0, MSGTMP3
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP2, MSGTMP3

	# Rounds 16-19
	movdqa		MSG, MSGTMP0
		paddd		MSG, [SHA256CONSTANTS + 4*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP0
	palignr		MSGTMP4, MSGTMP3, 4
	paddd		MSGTMP1, MSGTMP4
	sha256msg2	MSGTMP1, MSGTMP0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP3, MSGTMP0

	# Rounds 20-23
	movdqa		MSG, MSGTMP1
		paddd		MSG, [SHA256CONSTANTS + 5*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP1
	palignr		MSGTMP4, MSGTMP0, 4
	paddd		MSGTMP2, MSGTMP4
	sha256msg2	MSGTMP2, MSGTMP1
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP0, MSGTMP1

	# Rounds 24-27
	movdqa		MSG, MSGTMP2
		paddd		MSG, [SHA256CONSTANTS + 6*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP2
	palignr		MSGTMP4, MSGTMP1, 4
	paddd		MSGTMP3, MSGTMP4
	sha256msg2	MSGTMP3, MSGTMP2
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP1, MSGTMP2

	# Rounds 28-31
	movdqa		MSG, MSGTMP3
		paddd		MSG, [SHA256CONSTANTS + 7*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP3
	palignr		MSGTMP4, MSGTMP2, 4
	paddd		MSGTMP0, MSGTMP4
	sha256msg2	MSGTMP0, MSGTMP3
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP2, MSGTMP3

	# Rounds 32-35
	movdqa		MSG, MSGTMP0
		paddd		MSG, [SHA256CONSTANTS + 8*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP0
	palignr		MSGTMP4, MSGTMP3, 4
	paddd		MSGTMP1, MSGTMP4
	sha256msg2	MSGTMP1, MSGTMP0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP3, MSGTMP0

	# Rounds 36-39
	movdqa		MSG, MSGTMP1
		paddd		MSG, [SHA256CONSTANTS + 9*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP1
	palignr		MSGTMP4, MSGTMP0, 4
	paddd		MSGTMP2, MSGTMP4
	sha256msg2	MSGTMP2, MSGTMP1
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP0, MSGTMP1

	# Rounds 40-43
	movdqa		MSG, MSGTMP2
		paddd		MSG, [SHA256CONSTANTS + 10*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP2
	palignr		MSGTMP4, MSGTMP1, 4
	paddd		MSGTMP3, MSGTMP4
	sha256msg2	MSGTMP3, MSGTMP2
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP1, MSGTMP2

	# Rounds 44-47
	movdqa		MSG, MSGTMP3
		paddd		MSG, [SHA256CONSTANTS + 11*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP3
	palignr		MSGTMP4, MSGTMP2, 4
	paddd		MSGTMP0, MSGTMP4
	sha256msg2	MSGTMP0, MSGTMP3
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP2, MSGTMP3

	# Rounds 48-51
	movdqa		MSG, MSGTMP0
		paddd		MSG, [SHA256CONSTANTS + 12*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP0
	palignr		MSGTMP4, MSGTMP3, 4
	paddd		MSGTMP1, MSGTMP4
	sha256msg2	MSGTMP1, MSGTMP0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1
	sha256msg1	MSGTMP3, MSGTMP0

	# Rounds 52-55
	movdqa		MSG, MSGTMP1
		paddd		MSG, [SHA256CONSTANTS + 13*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP1
	palignr		MSGTMP4, MSGTMP0, 4
	paddd		MSGTMP2, MSGTMP4
	sha256msg2	MSGTMP2, MSGTMP1
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 56-59
	movdqa		MSG, MSGTMP2
		paddd		MSG, [SHA256CONSTANTS + 14*16]
		sha256rnds2	STATE1, STATE0
	movdqa		MSGTMP4, MSGTMP2
	palignr		MSGTMP4, MSGTMP1, 4
	paddd		MSGTMP3, MSGTMP4
	sha256msg2	MSGTMP3, MSGTMP2
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 60-63
	movdqa		MSG, MSGTMP3
		paddd		MSG, [SHA256CONSTANTS + 15*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Add current hash values with previously saved
	paddd		STATE0, ABEF_SAVE
	paddd		STATE1, CDGH_SAVE

        # Rounds with PADDING
	# Save hash values for addition after rounds
	movdqa		ABEF_SAVE, STATE0
	movdqa		CDGH_SAVE, STATE1

	# Rounds 0-3
	movdqa		MSG, [SHA256PADDING + 0*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 4-7
	movdqa		MSG, [SHA256PADDING + 1*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 8-11
	movdqa		MSG, [SHA256PADDING + 2*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 12-15
	movdqa		MSG, [SHA256PADDING + 3*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 16-19
	movdqa		MSG, [SHA256PADDING + 4*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 20-23
	movdqa		MSG, [SHA256PADDING + 5*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 24-27
	movdqa		MSG, [SHA256PADDING + 6*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 28-31
	movdqa		MSG, [SHA256PADDING + 7*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 32-35
	movdqa		MSG, [SHA256PADDING + 8*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 36-39
	movdqa		MSG, [SHA256PADDING + 9*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 40-43
	movdqa		MSG, [SHA256PADDING + 10*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 44-47
	movdqa		MSG, [SHA256PADDING + 11*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 48-51
	movdqa		MSG, [SHA256PADDING + 12*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 52-55
	movdqa		MSG, [SHA256PADDING + 13*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 56-59
	movdqa		MSG, [SHA256PADDING + 14*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Rounds 60-63
	movdqa		MSG, [SHA256PADDING + 15*16]
		sha256rnds2	STATE1, STATE0
		pshufd 		MSG, MSG, 0x0E
		sha256rnds2	STATE0, STATE1

	# Add current hash values with previously saved
	paddd		STATE0, ABEF_SAVE
	paddd		STATE1, CDGH_SAVE

	# Write hash values back in the correct order
	pshufd		STATE0,  STATE0,  0x1B	// FEBA
	pshufd		STATE1,  STATE1,  0xB1	// DCHG
	movdqa		MSGTMP4, STATE0
	pblendw		STATE0,  STATE1,  0xF0	// DCBA
	palignr		STATE1,  MSGTMP4, 8	// HGFE

        pshufb          STATE0, SHUF_MASK
        pshufb          STATE1, SHUF_MASK

	movdqu		[OUTPUT_PTR + 0*16], STATE0
	movdqu		[OUTPUT_PTR + 1*16], STATE1

.Lsha256_shani_epilog:
#ifdef __WIN64__
	movdqa		xmm6,  [rsp + 0*16]
	movdqa		xmm7,  [rsp + 1*16]
	movdqa		xmm8,  [rsp + 2*16]
	movdqa		xmm9,  [rsp + 3*16]
	movdqa		xmm10, [rsp + 4*16]
	movdqa		xmm11, [rsp + 5*16]
	movdqa		xmm12, [rsp + 6*16]
	movdqa		xmm13, [rsp + 7*16]
	movdqa		xmm14, [rsp + 8*16]
	movdqa		xmm15, [rsp + 9*16]
#endif
	add		rsp, frame_size
	ret	
#ifdef __linux__ 
.size hashtree_sha256_shani_x2,.-hashtree_sha256_shani_x2
.section .note.GNU-stack,"",@progbits
#endif
#endif
