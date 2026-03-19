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

#ifdef __aarch64__
.text
.arch armv8-a
.altmacro 

output .req x0
input .req x1
count .req x2
last  .req x2

digest .req x19
k256 .req x20
padding .req x21

VR0 .req v0
VR1 .req v1
VR2 .req v2
VR3 .req v3
QR0 .req q0

VTMP0 .req v4
VTMP1 .req v5
VTMP2 .req v6
VTMP3 .req v7
VTMP4 .req v17
VTMP5 .req v18
VTMP6 .req v19
KV0 .req v20
KV1 .req v21
KV2 .req v22
KV3 .req v23
KQ0 .req q20
KQ1 .req q21
KQ2 .req q22
KQ3 .req q23

VZ .req v16

A_ .req w3
B_ .req w4
C_ .req w5
D_ .req w6
E_ .req w7
F_ .req w9
G_ .req w10
H_ .req w11

AX_ .req x3
BX_ .req x4
CX_ .req x5
DX_ .req x6
EX_ .req x7
FX_ .req x9
GX_ .req x10
HX_ .req x11


T1 .req w12
T2 .req w13
T3 .req w14
T4 .req w15
T5 .req w22

###################################################################################################
#
# the functions roundx_sched for x=1..4 schedule 4 words and perform 4 rounds at the time, interleaving
# the ASIMD instructions with the ALU ones for better use of the RISC pipeline
#
##################################################################################################
.macro round1_sched A, B, C, D, E, F, G, H, VV0, VV1, VV2, VV3
		    ext			VTMP0.16b, \VV2\().16b, \VV3\().16b, #4
					ror T1, \E, #6
					ldr T3, [sp]
					ror T2, \A, #2
					ror T4, \A, #13

		    ext			VTMP1.16b, \VV0\().16b, \VV1\().16b, #4	// (W1..W4)
					eor T2, T2, T4
					add \H, \H, T3
					ror T3, \E, #11

		    add			VTMP0.4s, VTMP0.4s, \VV0\().4s		// (W0 + W9..W3 + W12)
					eor T1, T1, T3	    
					ror T3, \E, #25
					ror T4, \A, #22
				
		    ushr		VTMP2.4s, VTMP1.4s, #7
					eor T1, T1, T3	    // Sigma_1
					eor T2, T2, T4	    // Sigma_0
					eor T3, \F, \G

		    shl			VTMP3.4s, VTMP1.4s, #(32-7)
					eor T4, \A, \C
					and T3, T3, \E
					and T4, T4, \B
					eor T3, T3, \G	    // CH
					
		    ushr		VTMP4.4s, VTMP1.4s, #18
					add T1, T1, T3
					and T3, \A, \C
					add \H, \H, T1
					
		    orr			VTMP3.16b, VTMP3.16b, VTMP2.16b		// Ror^7(W1..W4)
					eor T4, T4, T3	    // MAJ
					add \D, \D, \H
					add T2, T2, T4

		    ushr		VTMP2.4s, VTMP1.4s, #3
					add \H, \H, T2
.endm

.macro round2_sched A, B, C, D, E, F, G, H, VV3
					ldr T3, [sp, #4]
					ror T1, \E, #6
		    shl			VTMP1.4s, VTMP1.4s, #(32-18)
					ror T2, \A, #2
					ror T4, \A, #13
					add \H, \H, T3
		    eor			VTMP3.16b, VTMP3.16b, VTMP2.16b
					ror T3, \E, #11
					eor T2, T2, T4
					eor T1, T1, T3	    
		    eor			VTMP1.16b, VTMP4.16b, VTMP1.16b		// Ror^18(W1..W4)
					ror T3, \E, #25
					ror T4, \A, #22
					eor T1, T1, T3	    // Sigma_1
		    zip2		VTMP5.4s, \VV3\().4s, \VV3\().4s	// (W12, W12, W13, W13)
					eor T2, T2, T4	    // Sigma_0
					eor T3, \F, \G
					eor T4, \A, \C
		    eor			VTMP1.16b, VTMP3.16b, VTMP1.16b		// sigma_0(W1..W4)
					and T3, T3, \E
					and T4, T4, \B
					eor T3, T3, \G	    // CH
		    ushr		VTMP6.4s, VTMP5.4s, #10
					add T1, T1, T3
					and T3, \A, \C
					add \H, \H, T1
		    ushr		VTMP3.2d, VTMP5.2d, #19			// Ror^19(W12, x, W13, x)
					eor T4, T4, T3	    // MAJ
					add \D, \D, \H
					add T2, T2, T4
		    ushr		VTMP2.2d, VTMP5.2d, #17			// Ror^17(W12, x, W13, x)
					add \H, \H, T2
.endm

.macro round3_sched A, B, C, D, E, F, G, H
					ldr T3, [sp, #8]
					ror T1, \E, #6
		    eor			VTMP3.16b, VTMP3.16b, VTMP6.16b
					ror T2, \A, #2
					ror T4, \A, #13
					add \H, \H, T3
		    add			VTMP0.4s, VTMP0.4s, VTMP1.4s		// W0 + W9 + sigma_0
					ror T3, \E, #11
					eor T2, T2, T4
					eor T1, T1, T3	    
		    eor			VTMP1.16b, VTMP3.16b, VTMP2.16b		// sigma_1(W12, x, W13, x)
					ror T3, \E, #25
					ror T4, \A, #22
					eor T1, T1, T3	    // Sigma_1
		    xtn			VTMP1.2s, VTMP1.2d			// sigma_1(W12, W13, 0, 0)
					eor T2, T2, T4	    // Sigma_0
					eor T3, \F, \G
					eor T4, \A, \C
		    add			VTMP0.4s, VTMP0.4s, VTMP1.4s		// (W16, W17,..)
					and T3, T3, \E
					and T4, T4, \B
					eor T3, T3, \G	    // CH
		    zip1		VTMP2.4s, VTMP0.4s, VTMP0.4s		// (W16, W16, W17, W17)
					add T1, T1, T3
					and T3, \A, \C
					add \H, \H, T1
					eor T4, T4, T3	    // MAJ
					add \D, \D, \H
					add T2, T2, T4
		    ushr		VTMP1.4s, VTMP2.4s, #10
					add \H, \H, T2
.endm

.macro round4_sched A, B, C, D, E, F, G, H, VV0
					ldr T3, [sp, #12]
					ror T1, \E, #6
					ror T2, \A, #2
		    ushr		VTMP3.2d, VTMP2.2d, #19			// Ror^19(W16, x, W17, x)
					ror T4, \A, #13
					add \H, \H, T3
					ror T3, \E, #11
					eor T2, T2, T4
		    ushr		VTMP2.2d, VTMP2.2d, #17			// ROR^17(W16, x, W17, x)
					eor T1, T1, T3	    
					ror T3, \E, #25
					ror T4, \A, #22
					eor T1, T1, T3	    // Sigma_1
		    eor			VTMP1.16b, VTMP1.16b, VTMP3.16b
					eor T2, T2, T4	    // Sigma_0
					eor T3, \F, \G
					eor T4, \A, \C
		    eor			VTMP1.16b, VTMP1.16b, VTMP2.16b		// sigma_1(W16, x, W17, x)
					and T3, T3, \E
					and T4, T4, \B
					eor T3, T3, \G	    // CH
		    uzp1		VTMP1.4s, VZ.4s, VTMP1.4s
					add T1, T1, T3
					and T3, \A, \C
					add \H, \H, T1
					eor T4, T4, T3	    // MAJ
					add \D, \D, \H
					add T2, T2, T4
		    add			\VV0\().4s, VTMP1.4s, VTMP0.4s
					add \H, \H, T2
.endm


.macro four_rounds_sched A, B, C, D, E, F, G, H, VV0, VV1, VV2, VV3
		    round1_sched \A, \B, \C, \D, \E, \F, \G, \H, \VV0, \VV1, \VV2, \VV3
		    round2_sched \H, \A, \B, \C, \D, \E, \F, \G, \VV3
		    round3_sched \G, \H, \A, \B, \C, \D, \E, \F
		    round4_sched \F, \G, \H, \A, \B, \C, \D, \E, \VV0
.endm

###################################################################################
# one_round performs a one round transition of the working variables A..H
# it reads pre-scheduled words from ptr + offset. 
##################################################################################
.macro one_round A, B, C, D, E, F, G, H, ptr, offset
					ldr T3, [\ptr, \offset]
					ror T1, \E, #6
					ror T2, \A, #2
					ror T4, \A, #13
					add \H, \H, T3
					ror T3, \E, #11
					eor T2, T2, T4
					eor T1, T1, T3	    
					ror T3, \E, #25
					ror T4, \A, #22
					eor T1, T1, T3	    // Sigma_1
					eor T2, T2, T4	    // Sigma_0
					eor T3, \F, \G
					eor T4, \A, \C
					and T3, T3, \E
					and T4, T4, \B
					eor T3, T3, \G	    // CH
					add T1, T1, T3
					and T3, \A, \C
					add \H, \H, T1
					eor T4, T4, T3	    // MAJ
					add \D, \D, \H
					add T2, T2, T4
					add \H, \H, T2
.endm

##############################################################################
#
# four_rounds performs 4 transitions of the working variables A..H.
# it reads pre-scheduled words from ptr+offset
#
#############################################################################
.macro four_rounds A, B, C, D, E, F, G, H, ptr, offset
		    one_round \A, \B, \C, \D, \E, \F, \G, \H, \ptr, \offset
		    one_round \H, \A, \B, \C, \D, \E, \F, \G, \ptr, \offset + 4
		    one_round \G, \H, \A, \B, \C, \D, \E, \F, \ptr, \offset + 8
		    one_round \F, \G, \H, \A, \B, \C, \D, \E, \ptr, \offset + 12
.endm

########################################################################################################
#
#   void sha256_armv8_neon_x1( unsigned char *output, unsigned char *input, size_t count)
#
#   armv8-a implementation with Neon but no crypto extensions
#   as in the Cortex A-72 of a Raspberry-Pi 4.b 
#
#   It reads one block at a time, and schedules 4 words at the same time using ASIMD instructions
#   There are no bound checks, caller is responsible to check that memory up to output + 32*count 
#   is writable.
#
########################################################################################################

#ifdef __APPLE__
.global _hashtree_sha256_neon_x1
#else
.global hashtree_sha256_neon_x1
.type   hashtree_sha256_neon_x1,%function
#endif
.align 4
#ifdef __APPLE__
_hashtree_sha256_neon_x1:
#else
hashtree_sha256_neon_x1:
#endif
		    sub			sp, sp, #64
		    stp			digest,k256, [sp, #48]
		    
		    movi		VZ.4s, #0
                    stp                 padding, x22, [sp, #32]
#ifdef __APPLE__
		    adrp		digest, .LDIGEST@PAGE
		    add			digest, digest, .LDIGEST@PAGEOFF
		    adrp		padding, .LPADDING@PAGE
		    add			padding, padding, .LPADDING@PAGEOFF
#else
		    adrp		digest, .LDIGEST
		    add			digest, digest, #:lo12:.LDIGEST
		    adrp		padding, .LPADDING
		    add			padding, padding, #:lo12:.LPADDING
#endif
		    add			last, output, count, lsl #5

.Lhash_1_block_loop:
# load one block
                    cmp                 output, last
                    beq                 .Larmv8_neon_x1_finish
                    
		    ld1			{VR0.4s, VR1.4s, VR2.4s, VR3.4s}, [input], #64
#ifdef __APPLE__
		    adrp		k256, .LK256@PAGE
		    add 		k256, k256, .LK256@PAGEOFF
#else
		    adrp		k256, .LK256
		    add 		k256, k256, #:lo12:.LK256
#endif
# change endianness
		    rev32		VR0.16b, VR0.16b
		    rev32		VR1.16b, VR1.16b
		    rev32		VR2.16b, VR2.16b
		    rev32		VR3.16b, VR3.16b

# load initial digest
		    ldp			A_, B_, [digest]
		    ldp			C_, D_, [digest, #8]
		    ldp			E_, F_, [digest, #16]
		    ldp			G_, H_, [digest, #24]

.rept 3
		    ld1 		{KV0.4s, KV1.4s, KV2.4s, KV3.4s}, [k256], #64
		    add			KV0.4s, KV0.4s, VR0.4s
		    str			KQ0, [sp]
		    four_rounds_sched   A_, B_, C_, D_, E_, F_, G_, H_, VR0, VR1, VR2, VR3
		    add			KV1.4s, KV1.4s, VR1.4s
		    str			KQ1, [sp]
		    four_rounds_sched   E_, F_, G_, H_, A_, B_, C_, D_, VR1, VR2, VR3, VR0
		    add			KV2.4s, KV2.4s, VR2.4s
		    str			KQ2, [sp]
		    four_rounds_sched   A_, B_, C_, D_, E_, F_, G_, H_, VR2, VR3, VR0, VR1
		    add			KV3.4s, KV3.4s, VR3.4s
		    str			KQ3, [sp]
		    four_rounds_sched   E_, F_, G_, H_, A_, B_, C_, D_, VR3, VR0, VR1, VR2
.endr
.Lremaining_rounds:
		    ld1 		{KV0.4s, KV1.4s, KV2.4s, KV3.4s}, [k256], #64
		    add			KV0.4s, KV0.4s, VR0.4s
		    str			KQ0, [sp]
		    four_rounds		A_, B_, C_, D_, E_, F_, G_, H_, sp, #0
		    add			KV1.4s, KV1.4s, VR1.4s
		    str			KQ1, [sp]
		    four_rounds		E_, F_, G_, H_, A_, B_, C_, D_, sp, #0
		    add			KV2.4s, KV2.4s, VR2.4s
		    str			KQ2, [sp]
		    four_rounds		A_, B_, C_, D_, E_, F_, G_, H_, sp, #0
		    add			KV3.4s, KV3.4s, VR3.4s
		    str			KQ3, [sp]
		    four_rounds		E_, F_, G_, H_, A_, B_, C_, D_, sp, #0

.Lrounds_with_padding:
		    ldp			T1, T2, [digest]
		    ldp			T3, T4, [digest, #8]
		    add			A_, A_, T1
		    add			B_, B_, T2
		    add			C_, C_, T3
		    add			D_, D_, T4
		    ldp			T1, T2, [digest, #16]
		    stp			A_, B_, [sp]
		    stp			C_, D_, [sp, #8]
		    ldp			T3, T4, [digest, #24]
		    add			E_, E_, T1
		    add			F_, F_, T2
		    add			G_, G_, T3
		    stp			E_, F_, [sp, #16]
		    add			H_, H_, T4
		    stp			G_, H_, [sp, #24]

.irp i,0,1,2,3,4,5,6,7
		    four_rounds A_, B_, C_, D_, E_, F_, G_, H_, padding, \i * 32
		    four_rounds E_, F_, G_, H_, A_, B_, C_, D_, padding, \i * 32 + 16
.endr
		    
		    ldp			T1, T2, [sp]
		    ldp			T3, T4, [sp, #8]
		    add			A_, A_, T1
		    add			B_, B_, T2
		    rev32		AX_, AX_ 
		    rev32		BX_, BX_ 
		    add			C_, C_, T3
		    add			D_, D_, T4
		    stp			A_, B_, [output], #8
		    ldp			T1, T2, [sp, #16]
		    rev32		CX_, CX_
		    rev32		DX_, DX_
		    stp			C_, D_, [output], #8
		    ldp			T3, T4, [sp, #24]
		    add			E_, E_, T1
		    add			F_, F_, T2
		    rev32		EX_, EX_
		    rev32		FX_, FX_
		    add			G_, G_, T3
		    add			H_, H_, T4
		    rev32		GX_, GX_
		    rev32		HX_, HX_
		    stp			E_, F_, [output], #8
		    stp			G_, H_, [output], #8
		    
		    b                   .Lhash_1_block_loop

.Larmv8_neon_x1_finish:
		    ldp			digest,k256, [sp, #48]
                    ldp                 padding, x22, [sp, #32]
		    add			sp, sp, #64
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
