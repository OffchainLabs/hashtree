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

# Definitions

#ifdef __WIN64__
     #define arg1 	rcx
     #define arg2 	rdx
     #define arg3	r8
     #define arg4	r9
     #define arg5	r10
#else
     #define arg1 	rdi
     #define arg2	rsi
     #define arg3	rdx
     #define arg4	rcx
     #define arg5       r8
#endif

#define OUTPUT_PTR	arg1
#define DATA_PTR	arg2
#define COUNT		arg3
#define TBL		arg4
#define PADDING		arg5
#define DIGEST		r11

// Initial register assignments for A-H (used by parameterized macros)
#define INI_A zmm0
#define INI_B zmm1
#define INI_C zmm2
#define INI_D zmm3
#define INI_E zmm4
#define INI_F zmm5
#define INI_G zmm6
#define INI_H zmm7

// Aliases for non-macro code (at initial rotation state)
#define A INI_A
#define B INI_B
#define C INI_C
#define D INI_D
#define E INI_E
#define F INI_F
#define G INI_G
#define H INI_H

#define T1	zmm8
#define TMP0	zmm9
#define TMP1	zmm10
#define TMP2	zmm11
#define TMP3	zmm12
#define TMP4	zmm13
#define TMP5	zmm14
#define TMP6	zmm15

#define YW0	ymm16
#define YW1	ymm17
#define YW2	ymm18
#define YW3	ymm19
#define YW4	ymm20
#define YW5	ymm21
#define YW6	ymm22
#define YW7	ymm23
#define YW8	ymm24
#define YW9	ymm25
#define YW10	ymm26
#define YW11	ymm27
#define YW12	ymm28
#define YW13	ymm29
#define YW14	ymm30
#define YW15	ymm31

// Initial register assignments for W0-W15 (used by parameterized macros)
#define INI_W0  zmm16
#define INI_W1  zmm17
#define INI_W2  zmm18
#define INI_W3  zmm19
#define INI_W4  zmm20
#define INI_W5  zmm21
#define INI_W6  zmm22
#define INI_W7  zmm23
#define INI_W8  zmm24
#define INI_W9  zmm25
#define INI_W10 zmm26
#define INI_W11 zmm27
#define INI_W12 zmm28
#define INI_W13 zmm29
#define INI_W14 zmm30
#define INI_W15 zmm31

// Aliases for non-macro code (at initial rotation state)
#define W0  INI_W0
#define W1  INI_W1
#define W2  INI_W2
#define W3  INI_W3
#define W4  INI_W4
#define W5  INI_W5
#define W6  INI_W6
#define W7  INI_W7
#define W8  INI_W8
#define W9  INI_W9
#define W10 INI_W10
#define W11 INI_W11
#define W12 INI_W12
#define W13 INI_W13
#define W14 INI_W14
#define W15 INI_W15

# Macros

# Input
#
# r0 = {a15 a14 a13 a12 a11 a10 a09 a08 a07 a06 a05 a04 a03 a02 a01 a00}
# r1 = {b15 g14 g13 g12 g11 g10 g09 g08 g07 g06 g05 g04 g03 g02 g01 g00}
# r2 = {c15 c14 c13 c12 c11 c10 c09 c08 c07 c06 c05 c04 c03 c02 c01 c00}
# r3 = {d15 d14 d13 d12 d11 d10 d09 d08 d07 d06 d05 d04 d03 d02 d01 d00}
# r4 = {e15 e14 e13 e12 e11 e10 e09 e08 e07 e06 e05 e04 e03 e02 e01 e00}
# r5 = {f15 f14 f13 f12 f11 f10 f09 f08 f07 f06 f05 f04 f03 f02 f01 f00}
# r6 = {g15 g14 g13 g12 g11 g10 g09 g08 g07 g06 g05 g04 g03 g02 g01 g00}
# r7 = {h15 h14 h13 h12 h11 h10 h09 h08 h07 h06 h05 h04 h03 h02 h01 h00}
# 
# OUTPUT:
# 
# r0 = {h01 g01 f01 e01 d01 c01 b01 a01 h00 g00 f00 e00 d00 c00 b00 a00}
# r1 = {h03 g03 f03 e03 d03 c03 b03 a03 h00 g02 f02 e02 d02 c02 b02 a02}
# r2 = {h05 g05 f05 e05 d05 c05 b05 a05 h00 g00 f00 e00 d00 c00 b00 a04}
# r3 = {h07 g07 f07 e07 d07 c07 b07 a07 h00 g00 f00 e00 d00 c00 b00 a06}
# r4 = {h09 g09 f09 e09 d09 c09 b09 a09 h00 g00 f00 e00 d00 c00 b00 a08}
# r5 = {h11 g11 f11 e11 d11 c11 b11 a11 h10 g10 f10 e10 d10 c10 b10 a10}
# r6 = {h13 g13 f13 e13 d13 c13 b13 a13 h12 g12 f12 e12 d12 c12 b12 a12}
# r7 = {h15 g15 f15 e15 d15 c15 b15 a15 h14 g14 f14 e14 d14 c14 b14 a14}
#
# m0 and m1 come already loaded with .LPSHUFFLE_TRANSPOSE_MASK3 and
# .LPSHUFFLE_TRANSPOSE_MASK4
.macro TRANSPOSE_8x16_U32 r0, r1, r2, r3, r4, r5, r6, r7,\
			t0, t1, t2, t3, m0, m1

	# Permutations: 2 letters, 8 indices
	vmovdqa32	\t0, \m0
	vmovdqa32	\t1, \m0
	vpermi2d	\t0, \r0, \r4	// t0 = {e7 e5 a7 a5 e6 e4 a6 a4 e3 e1 a3 a1 e2 e0 a2 a0}
	vpermi2d	\t1, \r1, \r5   // t1 = {f7 f5 b7 b5 f6 f4 b6 b4 f3 f1 b3 b1 f2 f0 b2 b0}
	vmovdqa32	\t2, \m1
	vmovdqa32	\t3, \m1
	vpermi2d	\t2, \r0, \r4	// t2 = {e15 e13 a15 a13 e14 e12 a14 a12 e11 e9 a11 a9 e10 e8 a10 a8}
	vpermi2d	\t3, \r1, \r5   // t3 = {f15 f13 b15 b13 f14 f12 b14 b12 f11 f9 b11 b9 f10 f8 a10 a8}

	vmovdqa32	\r0, \m0
	vmovdqa32	\r1, \m0
	vpermi2d	\r0, \r2, \r6	// r0 = {g7 g5 c7 c5 g6 g4 c6 c4 g3 g1 c3 c1 g2 g0 c2 c0}
	vpermi2d	\r1, \r3, \r7   // r1 = {h7 h5 d7 d5 h6 h4 d6 d4 h3 h1 d3 d1 h2 h0 d2 d0}

	vmovdqa32	\r4, \m1
	vmovdqa32	\r5, \m1
	vpermi2d	\r4, \r2, \r6	// r4 = {g15 g13 c15 c13 g14 g12 c14 c12 g11 g9 c11 c9 g10 g8 c10 c8}
	vpermi2d	\r5, \r3, \r7   // r5 = {h15 h13 d15 d13 h14 h12 d14 d12 h11 h9 d11 d9 h10 h8 d10 d8}

	# Simple shuffles: 4 letters, 4 indices
	vshufps		\r6, \t0, \t1, 0x88	// r6 = {f5 b5 e5 a5 f4 b4 e4 a4 f1 b1 e1 a1 f0 b0 e0 a0}
	vshufps		\r7, \t0, \t1, 0xDD	// r7 = {f7 b7 e7 a7 f6 b6 e6 a6 f3 b3 e3 a3 f2 b2 e2 a2}
	vshufps		\t1, \t2, \t3, 0x88	// t1 = {f13 b13 e13 a13 f12 b12 e12 a12 f9 b9 e9 a9 f8 b8 e8 a8}
	vshufps		\t0, \t2, \t3, 0xDD	// t0 = {f15 b15 e15 a15 f14 b14 e14 a14 f11 b11 e11 a11 f10 b10 e10 a10}
	vshufps		\t2, \r4, \r5, 0x88	// t2 = {h13 d13 g13 c13 h12 d12 g12 c12 h9 d9 g9 c9 h8 d8 g8 c8}
	vshufps		\t3, \r4, \r5, 0xDD	// t3 = {h15 d15 g15 c15 h14 d14 g14 c14 h11 d11 g11 c11 h10 d10 g10 c10}
	vshufps		\r4, \r0, \r1, 0x88	// r4 = {h5 d5 g5 c5 h4 d4 g4 c4 h1 d1 g1 c1 h0 d0 g0 c0}
	vshufps		\r5, \r0, \r1, 0xDD	// r5 = {h7 d7 g7 c7 h6 d6 g6 c6 h3 d3 g3 c3 h2 d2 g2 c2}

	# Final permutations: 2 letters, 8 indices
	vmovdqa32	\r0, \m0
	vmovdqa32	\r1, \m0 
	vpermi2d	\r0, \r6, \r4	// r0 = {h1 g1 f1 e1 d1 c1 b1 a1 h0 g0 f0 e0 d0 c0 b0 a0}
	vpermi2d	\r1, \r7, \r5   // r1 = {h3 g3 f3 e3 d3 c3 b3 a3 h2 g2 f2 e2 d2 c2 b2 a2}
	vmovdqa32	\r2, \m1
	vmovdqa32	\r3, \m1 
	vpermi2d	\r2, \r6, \r4	// r2 = {h5 g5 f5 e5 d5 c5 b5 a5 h4 g4 f4 e4 d4 c4 b4 a4}
	vpermi2d	\r3, \r7, \r5   // r3 = {h7 g7 f7 e7 d7 c7 b7 a7 h6 g6 f6 e6 d6 c6 b6 a6}


	vmovdqa32	\r4, \m0
	vmovdqa32	\r5, \m0 
	vpermi2d	\r4, \t1, \t2	// r4 = {h9 g9 f9 e9 d9 c9 b9 a9 h8 g8 f8 e8 d8 c8 b8 a8}
	vpermi2d	\r5, \t0, \t3   // r5 = {h11 g11 f11 e11 d11 c11 b11 a11 h10 g10 f10 e10 d10 c10 b10 a10}
	vmovdqa32	\r6, \m1
	vmovdqa32	\r7, \m1 
	vpermi2d	\r6, \t1, \t2	// r6 = {h13 g13 f13 e13 d13 c13 b13 a13 h12 g12 f12 e12 d12 c12 b12 a12}
	vpermi2d	\r7, \t0, \t3   // r7 = {h15 g15 f15 e15 d15 c15 b15 a15 h14 g14 f14 e14 d14 c14 b14 a14}
.endm	

.macro TRANSPOSE16_U32_PRELOADED r0, r1, r2, r3, r4, r5, r6, r7, r8,\
				r9, r10, r11, r12, r13, r14, r15,\
				t0, t1, m0, m1
	# process first 4 rows (r0..r3)
	vshufps	\t0, \r0, \r1, 0x44	// t0 = {j5 j4 i5 i4  j1 j0 i1 i0  b5 b4 a5 a4  b1 b0 a1 a0}
	vshufps	\r0, \r0, \r1, 0xEE	// r0 = {j7 j6 i7 i6  j3 j2 i3 i2  b7 b6 a7 a6  b3 b2 a3 a2}
	vshufps	\t1, \r2, \r3, 0x44	// t1 = {l5 l4 k5 k4  l1 l0 k1 k0  d5 d4 c5 c4  d1 d0 c1 c0}
	vshufps	\r2, \r2, \r3, 0xEE	// r2 = {l7 l6 k7 k6  l3 l2 k3 k2  d7 d6 c7 c6  d3 d2 c3 c2}

	vshufps	\r3, \t0, \t1, 0xDD	// r3 = {l5 k5 j5 i5  l1 k1 j1 i1  d5 c5 b5 a5  d1 c1 b1 a1}
	vshufps	\r1, \r0, \r2, 0x88	// r1 = {l6 k6 j6 i6  l2 k2 j2 i2  d6 c6 b6 a6  d2 c2 b2 a2}
	vshufps	\r0, \r0, \r2, 0xDD	// r0 = {l7 k7 j7 i7  l3 k3 j3 i3  d7 c7 b7 a7  d3 c3 b3 a3}
	vshufps	\t0, \t0, \t1, 0x88	// t0 = {l4 k4 j4 i4  l0 k0 j0 i0  d4 c4 b4 a4  d0 c0 b0 a0}

	# Load permute masks
	vmovdqa64	\m0, [rip + .LPSHUFFLE_TRANSPOSE_MASK1]
	vmovdqa64	\m1, [rip + .LPSHUFFLE_TRANSPOSE_MASK2]

	# process second 4 rows (r4..r7)
	vshufps	\r2, \r4, \r5, 0x44	// r2 = {n5 n4 m5 m4  n1 n0 m1 m0  f5 f4 e5 e4  f1 f0 e1 e0}
	vshufps	\r4, \r4, \r5, 0xEE	// r4 = {n7 n6 m7 m6  n3 n2 m3 m2  f7 f6 e7 e6  f3 f2 e3 e2}
	vshufps \t1, \r6, \r7, 0x44	// t1 = {p5 p4 o5 o4  p1 p0 o1 o0  h5 h4 g5 g4  h1 h0 g1 g0}
	vshufps	\r6, \r6, \r7, 0xEE	// r6 = {p7 p6 o7 o6  p3 p2 o3 o2  h7 h6 g7 g6  h3 h2 g3 g2}

	vshufps	\r7, \r2, \t1, 0xDD	// r7 = {p5 o5 n5 m5  p1 o1 n1 m1  h5 g5 f5 e5   h1 g1 f1 e1}
	vshufps	\r5, \r4, \r6, 0x88	// r5 = {p6 o6 n6 m6  p2 o2 n2 m2  h6 g6 f6 e6   h2 g2 f2 e2}
	vshufps	\r4, \r4, \r6, 0xDD	// r4 = {p7 o7 n7 m7  p3 o3 n3 m3  h7 g7 f7 e7   h3 g3 f3 e3}
	vshufps	\r2, \r2, \t1, 0x88	// r2 = {p4 o4 n4 m4  p0 o0 n0 m0  h4 g4 f4 e4   h0 g0 f0 e0}

	# process third 4 rows (r8..r11)
	vshufps	\r6, \r8, \r9,    0x44	// r6  = {j13 j12 i13 i12  j9  j8  i9  i8   b13 b12 a13 a12  b9  b8  a9  a8 }
	vshufps	\r8, \r8, \r9,    0xEE	// r8  = {j15 j14 i15 i14  j11 j10 i11 i10  b15 b14 a15 a14  b11 b10 a11 a10}
	vshufps	\t1, \r10, \r11,  0x44	// t1  = {l13 l12 k13 k12  l9  l8  k9  k8   d13 d12 c13 c12  d9  d8  c9  c8 }
	vshufps	\r10, \r10, \r11, 0xEE	// r10 = {l15 l14 k15 k14  l11 l10 k11 k10  d15 d14 c15 c14  d11 d10 c11 c10}

	vshufps	\r11, \r6, \t1, 0xDD		// r11 = {l13 k13 j13 i13  l9  k9  j9  i9   d13 c13 b13 a13  d9  c9  b9  a9 }
	vshufps	\r9, \r8, \r10, 0x88		// r9  = {l14 k14 j14 i14  l10 k10 j10 i10  d14 c14 b14 a14  d10 c10 b10 a10}
	vshufps	\r8, \r8, \r10, 0xDD		// r8  = {l15 k15 j15 i15  l11 k11 j11 i11  d15 c15 b15 a15  d11 c11 b11 a11}
	vshufps	\r6, \r6, \t1,  0x88		// r6  = {l12 k12 j12 i12  l8  k8  j8  i8   d12 c12 b12 a12  d8  c8  b8  a8 }

	# process fourth 4 rows (r12..r15)
	vshufps	\r10, \r12, \r13, 0x44	// r10 = {n13 n12 m13 m12  n9  n8  m9  m8   f13 f12 e13 e12  f9  f8  e9  e8 }
	vshufps	\r12, \r12, \r13, 0xEE	// r12 = {n15 n14 m15 m14  n11 n10 m11 m10  f15 f14 e15 e14  f11 f10 e11 e10}
	vshufps	\t1, \r14, \r15,  0x44	// t1  = {p13 p12 o13 o12  p9  p8  o9  o8   h13 h12 g13 g12  h9  h8  g9  g8 }
	vshufps	\r14, \r14, \r15, 0xEE	// r14 = {p15 p14 o15 o14  p11 p10 o11 o10  h15 h14 g15 g14  h11 h10 g11 g10}

	vshufps	\r15, \r10, \t1,  0xDD	// r15 = {p13 o13 n13 m13  p9  o9  n9  m9   h13 g13 f13 e13  h9  g9  f9  e9 }
	vshufps	\r13, \r12, \r14, 0x88	// r13 = {p14 o14 n14 m14  p10 o10 n10 m10  h14 g14 f14 e14  h10 g10 f10 e10}
	vshufps	\r12, \r12, \r14, 0xDD	// r12 = {p15 o15 n15 m15  p11 o11 n11 m11  h15 g15 f15 e15  h11 g11 f11 e11}
	vshufps	\r10, \r10, \t1,  0x88	// r10 = {p12 o12 n12 m12  p8  o8  n8  m8   h12 g12 f12 e12  h8  g8  f8  e8 }

	# perform final shuffles on bottom half, producing r8-r15
	vmovdqu32 \t1, \m0
	vpermi2q  \t1, \r9, \r13		// t1 =  {p10 o10 n10 m10  l10 k10 j10 i10  h10 g10 f10 e10  d10 c10 b10 a10}
	vmovdqu32 \r14, \m1
	vpermi2q  \r14, \r9, \r13		// r14 = {p14 o14 n14 m14  l14 k14 j14 i14  h14 g14 f14 e14  d14 c14 b14 a14}

	vmovdqu32 \r9, \m0
	vpermi2q  \r9, \r11, \r15		// r9  = {p9  o9  n9  m9   l9  k9  j9  i9   h9  g9  f9  e9   d9  c9  b9  a9}
	vmovdqu32 \r13, \m1
	vpermi2q  \r13, \r11, \r15		// r13 = {p13 o13 n13 m13  l13 k13 j13 i13  h13 g13 f13 e13  d13 c13 b13 a13}

	vmovdqu32 \r11, \m0
	vpermi2q  \r11, \r8, \r12		// r11 = {p11 o11 n11 m11  l11 k11 j11 i11  h11 g11 f11 e11  d11 c11 b11 a11}
	vmovdqu32 \r15, \m1
	vpermi2q  \r15, \r8, \r12		// r15 = {p15 o15 n15 m15  l15 k15 j15 i15  h15 g15 f15 e15  d15 c15 b15 a15}

	vmovdqu32 \r8, \m0
	vpermi2q  \r8, \r6, \r10		// r8  = {p8  o8  n8  m8   l8  k8  j8  i8   h8  g8  f8  e8    d8  c8  b8  a8}
	vmovdqu32 \r12, \m1
	vpermi2q  \r12, \r6, \r10		// r12 = {p12 o12 n12 m12  l12 k12 j12 i12  h12 g12 f12 e12   d12 c12 b12 a12}

	vmovdqu32 \r10, \t1			// r10 = {p10 o10 n10 m10  l10 k10 j10 i10  h10 g10 f10 e10  d10 c10 b10 a10}

	# perform final shuffles on top half, producing r0-r7
	vmovdqu32 \t1, \m0
	vpermi2q  \t1, \r1, \r5		// t1 = {p2 o2 n2 m2  l2 k2 j2 i2  h2 g2 f2 e2  d2 c2 b2 a2}
	vmovdqu32 \r6, \m1
	vpermi2q  \r6, \r1, \r5		// r6 = {p6 o6 n6 m6  l6 k6 j6 i6  h6 g6 f6 e6  d6 c6 b6 a6}

	vmovdqu32 \r1, \m0
	vpermi2q  \r1, \r3, \r7		// r1 = {p1 o1 n1 m1  l1 k1 j1 i1  h1 g1 f1 e1  d1 c1 b1 a1}
	vmovdqu32 \r5, \m1
	vpermi2q  \r5, \r3, \r7		// r5 = {p5 o5 n5 m5  l5 k5 j5 i5  h5 g5 f5 e5  d5 c5 b5 a5}

	vmovdqu32 \r3, \m0
	vpermi2q  \r3, \r0, \r4		// r3 = {p3 o3 n3 m3  l3 k3 j3 i3  h3 g3 f3 e3  d3 c3 b3 a3}
	vmovdqu32 \r7, \m1
	vpermi2q  \r7, \r0, \r4		// r7 = {p7 o7 n7 m7  l7 k7 j7 i7  h7 g7 f7 e7  d7 c7 b7 a7}

	vmovdqu32 \r0, \m0
	vpermi2q  \r0, \t0, \r2		// r0 = {p0 o0 n0 m0  l0 k0 j0 i0  h0 g0 f0 e0  d0 c0 b0 a0}
	vmovdqu32 \r4, \m1
	vpermi2q  \r4,  \t0, \r2		// r4 = {p4 o4 n4 m4  l4 k4 j4 i4  h4 g4 f4 e4  d4 c4 b4 a4}

	vmovdqu32 \r2, \t1			// r2 = {p2 o2 n2 m2  l2 k2 j2 i2  h2 g2 f2 e2  d2 c2 b2 a2}
.endm

// ROTATE_ARGS and ROTATE_ZMMS removed - using parameterized macros with explicit registers instead

// Parameterized PROCESS_LOOP with explicit registers (no rotation)
.macro PROCESS_LOOP_P WT, ra, rb, rc, rd, re, rf, rg, rh, is_padding
.if \is_padding - 1
	vpaddd		T1, \rh, TMP3		// T1 = H + Kt
.endif
	vmovdqa32	TMP0, \re
	vprord		TMP1, \re, 6 		// ROR_6(E)
	vprord		TMP2, \re, 11 		// ROR_11(E)
	vprord		TMP3, \re, 25 		// ROR_25(E)
	vpternlogd	TMP0, \rf, \rg, 0xCA	// TMP0 = CH(E,F,G)
.if \is_padding - 1
	vpaddd		T1, T1, \WT		// T1 = T1 + Wt
.else
	vpaddd		T1, \rh, \WT		// T1 = H + Wt + Kt
.endif
	vpternlogd	TMP1, TMP2, TMP3, 0x96	// TMP1 = SIGMA1(E)
	vpaddd		T1, T1, TMP0		// T1 = T1 + CH(E,F,G)
	vpaddd		T1, T1, TMP1		// T1 = T1 + SIGMA1(E)
	vpaddd		\rd, \rd, T1		// D = D + T1

	vprord		\rh, \ra, 2 		// ROR_2(A)
	vprord		TMP2, \ra, 13 		// ROR_13(A)
	vprord		TMP3, \ra, 22 		// ROR_22(A)
	vmovdqa32	TMP0, \ra
	vpternlogd	TMP0, \rb, \rc, 0xE8	// TMP0 = MAJ(A,B,C)
	vpternlogd	\rh, TMP2, TMP3, 0x96	// H(T2) = SIGMA0(A)
	vpaddd		\rh, \rh, TMP0		// H(T2) = SIGMA0(A) + MAJ(A,B,C)
	vpaddd		\rh, \rh, T1		// H(A) = H(T2) + T1
.endm

.macro MSG_SCHED_ROUND_16_63 WT, WTp1, WTp9, WTp14
	vprord		TMP4, \WTp14, 17 	// ROR_17(Wt-2)
	vprord		TMP5, \WTp14, 19 	// ROR_19(Wt-2)
	vpsrld		TMP6, \WTp14, 10 	// SHR_10(Wt-2)
	vpternlogd	TMP4, TMP5, TMP6, 0x96	// TMP4 = sigma1(Wt-2)

	vpaddd		\WT, \WT, TMP4	// Wt = Wt-16 + sigma1(Wt-2)
	vpaddd		\WT, \WT, \WTp9	// Wt = Wt-16 + sigma1(Wt-2) + Wt-7

	vprord		TMP4, \WTp1, 7 	// ROR_7(Wt-15)
	vprord		TMP5, \WTp1, 18 	// ROR_18(Wt-15)
	vpsrld		TMP6, \WTp1, 3 	// SHR_3(Wt-15)
	vpternlogd	TMP4, TMP5, TMP6, 0x96	// TMP4 = sigma0(Wt-15)

	vpaddd		\WT, \WT, TMP4	// Wt = Wt-16 + sigma1(Wt-2) +
						//      Wt-7 + sigma0(Wt-15) +
.endm

.section .rodata
.align 64

.LK256_16:
	.quad	0x428a2f98428a2f98, 0x428a2f98428a2f98
	.quad	0x428a2f98428a2f98, 0x428a2f98428a2f98
	.quad	0x428a2f98428a2f98, 0x428a2f98428a2f98
	.quad	0x428a2f98428a2f98, 0x428a2f98428a2f98
	.quad	0x7137449171374491, 0x7137449171374491
	.quad	0x7137449171374491, 0x7137449171374491
	.quad	0x7137449171374491, 0x7137449171374491
	.quad	0x7137449171374491, 0x7137449171374491
	.quad	0xb5c0fbcfb5c0fbcf, 0xb5c0fbcfb5c0fbcf
	.quad	0xb5c0fbcfb5c0fbcf, 0xb5c0fbcfb5c0fbcf
	.quad	0xb5c0fbcfb5c0fbcf, 0xb5c0fbcfb5c0fbcf
	.quad	0xb5c0fbcfb5c0fbcf, 0xb5c0fbcfb5c0fbcf
	.quad	0xe9b5dba5e9b5dba5, 0xe9b5dba5e9b5dba5
	.quad	0xe9b5dba5e9b5dba5, 0xe9b5dba5e9b5dba5
	.quad	0xe9b5dba5e9b5dba5, 0xe9b5dba5e9b5dba5
	.quad	0xe9b5dba5e9b5dba5, 0xe9b5dba5e9b5dba5
	.quad	0x3956c25b3956c25b, 0x3956c25b3956c25b
	.quad	0x3956c25b3956c25b, 0x3956c25b3956c25b
	.quad	0x3956c25b3956c25b, 0x3956c25b3956c25b
	.quad	0x3956c25b3956c25b, 0x3956c25b3956c25b
	.quad	0x59f111f159f111f1, 0x59f111f159f111f1
	.quad	0x59f111f159f111f1, 0x59f111f159f111f1
	.quad	0x59f111f159f111f1, 0x59f111f159f111f1
	.quad	0x59f111f159f111f1, 0x59f111f159f111f1
	.quad	0x923f82a4923f82a4, 0x923f82a4923f82a4
	.quad	0x923f82a4923f82a4, 0x923f82a4923f82a4
	.quad	0x923f82a4923f82a4, 0x923f82a4923f82a4
	.quad	0x923f82a4923f82a4, 0x923f82a4923f82a4
	.quad	0xab1c5ed5ab1c5ed5, 0xab1c5ed5ab1c5ed5
	.quad	0xab1c5ed5ab1c5ed5, 0xab1c5ed5ab1c5ed5
	.quad	0xab1c5ed5ab1c5ed5, 0xab1c5ed5ab1c5ed5
	.quad	0xab1c5ed5ab1c5ed5, 0xab1c5ed5ab1c5ed5
	.quad	0xd807aa98d807aa98, 0xd807aa98d807aa98
	.quad	0xd807aa98d807aa98, 0xd807aa98d807aa98
	.quad	0xd807aa98d807aa98, 0xd807aa98d807aa98
	.quad	0xd807aa98d807aa98, 0xd807aa98d807aa98
	.quad	0x12835b0112835b01, 0x12835b0112835b01
	.quad	0x12835b0112835b01, 0x12835b0112835b01
	.quad	0x12835b0112835b01, 0x12835b0112835b01
	.quad	0x12835b0112835b01, 0x12835b0112835b01
	.quad	0x243185be243185be, 0x243185be243185be
	.quad	0x243185be243185be, 0x243185be243185be
	.quad	0x243185be243185be, 0x243185be243185be
	.quad	0x243185be243185be, 0x243185be243185be
	.quad	0x550c7dc3550c7dc3, 0x550c7dc3550c7dc3
	.quad	0x550c7dc3550c7dc3, 0x550c7dc3550c7dc3
	.quad	0x550c7dc3550c7dc3, 0x550c7dc3550c7dc3
	.quad	0x550c7dc3550c7dc3, 0x550c7dc3550c7dc3
	.quad	0x72be5d7472be5d74, 0x72be5d7472be5d74
	.quad	0x72be5d7472be5d74, 0x72be5d7472be5d74
	.quad	0x72be5d7472be5d74, 0x72be5d7472be5d74
	.quad	0x72be5d7472be5d74, 0x72be5d7472be5d74
	.quad	0x80deb1fe80deb1fe, 0x80deb1fe80deb1fe
	.quad	0x80deb1fe80deb1fe, 0x80deb1fe80deb1fe
	.quad	0x80deb1fe80deb1fe, 0x80deb1fe80deb1fe
	.quad	0x80deb1fe80deb1fe, 0x80deb1fe80deb1fe
	.quad	0x9bdc06a79bdc06a7, 0x9bdc06a79bdc06a7
	.quad	0x9bdc06a79bdc06a7, 0x9bdc06a79bdc06a7
	.quad	0x9bdc06a79bdc06a7, 0x9bdc06a79bdc06a7
	.quad	0x9bdc06a79bdc06a7, 0x9bdc06a79bdc06a7
	.quad	0xc19bf174c19bf174, 0xc19bf174c19bf174
	.quad	0xc19bf174c19bf174, 0xc19bf174c19bf174
	.quad	0xc19bf174c19bf174, 0xc19bf174c19bf174
	.quad	0xc19bf174c19bf174, 0xc19bf174c19bf174
	.quad	0xe49b69c1e49b69c1, 0xe49b69c1e49b69c1
	.quad	0xe49b69c1e49b69c1, 0xe49b69c1e49b69c1
	.quad	0xe49b69c1e49b69c1, 0xe49b69c1e49b69c1
	.quad	0xe49b69c1e49b69c1, 0xe49b69c1e49b69c1
	.quad	0xefbe4786efbe4786, 0xefbe4786efbe4786
	.quad	0xefbe4786efbe4786, 0xefbe4786efbe4786
	.quad	0xefbe4786efbe4786, 0xefbe4786efbe4786
	.quad	0xefbe4786efbe4786, 0xefbe4786efbe4786
	.quad	0x0fc19dc60fc19dc6, 0x0fc19dc60fc19dc6
	.quad	0x0fc19dc60fc19dc6, 0x0fc19dc60fc19dc6
	.quad	0x0fc19dc60fc19dc6, 0x0fc19dc60fc19dc6
	.quad	0x0fc19dc60fc19dc6, 0x0fc19dc60fc19dc6
	.quad	0x240ca1cc240ca1cc, 0x240ca1cc240ca1cc
	.quad	0x240ca1cc240ca1cc, 0x240ca1cc240ca1cc
	.quad	0x240ca1cc240ca1cc, 0x240ca1cc240ca1cc
	.quad	0x240ca1cc240ca1cc, 0x240ca1cc240ca1cc
	.quad	0x2de92c6f2de92c6f, 0x2de92c6f2de92c6f
	.quad	0x2de92c6f2de92c6f, 0x2de92c6f2de92c6f
	.quad	0x2de92c6f2de92c6f, 0x2de92c6f2de92c6f
	.quad	0x2de92c6f2de92c6f, 0x2de92c6f2de92c6f
	.quad	0x4a7484aa4a7484aa, 0x4a7484aa4a7484aa
	.quad	0x4a7484aa4a7484aa, 0x4a7484aa4a7484aa
	.quad	0x4a7484aa4a7484aa, 0x4a7484aa4a7484aa
	.quad	0x4a7484aa4a7484aa, 0x4a7484aa4a7484aa
	.quad	0x5cb0a9dc5cb0a9dc, 0x5cb0a9dc5cb0a9dc
	.quad	0x5cb0a9dc5cb0a9dc, 0x5cb0a9dc5cb0a9dc
	.quad	0x5cb0a9dc5cb0a9dc, 0x5cb0a9dc5cb0a9dc
	.quad	0x5cb0a9dc5cb0a9dc, 0x5cb0a9dc5cb0a9dc
	.quad	0x76f988da76f988da, 0x76f988da76f988da
	.quad	0x76f988da76f988da, 0x76f988da76f988da
	.quad	0x76f988da76f988da, 0x76f988da76f988da
	.quad	0x76f988da76f988da, 0x76f988da76f988da
	.quad	0x983e5152983e5152, 0x983e5152983e5152
	.quad	0x983e5152983e5152, 0x983e5152983e5152
	.quad	0x983e5152983e5152, 0x983e5152983e5152
	.quad	0x983e5152983e5152, 0x983e5152983e5152
	.quad	0xa831c66da831c66d, 0xa831c66da831c66d
	.quad	0xa831c66da831c66d, 0xa831c66da831c66d
	.quad	0xa831c66da831c66d, 0xa831c66da831c66d
	.quad	0xa831c66da831c66d, 0xa831c66da831c66d
	.quad	0xb00327c8b00327c8, 0xb00327c8b00327c8
	.quad	0xb00327c8b00327c8, 0xb00327c8b00327c8
	.quad	0xb00327c8b00327c8, 0xb00327c8b00327c8
	.quad	0xb00327c8b00327c8, 0xb00327c8b00327c8
	.quad	0xbf597fc7bf597fc7, 0xbf597fc7bf597fc7
	.quad	0xbf597fc7bf597fc7, 0xbf597fc7bf597fc7
	.quad	0xbf597fc7bf597fc7, 0xbf597fc7bf597fc7
	.quad	0xbf597fc7bf597fc7, 0xbf597fc7bf597fc7
	.quad	0xc6e00bf3c6e00bf3, 0xc6e00bf3c6e00bf3
	.quad	0xc6e00bf3c6e00bf3, 0xc6e00bf3c6e00bf3
	.quad	0xc6e00bf3c6e00bf3, 0xc6e00bf3c6e00bf3
	.quad	0xc6e00bf3c6e00bf3, 0xc6e00bf3c6e00bf3
	.quad	0xd5a79147d5a79147, 0xd5a79147d5a79147
	.quad	0xd5a79147d5a79147, 0xd5a79147d5a79147
	.quad	0xd5a79147d5a79147, 0xd5a79147d5a79147
	.quad	0xd5a79147d5a79147, 0xd5a79147d5a79147
	.quad	0x06ca635106ca6351, 0x06ca635106ca6351
	.quad	0x06ca635106ca6351, 0x06ca635106ca6351
	.quad	0x06ca635106ca6351, 0x06ca635106ca6351
	.quad	0x06ca635106ca6351, 0x06ca635106ca6351
	.quad	0x1429296714292967, 0x1429296714292967
	.quad	0x1429296714292967, 0x1429296714292967
	.quad	0x1429296714292967, 0x1429296714292967
	.quad	0x1429296714292967, 0x1429296714292967
	.quad	0x27b70a8527b70a85, 0x27b70a8527b70a85
	.quad	0x27b70a8527b70a85, 0x27b70a8527b70a85
	.quad	0x27b70a8527b70a85, 0x27b70a8527b70a85
	.quad	0x27b70a8527b70a85, 0x27b70a8527b70a85
	.quad	0x2e1b21382e1b2138, 0x2e1b21382e1b2138
	.quad	0x2e1b21382e1b2138, 0x2e1b21382e1b2138
	.quad	0x2e1b21382e1b2138, 0x2e1b21382e1b2138
	.quad	0x2e1b21382e1b2138, 0x2e1b21382e1b2138
	.quad	0x4d2c6dfc4d2c6dfc, 0x4d2c6dfc4d2c6dfc
	.quad	0x4d2c6dfc4d2c6dfc, 0x4d2c6dfc4d2c6dfc
	.quad	0x4d2c6dfc4d2c6dfc, 0x4d2c6dfc4d2c6dfc
	.quad	0x4d2c6dfc4d2c6dfc, 0x4d2c6dfc4d2c6dfc
	.quad	0x53380d1353380d13, 0x53380d1353380d13
	.quad	0x53380d1353380d13, 0x53380d1353380d13
	.quad	0x53380d1353380d13, 0x53380d1353380d13
	.quad	0x53380d1353380d13, 0x53380d1353380d13
	.quad	0x650a7354650a7354, 0x650a7354650a7354
	.quad	0x650a7354650a7354, 0x650a7354650a7354
	.quad	0x650a7354650a7354, 0x650a7354650a7354
	.quad	0x650a7354650a7354, 0x650a7354650a7354
	.quad	0x766a0abb766a0abb, 0x766a0abb766a0abb
	.quad	0x766a0abb766a0abb, 0x766a0abb766a0abb
	.quad	0x766a0abb766a0abb, 0x766a0abb766a0abb
	.quad	0x766a0abb766a0abb, 0x766a0abb766a0abb
	.quad	0x81c2c92e81c2c92e, 0x81c2c92e81c2c92e
	.quad	0x81c2c92e81c2c92e, 0x81c2c92e81c2c92e
	.quad	0x81c2c92e81c2c92e, 0x81c2c92e81c2c92e
	.quad	0x81c2c92e81c2c92e, 0x81c2c92e81c2c92e
	.quad	0x92722c8592722c85, 0x92722c8592722c85
	.quad	0x92722c8592722c85, 0x92722c8592722c85
	.quad	0x92722c8592722c85, 0x92722c8592722c85
	.quad	0x92722c8592722c85, 0x92722c8592722c85
	.quad	0xa2bfe8a1a2bfe8a1, 0xa2bfe8a1a2bfe8a1
	.quad	0xa2bfe8a1a2bfe8a1, 0xa2bfe8a1a2bfe8a1
	.quad	0xa2bfe8a1a2bfe8a1, 0xa2bfe8a1a2bfe8a1
	.quad	0xa2bfe8a1a2bfe8a1, 0xa2bfe8a1a2bfe8a1
	.quad	0xa81a664ba81a664b, 0xa81a664ba81a664b
	.quad	0xa81a664ba81a664b, 0xa81a664ba81a664b
	.quad	0xa81a664ba81a664b, 0xa81a664ba81a664b
	.quad	0xa81a664ba81a664b, 0xa81a664ba81a664b
	.quad	0xc24b8b70c24b8b70, 0xc24b8b70c24b8b70
	.quad	0xc24b8b70c24b8b70, 0xc24b8b70c24b8b70
	.quad	0xc24b8b70c24b8b70, 0xc24b8b70c24b8b70
	.quad	0xc24b8b70c24b8b70, 0xc24b8b70c24b8b70
	.quad	0xc76c51a3c76c51a3, 0xc76c51a3c76c51a3
	.quad	0xc76c51a3c76c51a3, 0xc76c51a3c76c51a3
	.quad	0xc76c51a3c76c51a3, 0xc76c51a3c76c51a3
	.quad	0xc76c51a3c76c51a3, 0xc76c51a3c76c51a3
	.quad	0xd192e819d192e819, 0xd192e819d192e819
	.quad	0xd192e819d192e819, 0xd192e819d192e819
	.quad	0xd192e819d192e819, 0xd192e819d192e819
	.quad	0xd192e819d192e819, 0xd192e819d192e819
	.quad	0xd6990624d6990624, 0xd6990624d6990624
	.quad	0xd6990624d6990624, 0xd6990624d6990624
	.quad	0xd6990624d6990624, 0xd6990624d6990624
	.quad	0xd6990624d6990624, 0xd6990624d6990624
	.quad	0xf40e3585f40e3585, 0xf40e3585f40e3585
	.quad	0xf40e3585f40e3585, 0xf40e3585f40e3585
	.quad	0xf40e3585f40e3585, 0xf40e3585f40e3585
	.quad	0xf40e3585f40e3585, 0xf40e3585f40e3585
	.quad	0x106aa070106aa070, 0x106aa070106aa070
	.quad	0x106aa070106aa070, 0x106aa070106aa070
	.quad	0x106aa070106aa070, 0x106aa070106aa070
	.quad	0x106aa070106aa070, 0x106aa070106aa070
	.quad	0x19a4c11619a4c116, 0x19a4c11619a4c116
	.quad	0x19a4c11619a4c116, 0x19a4c11619a4c116
	.quad	0x19a4c11619a4c116, 0x19a4c11619a4c116
	.quad	0x19a4c11619a4c116, 0x19a4c11619a4c116
	.quad	0x1e376c081e376c08, 0x1e376c081e376c08
	.quad	0x1e376c081e376c08, 0x1e376c081e376c08
	.quad	0x1e376c081e376c08, 0x1e376c081e376c08
	.quad	0x1e376c081e376c08, 0x1e376c081e376c08
	.quad	0x2748774c2748774c, 0x2748774c2748774c
	.quad	0x2748774c2748774c, 0x2748774c2748774c
	.quad	0x2748774c2748774c, 0x2748774c2748774c
	.quad	0x2748774c2748774c, 0x2748774c2748774c
	.quad	0x34b0bcb534b0bcb5, 0x34b0bcb534b0bcb5
	.quad	0x34b0bcb534b0bcb5, 0x34b0bcb534b0bcb5
	.quad	0x34b0bcb534b0bcb5, 0x34b0bcb534b0bcb5
	.quad	0x34b0bcb534b0bcb5, 0x34b0bcb534b0bcb5
	.quad	0x391c0cb3391c0cb3, 0x391c0cb3391c0cb3
	.quad	0x391c0cb3391c0cb3, 0x391c0cb3391c0cb3
	.quad	0x391c0cb3391c0cb3, 0x391c0cb3391c0cb3
	.quad	0x391c0cb3391c0cb3, 0x391c0cb3391c0cb3
	.quad	0x4ed8aa4a4ed8aa4a, 0x4ed8aa4a4ed8aa4a
	.quad	0x4ed8aa4a4ed8aa4a, 0x4ed8aa4a4ed8aa4a
	.quad	0x4ed8aa4a4ed8aa4a, 0x4ed8aa4a4ed8aa4a
	.quad	0x4ed8aa4a4ed8aa4a, 0x4ed8aa4a4ed8aa4a
	.quad	0x5b9cca4f5b9cca4f, 0x5b9cca4f5b9cca4f
	.quad	0x5b9cca4f5b9cca4f, 0x5b9cca4f5b9cca4f
	.quad	0x5b9cca4f5b9cca4f, 0x5b9cca4f5b9cca4f
	.quad	0x5b9cca4f5b9cca4f, 0x5b9cca4f5b9cca4f
	.quad	0x682e6ff3682e6ff3, 0x682e6ff3682e6ff3
	.quad	0x682e6ff3682e6ff3, 0x682e6ff3682e6ff3
	.quad	0x682e6ff3682e6ff3, 0x682e6ff3682e6ff3
	.quad	0x682e6ff3682e6ff3, 0x682e6ff3682e6ff3
	.quad	0x748f82ee748f82ee, 0x748f82ee748f82ee
	.quad	0x748f82ee748f82ee, 0x748f82ee748f82ee
	.quad	0x748f82ee748f82ee, 0x748f82ee748f82ee
	.quad	0x748f82ee748f82ee, 0x748f82ee748f82ee
	.quad	0x78a5636f78a5636f, 0x78a5636f78a5636f
	.quad	0x78a5636f78a5636f, 0x78a5636f78a5636f
	.quad	0x78a5636f78a5636f, 0x78a5636f78a5636f
	.quad	0x78a5636f78a5636f, 0x78a5636f78a5636f
	.quad	0x84c8781484c87814, 0x84c8781484c87814
	.quad	0x84c8781484c87814, 0x84c8781484c87814
	.quad	0x84c8781484c87814, 0x84c8781484c87814
	.quad	0x84c8781484c87814, 0x84c8781484c87814
	.quad	0x8cc702088cc70208, 0x8cc702088cc70208
	.quad	0x8cc702088cc70208, 0x8cc702088cc70208
	.quad	0x8cc702088cc70208, 0x8cc702088cc70208
	.quad	0x8cc702088cc70208, 0x8cc702088cc70208
	.quad	0x90befffa90befffa, 0x90befffa90befffa
	.quad	0x90befffa90befffa, 0x90befffa90befffa
	.quad	0x90befffa90befffa, 0x90befffa90befffa
	.quad	0x90befffa90befffa, 0x90befffa90befffa
	.quad	0xa4506ceba4506ceb, 0xa4506ceba4506ceb
	.quad	0xa4506ceba4506ceb, 0xa4506ceba4506ceb
	.quad	0xa4506ceba4506ceb, 0xa4506ceba4506ceb
	.quad	0xa4506ceba4506ceb, 0xa4506ceba4506ceb
	.quad	0xbef9a3f7bef9a3f7, 0xbef9a3f7bef9a3f7
	.quad	0xbef9a3f7bef9a3f7, 0xbef9a3f7bef9a3f7
	.quad	0xbef9a3f7bef9a3f7, 0xbef9a3f7bef9a3f7
	.quad	0xbef9a3f7bef9a3f7, 0xbef9a3f7bef9a3f7
	.quad	0xc67178f2c67178f2, 0xc67178f2c67178f2
	.quad	0xc67178f2c67178f2, 0xc67178f2c67178f2
	.quad	0xc67178f2c67178f2, 0xc67178f2c67178f2
	.quad	0xc67178f2c67178f2, 0xc67178f2c67178f2

.LPSHUFFLE_BYTE_FLIP_MASK:
	 .quad 0x0405060700010203, 0x0c0d0e0f08090a0b
	 .quad 0x0405060700010203, 0x0c0d0e0f08090a0b
	 .quad 0x0405060700010203, 0x0c0d0e0f08090a0b
	 .quad 0x0405060700010203, 0x0c0d0e0f08090a0b

.LPADDING_16:
	.octa     0xc28a2f98c28a2f98c28a2f98c28a2f98
	.octa     0xc28a2f98c28a2f98c28a2f98c28a2f98
	.octa     0xc28a2f98c28a2f98c28a2f98c28a2f98
	.octa     0xc28a2f98c28a2f98c28a2f98c28a2f98
	.octa 	  0x71374491713744917137449171374491
	.octa 	  0x71374491713744917137449171374491
	.octa 	  0x71374491713744917137449171374491
	.octa 	  0x71374491713744917137449171374491
	.octa 	  0xb5c0fbcfb5c0fbcfb5c0fbcfb5c0fbcf
	.octa 	  0xb5c0fbcfb5c0fbcfb5c0fbcfb5c0fbcf
	.octa 	  0xb5c0fbcfb5c0fbcfb5c0fbcfb5c0fbcf
	.octa 	  0xb5c0fbcfb5c0fbcfb5c0fbcfb5c0fbcf
	.octa 	  0xe9b5dba5e9b5dba5e9b5dba5e9b5dba5
	.octa 	  0xe9b5dba5e9b5dba5e9b5dba5e9b5dba5
	.octa 	  0xe9b5dba5e9b5dba5e9b5dba5e9b5dba5
	.octa 	  0xe9b5dba5e9b5dba5e9b5dba5e9b5dba5
        .octa     0x3956c25b3956c25b3956c25b3956c25b
        .octa     0x3956c25b3956c25b3956c25b3956c25b
        .octa     0x3956c25b3956c25b3956c25b3956c25b
        .octa     0x3956c25b3956c25b3956c25b3956c25b
        .octa     0x59f111f159f111f159f111f159f111f1
        .octa     0x59f111f159f111f159f111f159f111f1
        .octa     0x59f111f159f111f159f111f159f111f1
        .octa     0x59f111f159f111f159f111f159f111f1
        .octa     0x923f82a4923f82a4923f82a4923f82a4
        .octa     0x923f82a4923f82a4923f82a4923f82a4
        .octa     0x923f82a4923f82a4923f82a4923f82a4
        .octa     0x923f82a4923f82a4923f82a4923f82a4
        .octa     0xab1c5ed5ab1c5ed5ab1c5ed5ab1c5ed5
        .octa     0xab1c5ed5ab1c5ed5ab1c5ed5ab1c5ed5
        .octa     0xab1c5ed5ab1c5ed5ab1c5ed5ab1c5ed5
        .octa     0xab1c5ed5ab1c5ed5ab1c5ed5ab1c5ed5
        .octa     0xd807aa98d807aa98d807aa98d807aa98
        .octa     0xd807aa98d807aa98d807aa98d807aa98
        .octa     0xd807aa98d807aa98d807aa98d807aa98
        .octa     0xd807aa98d807aa98d807aa98d807aa98
        .octa     0x12835b0112835b0112835b0112835b01
        .octa     0x12835b0112835b0112835b0112835b01
        .octa     0x12835b0112835b0112835b0112835b01
        .octa     0x12835b0112835b0112835b0112835b01
        .octa     0x243185be243185be243185be243185be
        .octa     0x243185be243185be243185be243185be
        .octa     0x243185be243185be243185be243185be
        .octa     0x243185be243185be243185be243185be
        .octa     0x550c7dc3550c7dc3550c7dc3550c7dc3
        .octa     0x550c7dc3550c7dc3550c7dc3550c7dc3
        .octa     0x550c7dc3550c7dc3550c7dc3550c7dc3
        .octa     0x550c7dc3550c7dc3550c7dc3550c7dc3
        .octa     0x72be5d7472be5d7472be5d7472be5d74
        .octa     0x72be5d7472be5d7472be5d7472be5d74
        .octa     0x72be5d7472be5d7472be5d7472be5d74
        .octa     0x72be5d7472be5d7472be5d7472be5d74
        .octa     0x80deb1fe80deb1fe80deb1fe80deb1fe
        .octa     0x80deb1fe80deb1fe80deb1fe80deb1fe
        .octa     0x80deb1fe80deb1fe80deb1fe80deb1fe
        .octa     0x80deb1fe80deb1fe80deb1fe80deb1fe
        .octa     0x9bdc06a79bdc06a79bdc06a79bdc06a7
        .octa     0x9bdc06a79bdc06a79bdc06a79bdc06a7
        .octa     0x9bdc06a79bdc06a79bdc06a79bdc06a7
        .octa     0x9bdc06a79bdc06a79bdc06a79bdc06a7
        .octa     0xc19bf374c19bf374c19bf374c19bf374
        .octa     0xc19bf374c19bf374c19bf374c19bf374
        .octa     0xc19bf374c19bf374c19bf374c19bf374
        .octa     0xc19bf374c19bf374c19bf374c19bf374
        .octa     0x649b69c1649b69c1649b69c1649b69c1
        .octa     0x649b69c1649b69c1649b69c1649b69c1
        .octa     0x649b69c1649b69c1649b69c1649b69c1
        .octa     0x649b69c1649b69c1649b69c1649b69c1
        .octa     0xf0fe4786f0fe4786f0fe4786f0fe4786
        .octa     0xf0fe4786f0fe4786f0fe4786f0fe4786
        .octa     0xf0fe4786f0fe4786f0fe4786f0fe4786
        .octa     0xf0fe4786f0fe4786f0fe4786f0fe4786
        .octa     0x0fe1edc60fe1edc60fe1edc60fe1edc6
        .octa     0x0fe1edc60fe1edc60fe1edc60fe1edc6
        .octa     0x0fe1edc60fe1edc60fe1edc60fe1edc6
        .octa     0x0fe1edc60fe1edc60fe1edc60fe1edc6
        .octa     0x240cf254240cf254240cf254240cf254
        .octa     0x240cf254240cf254240cf254240cf254
        .octa     0x240cf254240cf254240cf254240cf254
        .octa     0x240cf254240cf254240cf254240cf254
        .octa     0x4fe9346f4fe9346f4fe9346f4fe9346f
        .octa     0x4fe9346f4fe9346f4fe9346f4fe9346f
        .octa     0x4fe9346f4fe9346f4fe9346f4fe9346f
        .octa     0x4fe9346f4fe9346f4fe9346f4fe9346f
        .octa     0x6cc984be6cc984be6cc984be6cc984be
        .octa     0x6cc984be6cc984be6cc984be6cc984be
        .octa     0x6cc984be6cc984be6cc984be6cc984be
        .octa     0x6cc984be6cc984be6cc984be6cc984be
        .octa     0x61b9411e61b9411e61b9411e61b9411e
        .octa     0x61b9411e61b9411e61b9411e61b9411e
        .octa     0x61b9411e61b9411e61b9411e61b9411e
        .octa     0x61b9411e61b9411e61b9411e61b9411e
        .octa     0x16f988fa16f988fa16f988fa16f988fa
        .octa     0x16f988fa16f988fa16f988fa16f988fa
        .octa     0x16f988fa16f988fa16f988fa16f988fa
        .octa     0x16f988fa16f988fa16f988fa16f988fa
        .octa     0xf2c65152f2c65152f2c65152f2c65152
        .octa     0xf2c65152f2c65152f2c65152f2c65152
        .octa     0xf2c65152f2c65152f2c65152f2c65152
        .octa     0xf2c65152f2c65152f2c65152f2c65152
        .octa     0xa88e5a6da88e5a6da88e5a6da88e5a6d
        .octa     0xa88e5a6da88e5a6da88e5a6da88e5a6d
        .octa     0xa88e5a6da88e5a6da88e5a6da88e5a6d
        .octa     0xa88e5a6da88e5a6da88e5a6da88e5a6d
        .octa     0xb019fc65b019fc65b019fc65b019fc65
        .octa     0xb019fc65b019fc65b019fc65b019fc65
        .octa     0xb019fc65b019fc65b019fc65b019fc65
        .octa     0xb019fc65b019fc65b019fc65b019fc65
        .octa     0xb9d99ec7b9d99ec7b9d99ec7b9d99ec7
        .octa     0xb9d99ec7b9d99ec7b9d99ec7b9d99ec7
        .octa     0xb9d99ec7b9d99ec7b9d99ec7b9d99ec7
        .octa     0xb9d99ec7b9d99ec7b9d99ec7b9d99ec7
        .octa     0x9a1231c39a1231c39a1231c39a1231c3
        .octa     0x9a1231c39a1231c39a1231c39a1231c3
        .octa     0x9a1231c39a1231c39a1231c39a1231c3
        .octa     0x9a1231c39a1231c39a1231c39a1231c3
        .octa     0xe70eeaa0e70eeaa0e70eeaa0e70eeaa0
        .octa     0xe70eeaa0e70eeaa0e70eeaa0e70eeaa0
        .octa     0xe70eeaa0e70eeaa0e70eeaa0e70eeaa0
        .octa     0xe70eeaa0e70eeaa0e70eeaa0e70eeaa0
        .octa     0xfdb1232bfdb1232bfdb1232bfdb1232b
        .octa     0xfdb1232bfdb1232bfdb1232bfdb1232b
        .octa     0xfdb1232bfdb1232bfdb1232bfdb1232b
        .octa     0xfdb1232bfdb1232bfdb1232bfdb1232b
        .octa     0xc7353eb0c7353eb0c7353eb0c7353eb0
        .octa     0xc7353eb0c7353eb0c7353eb0c7353eb0
        .octa     0xc7353eb0c7353eb0c7353eb0c7353eb0
        .octa     0xc7353eb0c7353eb0c7353eb0c7353eb0
        .octa     0x3069bad53069bad53069bad53069bad5
        .octa     0x3069bad53069bad53069bad53069bad5
        .octa     0x3069bad53069bad53069bad53069bad5
        .octa     0x3069bad53069bad53069bad53069bad5
        .octa     0xcb976d5fcb976d5fcb976d5fcb976d5f
        .octa     0xcb976d5fcb976d5fcb976d5fcb976d5f
        .octa     0xcb976d5fcb976d5fcb976d5fcb976d5f
        .octa     0xcb976d5fcb976d5fcb976d5fcb976d5f
        .octa     0x5a0f118f5a0f118f5a0f118f5a0f118f
        .octa     0x5a0f118f5a0f118f5a0f118f5a0f118f
        .octa     0x5a0f118f5a0f118f5a0f118f5a0f118f
        .octa     0x5a0f118f5a0f118f5a0f118f5a0f118f
        .octa     0xdc1eeefddc1eeefddc1eeefddc1eeefd
        .octa     0xdc1eeefddc1eeefddc1eeefddc1eeefd
        .octa     0xdc1eeefddc1eeefddc1eeefddc1eeefd
        .octa     0xdc1eeefddc1eeefddc1eeefddc1eeefd
        .octa     0x0a35b6890a35b6890a35b6890a35b689
        .octa     0x0a35b6890a35b6890a35b6890a35b689
        .octa     0x0a35b6890a35b6890a35b6890a35b689
        .octa     0x0a35b6890a35b6890a35b6890a35b689
        .octa     0xde0b7a04de0b7a04de0b7a04de0b7a04
        .octa     0xde0b7a04de0b7a04de0b7a04de0b7a04
        .octa     0xde0b7a04de0b7a04de0b7a04de0b7a04
        .octa     0xde0b7a04de0b7a04de0b7a04de0b7a04
        .octa     0x58f4ca9d58f4ca9d58f4ca9d58f4ca9d
        .octa     0x58f4ca9d58f4ca9d58f4ca9d58f4ca9d
        .octa     0x58f4ca9d58f4ca9d58f4ca9d58f4ca9d
        .octa     0x58f4ca9d58f4ca9d58f4ca9d58f4ca9d
        .octa     0xe15d5b16e15d5b16e15d5b16e15d5b16
        .octa     0xe15d5b16e15d5b16e15d5b16e15d5b16
        .octa     0xe15d5b16e15d5b16e15d5b16e15d5b16
        .octa     0xe15d5b16e15d5b16e15d5b16e15d5b16
        .octa     0x007f3e86007f3e86007f3e86007f3e86
        .octa     0x007f3e86007f3e86007f3e86007f3e86
        .octa     0x007f3e86007f3e86007f3e86007f3e86
        .octa     0x007f3e86007f3e86007f3e86007f3e86
        .octa     0x37088980370889803708898037088980
        .octa     0x37088980370889803708898037088980
        .octa     0x37088980370889803708898037088980
        .octa     0x37088980370889803708898037088980
        .octa     0xa507ea32a507ea32a507ea32a507ea32
        .octa     0xa507ea32a507ea32a507ea32a507ea32
        .octa     0xa507ea32a507ea32a507ea32a507ea32
        .octa     0xa507ea32a507ea32a507ea32a507ea32
        .octa     0x6fab95376fab95376fab95376fab9537
        .octa     0x6fab95376fab95376fab95376fab9537
        .octa     0x6fab95376fab95376fab95376fab9537
        .octa     0x6fab95376fab95376fab95376fab9537
        .octa     0x17406110174061101740611017406110
        .octa     0x17406110174061101740611017406110
        .octa     0x17406110174061101740611017406110
        .octa     0x17406110174061101740611017406110
        .octa     0x0d8cd6f10d8cd6f10d8cd6f10d8cd6f1
        .octa     0x0d8cd6f10d8cd6f10d8cd6f10d8cd6f1
        .octa     0x0d8cd6f10d8cd6f10d8cd6f10d8cd6f1
        .octa     0x0d8cd6f10d8cd6f10d8cd6f10d8cd6f1
        .octa     0xcdaa3b6dcdaa3b6dcdaa3b6dcdaa3b6d
        .octa     0xcdaa3b6dcdaa3b6dcdaa3b6dcdaa3b6d
        .octa     0xcdaa3b6dcdaa3b6dcdaa3b6dcdaa3b6d
        .octa     0xcdaa3b6dcdaa3b6dcdaa3b6dcdaa3b6d
        .octa     0xc0bbbe37c0bbbe37c0bbbe37c0bbbe37
        .octa     0xc0bbbe37c0bbbe37c0bbbe37c0bbbe37
        .octa     0xc0bbbe37c0bbbe37c0bbbe37c0bbbe37
        .octa     0xc0bbbe37c0bbbe37c0bbbe37c0bbbe37
        .octa     0x83613bda83613bda83613bda83613bda
        .octa     0x83613bda83613bda83613bda83613bda
        .octa     0x83613bda83613bda83613bda83613bda
        .octa     0x83613bda83613bda83613bda83613bda
        .octa     0xdb48a363db48a363db48a363db48a363
        .octa     0xdb48a363db48a363db48a363db48a363
        .octa     0xdb48a363db48a363db48a363db48a363
        .octa     0xdb48a363db48a363db48a363db48a363
        .octa     0x0b02e9310b02e9310b02e9310b02e931
        .octa     0x0b02e9310b02e9310b02e9310b02e931
        .octa     0x0b02e9310b02e9310b02e9310b02e931
        .octa     0x0b02e9310b02e9310b02e9310b02e931
        .octa     0x6fd15ca76fd15ca76fd15ca76fd15ca7
        .octa     0x6fd15ca76fd15ca76fd15ca76fd15ca7
        .octa     0x6fd15ca76fd15ca76fd15ca76fd15ca7
        .octa     0x6fd15ca76fd15ca76fd15ca76fd15ca7
        .octa     0x521afaca521afaca521afaca521afaca
        .octa     0x521afaca521afaca521afaca521afaca
        .octa     0x521afaca521afaca521afaca521afaca
        .octa     0x521afaca521afaca521afaca521afaca
        .octa     0x31338431313384313133843131338431
        .octa     0x31338431313384313133843131338431
        .octa     0x31338431313384313133843131338431
        .octa     0x31338431313384313133843131338431
        .octa     0x6ed41a956ed41a956ed41a956ed41a95
        .octa     0x6ed41a956ed41a956ed41a956ed41a95
        .octa     0x6ed41a956ed41a956ed41a956ed41a95
        .octa     0x6ed41a956ed41a956ed41a956ed41a95
        .octa     0x6d4378906d4378906d4378906d437890
        .octa     0x6d4378906d4378906d4378906d437890
        .octa     0x6d4378906d4378906d4378906d437890
        .octa     0x6d4378906d4378906d4378906d437890
        .octa     0xc39c91f2c39c91f2c39c91f2c39c91f2
        .octa     0xc39c91f2c39c91f2c39c91f2c39c91f2
        .octa     0xc39c91f2c39c91f2c39c91f2c39c91f2
        .octa     0xc39c91f2c39c91f2c39c91f2c39c91f2
        .octa     0x9eccabbd9eccabbd9eccabbd9eccabbd
        .octa     0x9eccabbd9eccabbd9eccabbd9eccabbd
        .octa     0x9eccabbd9eccabbd9eccabbd9eccabbd
        .octa     0x9eccabbd9eccabbd9eccabbd9eccabbd
        .octa     0xb5c9a0e6b5c9a0e6b5c9a0e6b5c9a0e6
        .octa     0xb5c9a0e6b5c9a0e6b5c9a0e6b5c9a0e6
        .octa     0xb5c9a0e6b5c9a0e6b5c9a0e6b5c9a0e6
        .octa     0xb5c9a0e6b5c9a0e6b5c9a0e6b5c9a0e6
        .octa     0x532fb63c532fb63c532fb63c532fb63c
        .octa     0x532fb63c532fb63c532fb63c532fb63c
        .octa     0x532fb63c532fb63c532fb63c532fb63c
        .octa     0x532fb63c532fb63c532fb63c532fb63c
        .octa     0xd2c741c6d2c741c6d2c741c6d2c741c6
        .octa     0xd2c741c6d2c741c6d2c741c6d2c741c6
        .octa     0xd2c741c6d2c741c6d2c741c6d2c741c6
        .octa     0xd2c741c6d2c741c6d2c741c6d2c741c6
        .octa     0x07237ea307237ea307237ea307237ea3
        .octa     0x07237ea307237ea307237ea307237ea3
        .octa     0x07237ea307237ea307237ea307237ea3
        .octa     0x07237ea307237ea307237ea307237ea3
        .octa     0xa4954b68a4954b68a4954b68a4954b68
        .octa     0xa4954b68a4954b68a4954b68a4954b68
        .octa     0xa4954b68a4954b68a4954b68a4954b68
        .octa     0xa4954b68a4954b68a4954b68a4954b68
        .octa     0x4c191d764c191d764c191d764c191d76
        .octa     0x4c191d764c191d764c191d764c191d76
        .octa     0x4c191d764c191d764c191d764c191d76
        .octa     0x4c191d764c191d764c191d764c191d76

.LDIGEST_16:
        .long   0x6a09e667, 0x6a09e667, 0x6a09e667, 0x6a09e667
        .long   0x6a09e667, 0x6a09e667, 0x6a09e667, 0x6a09e667
        .long   0x6a09e667, 0x6a09e667, 0x6a09e667, 0x6a09e667
        .long   0x6a09e667, 0x6a09e667, 0x6a09e667, 0x6a09e667
	.long 	0xbb67ae85, 0xbb67ae85, 0xbb67ae85, 0xbb67ae85 
	.long 	0xbb67ae85, 0xbb67ae85, 0xbb67ae85, 0xbb67ae85 
	.long 	0xbb67ae85, 0xbb67ae85, 0xbb67ae85, 0xbb67ae85 
	.long 	0xbb67ae85, 0xbb67ae85, 0xbb67ae85, 0xbb67ae85 
	.long   0x3c6ef372, 0x3c6ef372, 0x3c6ef372, 0x3c6ef372 
	.long   0x3c6ef372, 0x3c6ef372, 0x3c6ef372, 0x3c6ef372 
	.long   0x3c6ef372, 0x3c6ef372, 0x3c6ef372, 0x3c6ef372 
	.long   0x3c6ef372, 0x3c6ef372, 0x3c6ef372, 0x3c6ef372 
	.long 	0xa54ff53a, 0xa54ff53a, 0xa54ff53a, 0xa54ff53a 
	.long 	0xa54ff53a, 0xa54ff53a, 0xa54ff53a, 0xa54ff53a 
	.long 	0xa54ff53a, 0xa54ff53a, 0xa54ff53a, 0xa54ff53a 
	.long 	0xa54ff53a, 0xa54ff53a, 0xa54ff53a, 0xa54ff53a 
	.long	0x510e527f, 0x510e527f, 0x510e527f, 0x510e527f
	.long	0x510e527f, 0x510e527f, 0x510e527f, 0x510e527f
	.long	0x510e527f, 0x510e527f, 0x510e527f, 0x510e527f
	.long	0x510e527f, 0x510e527f, 0x510e527f, 0x510e527f
	.long 	0x9b05688c, 0x9b05688c, 0x9b05688c, 0x9b05688c 
	.long 	0x9b05688c, 0x9b05688c, 0x9b05688c, 0x9b05688c 
	.long 	0x9b05688c, 0x9b05688c, 0x9b05688c, 0x9b05688c 
	.long 	0x9b05688c, 0x9b05688c, 0x9b05688c, 0x9b05688c 
	.long	0x1f83d9ab, 0x1f83d9ab, 0x1f83d9ab, 0x1f83d9ab
	.long	0x1f83d9ab, 0x1f83d9ab, 0x1f83d9ab, 0x1f83d9ab
	.long	0x1f83d9ab, 0x1f83d9ab, 0x1f83d9ab, 0x1f83d9ab
	.long	0x1f83d9ab, 0x1f83d9ab, 0x1f83d9ab, 0x1f83d9ab
        .long   0x5be0cd19, 0x5be0cd19, 0x5be0cd19, 0x5be0cd19
        .long   0x5be0cd19, 0x5be0cd19, 0x5be0cd19, 0x5be0cd19
        .long   0x5be0cd19, 0x5be0cd19, 0x5be0cd19, 0x5be0cd19
        .long   0x5be0cd19, 0x5be0cd19, 0x5be0cd19, 0x5be0cd19

.LPSHUFFLE_TRANSPOSE_MASK1:
				.quad 0x0000000000000000
				.quad 0x0000000000000001
				.quad 0x0000000000000008
				.quad 0x0000000000000009
				.quad 0x0000000000000004
				.quad 0x0000000000000005
				.quad 0x000000000000000C
				.quad 0x000000000000000D

.LPSHUFFLE_TRANSPOSE_MASK2:
				.quad 0x0000000000000002
				.quad 0x0000000000000003
				.quad 0x000000000000000A
				.quad 0x000000000000000B
				.quad 0x0000000000000006
				.quad 0x0000000000000007
				.quad 0x000000000000000E
				.quad 0x000000000000000F

.LPSHUFFLE_TRANSPOSE_MASK3:
	.long	0x00000000, 0x00000002, 0x00000010, 0x00000012
	.long	0x00000001, 0x00000003, 0x00000011, 0x00000013
	.long	0x00000004, 0x00000006, 0x00000014, 0x00000016
	.long	0x00000005, 0x00000007, 0x00000015, 0x00000017
				
.LPSHUFFLE_TRANSPOSE_MASK4:
	.long	0x00000008, 0x0000000a, 0x00000018, 0x0000001a
	.long	0x00000009, 0x0000000b, 0x00000019, 0x0000001b
	.long	0x0000000c, 0x0000000e, 0x0000001c, 0x0000001e
	.long	0x0000000d, 0x0000000f, 0x0000001d, 0x0000001f

.text
.global hashtree_sha256_avx512_x16
#ifndef __WIN64__
.type hashtree_sha256_avx512_x16,%function
#endif
.align 64
hashtree_sha256_avx512_x16:
        endbr64
        cmp     COUNT, 0
        jne     .Lstart_routine
        ret

.Lstart_routine:
	lea	PADDING, [rip + .LPADDING_16]
	lea	DIGEST,	[rip + .LDIGEST_16]
	lea	TBL, [rip + .LK256_16]

.Lsha256_16_avx512loop:
.set .Lpadding, 0
	
	cmp		COUNT, 16
	jb		hashtree_sha256_avx2_x8
	
	# Load pre-transposed digest
	vmovdqa32	A, [DIGEST + 0*64]
	vmovdqa32	B, [DIGEST + 1*64]
	vmovdqa32	C, [DIGEST + 2*64]
	vmovdqa32	D, [DIGEST + 3*64]
	vmovdqa32	E, [DIGEST + 4*64]
	vmovdqa32	F, [DIGEST + 5*64]
	vmovdqa32	G, [DIGEST + 6*64]
	vmovdqa32	H, [DIGEST + 7*64]
	
	# Load incoming blocks 16 at a time, start loading the lower
	# part of the 16 blocks
	# W0  = {X X X X  X X X X  a7  a6  a5  a4    a3  a2  a1 a0}
	# W1  = {X X X X  X X X X  b7  b6  b5  b4    b3  b2  b1 b0}
	# W2  = {X X X X  X X X X  c7  c6  c5  c4    c3  c2  c1 c0}
	# W3  = {X X X X  X X X X  d7  d6  d5  d4    d3  d2  d1 d0}
	# W4  = {X X X X  X X X X  e7  e6  e5  e4    e3  e2  e1 e0}
	# W5  = {X X X X  X X X X  f7  f6  f5  f4    f3  f2  f1 f0}
	# W6  = {X X X X  X X X X  g7  g6  g5  g4    g3  g2  g1 g0}
	# W7  = {X X X X  X X X X  h7  h6  h5  h4    h3  h2  h1 h0}
	# W8  = {X X X X  X X X X  a15 a14 a13 a12   a11 a10 a9 a8}
	# W9  = {X X X X  X X X X  b15 b14 b13 b12   b11 b10 b9 b8}
	# W10 = {X X X X  X X X X  c15 c14 c13 c12   c11 c10 c9 c8}
	# W11 = {X X X X  X X X X  d15 d14 d13 d12   d11 d10 d9 d8}
	# W12 = {X X X X  X X X X  e15 e14 e13 e12   e11 e10 e9 e8}
	# W13 = {X X X X  X X X X  f15 f14 f13 f12   f11 f10 f9 f8}
	# W14 = {X X X X  X X X X  g15 g14 g13 g12   g11 g10 g9 g8}
	# W15 = {X X X X  X X X X  h15 h14 h13 h12   h11 h10 h9 h8}
	vmovups	YW0,[DATA_PTR+0*64]
	vmovups	YW1,[DATA_PTR+1*64]
	vmovups	YW2,[DATA_PTR+2*64]
	vmovups	YW3,[DATA_PTR+3*64]
	vmovups	YW4,[DATA_PTR+4*64]
	vmovups	YW5,[DATA_PTR+5*64]
	vmovups	YW6,[DATA_PTR+6*64]
	vmovups	YW7,[DATA_PTR+7*64]
	vmovups	YW8,[DATA_PTR+0*64+32]
	vmovups	YW9,[DATA_PTR+1*64+32]
	vmovups	YW10,[DATA_PTR+2*64+32]
	vmovups	YW11,[DATA_PTR+3*64+32]
	vmovups	YW12,[DATA_PTR+4*64+32]
	vmovups	YW13,[DATA_PTR+5*64+32]
	vmovups	YW14,[DATA_PTR+6*64+32]
	vmovups	YW15,[DATA_PTR+7*64+32]

	# Load the upper half
	#
	# W0  = {i7  i6  i5  i4    i3  i2  i1 i0   a7  a6  a5  a4    a3  a2  a1 a0}
	# W1  = {j7  j6  j5  j4    j3  j2  j1 j0   b7  b6  b5  b4    b3  b2  b1 b0}
	# W2  = {k7  k6  k5  k4    k3  k2  k1 k0   c7  c6  c5  c4    c3  c2  c1 c0}
	# W3  = {l7  l6  l5  l4    l3  l2  l1 l0   d7  d6  d5  d4    d3  d2  d1 d0}
	# W4  = {m7  m6  m5  m4    m3  m2  m1 m0   e7  e6  e5  e4    e3  e2  e1 e0}
	# W5  = {n7  n6  n5  n4    n3  n2  n1 n0   f7  f6  f5  f4    f3  f2  f1 f0}
	# W6  = {o7  o6  o5  o4    o3  o2  o1 o0   g7  g6  g5  g4    g3  g2  g1 g0}
	# W7  = {p7  p6  p5  p4    p3  p2  p1 p0   h7  h6  h5  h4    h3  h2  h1 h0}
	# W8  = {i15 i14 i13 i12   i11 i10 i9 i8   a15 a14 a13 a12   a11 a10 a9 a8}
	# W9  = {j15 j14 j13 j12   j11 j10 j9 j8   b15 b14 b13 b12   b11 b10 b9 b8}
	# W10 = {k15 k14 k13 k12   k11 k10 k9 k8   c15 c14 c13 c12   c11 c10 c9 c8}
	# W11 = {l15 l14 l13 l12   l11 l10 l9 l8   d15 d14 d13 d12   d11 d10 d9 d8}
	# W12 = {m15 m14 m13 m12   m11 m10 m9 m8   e15 e14 e13 e12   e11 e10 e9 e8}
	# W13 = {n15 n14 n13 n12   n11 n10 n9 n8   f15 f14 f13 f12   f11 f10 f9 f8}
	# W14 = {o15 o14 o13 o12   o11 o10 o9 o8   g15 g14 g13 g12   g11 g10 g9 g8}
	# W15 = {p15 p14 p13 p12   p11 p10 p9 p8   h15 h14 h13 h12   h11 h10 h9 h8}

	vinserti64x4 W0, W0, [DATA_PTR+8*64], 0x01
	vinserti64x4 W1, W1, [DATA_PTR+9*64], 0x01
	vinserti64x4 W2, W2, [DATA_PTR+10*64], 0x01
	vinserti64x4 W3, W3, [DATA_PTR+11*64], 0x01
	vinserti64x4 W4, W4, [DATA_PTR+12*64], 0x01
	vinserti64x4 W5, W5, [DATA_PTR+13*64], 0x01
	vinserti64x4 W6, W6, [DATA_PTR+14*64], 0x01
	vinserti64x4 W7, W7, [DATA_PTR+15*64], 0x01
	vinserti64x4 W8, W8, [DATA_PTR+8*64+32], 0x01
	vinserti64x4 W9, W9, [DATA_PTR+9*64+32], 0x01
	vinserti64x4 W10, W10, [DATA_PTR+10*64+32], 0x01
	vinserti64x4 W11, W11, [DATA_PTR+11*64+32], 0x01
	vinserti64x4 W12, W12, [DATA_PTR+12*64+32], 0x01
	vinserti64x4 W13, W13, [DATA_PTR+13*64+32], 0x01
	vinserti64x4 W14, W14, [DATA_PTR+14*64+32], 0x01
	vinserti64x4 W15, W15, [DATA_PTR+15*64+32], 0x01

.align 32
	vmovdqa32	TMP2, [rip + .LPSHUFFLE_BYTE_FLIP_MASK]
	vmovdqa32	TMP3, [TBL]	# First K


	# W0   = {p0  o0  n0  m0    l0  k0  j0  i0    h0  g0  f0  e0    d0  c0  b0  a0}
	# W1   = {p1  o1  n1  m1    l1  k1  j1  i1    h1  g1  f1  e1    d1  c1  b1  a1}
	# W2   = {p2  o2  n2  m2    l2  k2  j2  i2    h2  g2  f2  e2    d2  c2  b2  a2}
	# W3   = {p3  o3  n3  m3    l3  k3  j3  i3    h3  g3  f3  e3    d3  c3  b3  a3}
	# W4   = {p4  o4  n4  m4    l4  k4  j4  i4    h4  g4  f4  e4    d4  c4  b4  a4}
	# W5   = {p5  o5  n5  m5    l5  k5  j5  i5    h5  g5  f5  e5    d5  c5  b5  a5}
	# W6   = {p6  o6  n6  m6    l6  k6  j6  i6    h6  g6  f6  e6    d6  c6  b6  a6}
	# W7   = {p7  o7  n7  m7    l7  k7  j7  i7    h7  g7  f7  e7    d7  c7  b7  a7}
	# W8   = {p8  o8  n8  m8    l8  k8  j8  i8    h8  g8  f8  e8    d8  c8  b8  a8}
	# W9   = {p9  o9  n9  m9    l9  k9  j9  i9    h9  g9  f9  e9    d9  c9  b9  a9}
	# W10  = {p10 o10 n10 m10   l10 k10 j10 i10   h10 g10 f10 e10   d10 c10 b10 a10}
	# W11  = {p11 o11 n11 m11   l11 k11 j11 i11   h11 g11 f11 e11   d11 c11 b11 a11}
	# W12  = {p12 o12 n12 m12   l12 k12 j12 i12   h12 g12 f12 e12   d12 c12 b12 a12}
	# W13  = {p13 o13 n13 m13   l13 k13 j13 i13   h13 g13 f13 e13   d13 c13 b13 a13}
	# W14  = {p14 o14 n14 m14   l14 k14 j14 i14   h14 g14 f14 e14   d14 c14 b14 a14}
	# W15  = {p15 o15 n15 m15   l15 k15 j15 i15   h15 g15 f15 e15   d15 c15 b15 a15}

	TRANSPOSE16_U32_PRELOADED W0, W1, W2, W3, W4, W5, W6, W7, W8, W9, W10, \
                                  W11, W12, W13, W14, W15, TMP0, TMP1, TMP4, TMP5

	// Byte swap W0-W15 (expanded from .rept 16 + ROTATE_ZMMS)
	vpshufb	INI_W0, INI_W0, TMP2
	vpshufb	INI_W1, INI_W1, TMP2
	vpshufb	INI_W2, INI_W2, TMP2
	vpshufb	INI_W3, INI_W3, TMP2
	vpshufb	INI_W4, INI_W4, TMP2
	vpshufb	INI_W5, INI_W5, TMP2
	vpshufb	INI_W6, INI_W6, TMP2
	vpshufb	INI_W7, INI_W7, TMP2
	vpshufb	INI_W8, INI_W8, TMP2
	vpshufb	INI_W9, INI_W9, TMP2
	vpshufb	INI_W10, INI_W10, TMP2
	vpshufb	INI_W11, INI_W11, TMP2
	vpshufb	INI_W12, INI_W12, TMP2
	vpshufb	INI_W13, INI_W13, TMP2
	vpshufb	INI_W14, INI_W14, TMP2
	vpshufb	INI_W15, INI_W15, TMP2

	// Rounds 0-47: PROCESS_LOOP + MSG_SCHED (expanded)
	// Each round uses A-H rotation (8-cycle) and W rotation (16-cycle)
	// Round 0: A-H state 0, W state 0
	PROCESS_LOOP_P INI_W0, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 0
	vmovdqa32	TMP3, [TBL + 64*1]
	MSG_SCHED_ROUND_16_63 INI_W0, INI_W1, INI_W9, INI_W14
	// Round 1: A-H state 1, W state 1
	PROCESS_LOOP_P INI_W1, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 0
	vmovdqa32	TMP3, [TBL + 64*2]
	MSG_SCHED_ROUND_16_63 INI_W1, INI_W2, INI_W10, INI_W15
	// Round 2: A-H state 2, W state 2
	PROCESS_LOOP_P INI_W2, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 0
	vmovdqa32	TMP3, [TBL + 64*3]
	MSG_SCHED_ROUND_16_63 INI_W2, INI_W3, INI_W11, INI_W0
	// Round 3: A-H state 3, W state 3
	PROCESS_LOOP_P INI_W3, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 0
	vmovdqa32	TMP3, [TBL + 64*4]
	MSG_SCHED_ROUND_16_63 INI_W3, INI_W4, INI_W12, INI_W1
	// Round 4: A-H state 4, W state 4
	PROCESS_LOOP_P INI_W4, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 0
	vmovdqa32	TMP3, [TBL + 64*5]
	MSG_SCHED_ROUND_16_63 INI_W4, INI_W5, INI_W13, INI_W2
	// Round 5: A-H state 5, W state 5
	PROCESS_LOOP_P INI_W5, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 0
	vmovdqa32	TMP3, [TBL + 64*6]
	MSG_SCHED_ROUND_16_63 INI_W5, INI_W6, INI_W14, INI_W3
	// Round 6: A-H state 6, W state 6
	PROCESS_LOOP_P INI_W6, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 0
	vmovdqa32	TMP3, [TBL + 64*7]
	MSG_SCHED_ROUND_16_63 INI_W6, INI_W7, INI_W15, INI_W4
	// Round 7: A-H state 7, W state 7
	PROCESS_LOOP_P INI_W7, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 0
	vmovdqa32	TMP3, [TBL + 64*8]
	MSG_SCHED_ROUND_16_63 INI_W7, INI_W8, INI_W0, INI_W5
	// Round 8: A-H state 0, W state 8
	PROCESS_LOOP_P INI_W8, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 0
	vmovdqa32	TMP3, [TBL + 64*9]
	MSG_SCHED_ROUND_16_63 INI_W8, INI_W9, INI_W1, INI_W6
	// Round 9: A-H state 1, W state 9
	PROCESS_LOOP_P INI_W9, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 0
	vmovdqa32	TMP3, [TBL + 64*10]
	MSG_SCHED_ROUND_16_63 INI_W9, INI_W10, INI_W2, INI_W7
	// Round 10: A-H state 2, W state 10
	PROCESS_LOOP_P INI_W10, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 0
	vmovdqa32	TMP3, [TBL + 64*11]
	MSG_SCHED_ROUND_16_63 INI_W10, INI_W11, INI_W3, INI_W8
	// Round 11: A-H state 3, W state 11
	PROCESS_LOOP_P INI_W11, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 0
	vmovdqa32	TMP3, [TBL + 64*12]
	MSG_SCHED_ROUND_16_63 INI_W11, INI_W12, INI_W4, INI_W9
	// Round 12: A-H state 4, W state 12
	PROCESS_LOOP_P INI_W12, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 0
	vmovdqa32	TMP3, [TBL + 64*13]
	MSG_SCHED_ROUND_16_63 INI_W12, INI_W13, INI_W5, INI_W10
	// Round 13: A-H state 5, W state 13
	PROCESS_LOOP_P INI_W13, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 0
	vmovdqa32	TMP3, [TBL + 64*14]
	MSG_SCHED_ROUND_16_63 INI_W13, INI_W14, INI_W6, INI_W11
	// Round 14: A-H state 6, W state 14
	PROCESS_LOOP_P INI_W14, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 0
	vmovdqa32	TMP3, [TBL + 64*15]
	MSG_SCHED_ROUND_16_63 INI_W14, INI_W15, INI_W7, INI_W12
	// Round 15: A-H state 7, W state 15
	PROCESS_LOOP_P INI_W15, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 0
	vmovdqa32	TMP3, [TBL + 64*16]
	MSG_SCHED_ROUND_16_63 INI_W15, INI_W0, INI_W8, INI_W13
	// Round 16: A-H state 0, W state 0
	PROCESS_LOOP_P INI_W0, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 0
	vmovdqa32	TMP3, [TBL + 64*17]
	MSG_SCHED_ROUND_16_63 INI_W0, INI_W1, INI_W9, INI_W14
	// Round 17: A-H state 1, W state 1
	PROCESS_LOOP_P INI_W1, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 0
	vmovdqa32	TMP3, [TBL + 64*18]
	MSG_SCHED_ROUND_16_63 INI_W1, INI_W2, INI_W10, INI_W15
	// Round 18: A-H state 2, W state 2
	PROCESS_LOOP_P INI_W2, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 0
	vmovdqa32	TMP3, [TBL + 64*19]
	MSG_SCHED_ROUND_16_63 INI_W2, INI_W3, INI_W11, INI_W0
	// Round 19: A-H state 3, W state 3
	PROCESS_LOOP_P INI_W3, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 0
	vmovdqa32	TMP3, [TBL + 64*20]
	MSG_SCHED_ROUND_16_63 INI_W3, INI_W4, INI_W12, INI_W1
	// Round 20: A-H state 4, W state 4
	PROCESS_LOOP_P INI_W4, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 0
	vmovdqa32	TMP3, [TBL + 64*21]
	MSG_SCHED_ROUND_16_63 INI_W4, INI_W5, INI_W13, INI_W2
	// Round 21: A-H state 5, W state 5
	PROCESS_LOOP_P INI_W5, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 0
	vmovdqa32	TMP3, [TBL + 64*22]
	MSG_SCHED_ROUND_16_63 INI_W5, INI_W6, INI_W14, INI_W3
	// Round 22: A-H state 6, W state 6
	PROCESS_LOOP_P INI_W6, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 0
	vmovdqa32	TMP3, [TBL + 64*23]
	MSG_SCHED_ROUND_16_63 INI_W6, INI_W7, INI_W15, INI_W4
	// Round 23: A-H state 7, W state 7
	PROCESS_LOOP_P INI_W7, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 0
	vmovdqa32	TMP3, [TBL + 64*24]
	MSG_SCHED_ROUND_16_63 INI_W7, INI_W8, INI_W0, INI_W5
	// Round 24: A-H state 0, W state 8
	PROCESS_LOOP_P INI_W8, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 0
	vmovdqa32	TMP3, [TBL + 64*25]
	MSG_SCHED_ROUND_16_63 INI_W8, INI_W9, INI_W1, INI_W6
	// Round 25: A-H state 1, W state 9
	PROCESS_LOOP_P INI_W9, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 0
	vmovdqa32	TMP3, [TBL + 64*26]
	MSG_SCHED_ROUND_16_63 INI_W9, INI_W10, INI_W2, INI_W7
	// Round 26: A-H state 2, W state 10
	PROCESS_LOOP_P INI_W10, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 0
	vmovdqa32	TMP3, [TBL + 64*27]
	MSG_SCHED_ROUND_16_63 INI_W10, INI_W11, INI_W3, INI_W8
	// Round 27: A-H state 3, W state 11
	PROCESS_LOOP_P INI_W11, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 0
	vmovdqa32	TMP3, [TBL + 64*28]
	MSG_SCHED_ROUND_16_63 INI_W11, INI_W12, INI_W4, INI_W9
	// Round 28: A-H state 4, W state 12
	PROCESS_LOOP_P INI_W12, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 0
	vmovdqa32	TMP3, [TBL + 64*29]
	MSG_SCHED_ROUND_16_63 INI_W12, INI_W13, INI_W5, INI_W10
	// Round 29: A-H state 5, W state 13
	PROCESS_LOOP_P INI_W13, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 0
	vmovdqa32	TMP3, [TBL + 64*30]
	MSG_SCHED_ROUND_16_63 INI_W13, INI_W14, INI_W6, INI_W11
	// Round 30: A-H state 6, W state 14
	PROCESS_LOOP_P INI_W14, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 0
	vmovdqa32	TMP3, [TBL + 64*31]
	MSG_SCHED_ROUND_16_63 INI_W14, INI_W15, INI_W7, INI_W12
	// Round 31: A-H state 7, W state 15
	PROCESS_LOOP_P INI_W15, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 0
	vmovdqa32	TMP3, [TBL + 64*32]
	MSG_SCHED_ROUND_16_63 INI_W15, INI_W0, INI_W8, INI_W13
	// Round 32: A-H state 0, W state 0
	PROCESS_LOOP_P INI_W0, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 0
	vmovdqa32	TMP3, [TBL + 64*33]
	MSG_SCHED_ROUND_16_63 INI_W0, INI_W1, INI_W9, INI_W14
	// Round 33: A-H state 1, W state 1
	PROCESS_LOOP_P INI_W1, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 0
	vmovdqa32	TMP3, [TBL + 64*34]
	MSG_SCHED_ROUND_16_63 INI_W1, INI_W2, INI_W10, INI_W15
	// Round 34: A-H state 2, W state 2
	PROCESS_LOOP_P INI_W2, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 0
	vmovdqa32	TMP3, [TBL + 64*35]
	MSG_SCHED_ROUND_16_63 INI_W2, INI_W3, INI_W11, INI_W0
	// Round 35: A-H state 3, W state 3
	PROCESS_LOOP_P INI_W3, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 0
	vmovdqa32	TMP3, [TBL + 64*36]
	MSG_SCHED_ROUND_16_63 INI_W3, INI_W4, INI_W12, INI_W1
	// Round 36: A-H state 4, W state 4
	PROCESS_LOOP_P INI_W4, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 0
	vmovdqa32	TMP3, [TBL + 64*37]
	MSG_SCHED_ROUND_16_63 INI_W4, INI_W5, INI_W13, INI_W2
	// Round 37: A-H state 5, W state 5
	PROCESS_LOOP_P INI_W5, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 0
	vmovdqa32	TMP3, [TBL + 64*38]
	MSG_SCHED_ROUND_16_63 INI_W5, INI_W6, INI_W14, INI_W3
	// Round 38: A-H state 6, W state 6
	PROCESS_LOOP_P INI_W6, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 0
	vmovdqa32	TMP3, [TBL + 64*39]
	MSG_SCHED_ROUND_16_63 INI_W6, INI_W7, INI_W15, INI_W4
	// Round 39: A-H state 7, W state 7
	PROCESS_LOOP_P INI_W7, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 0
	vmovdqa32	TMP3, [TBL + 64*40]
	MSG_SCHED_ROUND_16_63 INI_W7, INI_W8, INI_W0, INI_W5
	// Round 40: A-H state 0, W state 8
	PROCESS_LOOP_P INI_W8, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 0
	vmovdqa32	TMP3, [TBL + 64*41]
	MSG_SCHED_ROUND_16_63 INI_W8, INI_W9, INI_W1, INI_W6
	// Round 41: A-H state 1, W state 9
	PROCESS_LOOP_P INI_W9, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 0
	vmovdqa32	TMP3, [TBL + 64*42]
	MSG_SCHED_ROUND_16_63 INI_W9, INI_W10, INI_W2, INI_W7
	// Round 42: A-H state 2, W state 10
	PROCESS_LOOP_P INI_W10, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 0
	vmovdqa32	TMP3, [TBL + 64*43]
	MSG_SCHED_ROUND_16_63 INI_W10, INI_W11, INI_W3, INI_W8
	// Round 43: A-H state 3, W state 11
	PROCESS_LOOP_P INI_W11, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 0
	vmovdqa32	TMP3, [TBL + 64*44]
	MSG_SCHED_ROUND_16_63 INI_W11, INI_W12, INI_W4, INI_W9
	// Round 44: A-H state 4, W state 12
	PROCESS_LOOP_P INI_W12, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 0
	vmovdqa32	TMP3, [TBL + 64*45]
	MSG_SCHED_ROUND_16_63 INI_W12, INI_W13, INI_W5, INI_W10
	// Round 45: A-H state 5, W state 13
	PROCESS_LOOP_P INI_W13, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 0
	vmovdqa32	TMP3, [TBL + 64*46]
	MSG_SCHED_ROUND_16_63 INI_W13, INI_W14, INI_W6, INI_W11
	// Round 46: A-H state 6, W state 14
	PROCESS_LOOP_P INI_W14, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 0
	vmovdqa32	TMP3, [TBL + 64*47]
	MSG_SCHED_ROUND_16_63 INI_W14, INI_W15, INI_W7, INI_W12
	// Round 47: A-H state 7, W state 15
	PROCESS_LOOP_P INI_W15, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 0
	vmovdqa32	TMP3, [TBL + 64*48]
	MSG_SCHED_ROUND_16_63 INI_W15, INI_W0, INI_W8, INI_W13

	// Rounds 48-63: PROCESS_LOOP only (no message schedule)
	// Round 48: A-H state 0, W state 0
	PROCESS_LOOP_P INI_W0, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 0
	vmovdqa32	TMP3, [TBL + 64*49]
	// Round 49: A-H state 1, W state 1
	PROCESS_LOOP_P INI_W1, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 0
	vmovdqa32	TMP3, [TBL + 64*50]
	// Round 50: A-H state 2, W state 2
	PROCESS_LOOP_P INI_W2, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 0
	vmovdqa32	TMP3, [TBL + 64*51]
	// Round 51: A-H state 3, W state 3
	PROCESS_LOOP_P INI_W3, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 0
	vmovdqa32	TMP3, [TBL + 64*52]
	// Round 52: A-H state 4, W state 4
	PROCESS_LOOP_P INI_W4, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 0
	vmovdqa32	TMP3, [TBL + 64*53]
	// Round 53: A-H state 5, W state 5
	PROCESS_LOOP_P INI_W5, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 0
	vmovdqa32	TMP3, [TBL + 64*54]
	// Round 54: A-H state 6, W state 6
	PROCESS_LOOP_P INI_W6, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 0
	vmovdqa32	TMP3, [TBL + 64*55]
	// Round 55: A-H state 7, W state 7
	PROCESS_LOOP_P INI_W7, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 0
	vmovdqa32	TMP3, [TBL + 64*56]
	// Round 56: A-H state 0, W state 8
	PROCESS_LOOP_P INI_W8, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 0
	vmovdqa32	TMP3, [TBL + 64*57]
	// Round 57: A-H state 1, W state 9
	PROCESS_LOOP_P INI_W9, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 0
	vmovdqa32	TMP3, [TBL + 64*58]
	// Round 58: A-H state 2, W state 10
	PROCESS_LOOP_P INI_W10, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 0
	vmovdqa32	TMP3, [TBL + 64*59]
	// Round 59: A-H state 3, W state 11
	PROCESS_LOOP_P INI_W11, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 0
	vmovdqa32	TMP3, [TBL + 64*60]
	// Round 60: A-H state 4, W state 12
	PROCESS_LOOP_P INI_W12, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 0
	vmovdqa32	TMP3, [TBL + 64*61]
	// Round 61: A-H state 5, W state 13
	PROCESS_LOOP_P INI_W13, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 0
	vmovdqa32	TMP3, [TBL + 64*62]
	// Round 62: A-H state 6, W state 14
	PROCESS_LOOP_P INI_W14, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 0
	vmovdqa32	TMP3, [TBL + 64*63]
	// Round 63: A-H state 7, W state 15
	PROCESS_LOOP_P INI_W15, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 0

	# Add old digest
	vpaddd		A, A, [DIGEST + 0*64]
	vpaddd		B, B, [DIGEST + 1*64]
	vpaddd		C, C, [DIGEST + 2*64]
	vpaddd		D, D, [DIGEST + 3*64]
	vpaddd		E, E, [DIGEST + 4*64]
	vpaddd		F, F, [DIGEST + 5*64]
	vpaddd		G, G, [DIGEST + 6*64]
	vpaddd		H, H, [DIGEST + 7*64]
	
	# Save digest for later processing
	vmovdqa32	W0, A
	vmovdqa32	W1, B
	vmovdqa32	W2, C
	vmovdqa32	W3, D
	vmovdqa32	W4, E
	vmovdqa32	W5, F
	vmovdqa32	W6, G
	vmovdqa32	W7, H

	# Load transposing masks
	vmovdqa32	TMP5, [rip + .LPSHUFFLE_TRANSPOSE_MASK3]
	vmovdqa32	TMP6, [rip + .LPSHUFFLE_TRANSPOSE_MASK4]

	# Rounds with padding (64 rounds, manually unrolled)
	# Round 0: A=INI_A, B=INI_B, C=INI_C, D=INI_D, E=INI_E, F=INI_F, G=INI_G, H=INI_H
	vmovdqa32	TMP4, [PADDING + 64*0]
	PROCESS_LOOP_P TMP4, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 1
	# Round 1: A=INI_H, B=INI_A, C=INI_B, D=INI_C, E=INI_D, F=INI_E, G=INI_F, H=INI_G
	vmovdqa32	TMP4, [PADDING + 64*1]
	PROCESS_LOOP_P TMP4, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 1
	# Round 2: A=INI_G, B=INI_H, C=INI_A, D=INI_B, E=INI_C, F=INI_D, G=INI_E, H=INI_F
	vmovdqa32	TMP4, [PADDING + 64*2]
	PROCESS_LOOP_P TMP4, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 1
	# Round 3: A=INI_F, B=INI_G, C=INI_H, D=INI_A, E=INI_B, F=INI_C, G=INI_D, H=INI_E
	vmovdqa32	TMP4, [PADDING + 64*3]
	PROCESS_LOOP_P TMP4, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 1
	# Round 4: A=INI_E, B=INI_F, C=INI_G, D=INI_H, E=INI_A, F=INI_B, G=INI_C, H=INI_D
	vmovdqa32	TMP4, [PADDING + 64*4]
	PROCESS_LOOP_P TMP4, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 1
	# Round 5: A=INI_D, B=INI_E, C=INI_F, D=INI_G, E=INI_H, F=INI_A, G=INI_B, H=INI_C
	vmovdqa32	TMP4, [PADDING + 64*5]
	PROCESS_LOOP_P TMP4, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 1
	# Round 6: A=INI_C, B=INI_D, C=INI_E, D=INI_F, E=INI_G, F=INI_H, G=INI_A, H=INI_B
	vmovdqa32	TMP4, [PADDING + 64*6]
	PROCESS_LOOP_P TMP4, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 1
	# Round 7: A=INI_B, B=INI_C, C=INI_D, D=INI_E, E=INI_F, F=INI_G, G=INI_H, H=INI_A
	vmovdqa32	TMP4, [PADDING + 64*7]
	PROCESS_LOOP_P TMP4, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 1
	# Round 8: A=INI_A, B=INI_B, C=INI_C, D=INI_D, E=INI_E, F=INI_F, G=INI_G, H=INI_H
	vmovdqa32	TMP4, [PADDING + 64*8]
	PROCESS_LOOP_P TMP4, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 1
	# Round 9
	vmovdqa32	TMP4, [PADDING + 64*9]
	PROCESS_LOOP_P TMP4, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 1
	# Round 10
	vmovdqa32	TMP4, [PADDING + 64*10]
	PROCESS_LOOP_P TMP4, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 1
	# Round 11
	vmovdqa32	TMP4, [PADDING + 64*11]
	PROCESS_LOOP_P TMP4, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 1
	# Round 12
	vmovdqa32	TMP4, [PADDING + 64*12]
	PROCESS_LOOP_P TMP4, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 1
	# Round 13
	vmovdqa32	TMP4, [PADDING + 64*13]
	PROCESS_LOOP_P TMP4, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 1
	# Round 14
	vmovdqa32	TMP4, [PADDING + 64*14]
	PROCESS_LOOP_P TMP4, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 1
	# Round 15
	vmovdqa32	TMP4, [PADDING + 64*15]
	PROCESS_LOOP_P TMP4, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 1
	# Round 16
	vmovdqa32	TMP4, [PADDING + 64*16]
	PROCESS_LOOP_P TMP4, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 1
	# Round 17
	vmovdqa32	TMP4, [PADDING + 64*17]
	PROCESS_LOOP_P TMP4, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 1
	# Round 18
	vmovdqa32	TMP4, [PADDING + 64*18]
	PROCESS_LOOP_P TMP4, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 1
	# Round 19
	vmovdqa32	TMP4, [PADDING + 64*19]
	PROCESS_LOOP_P TMP4, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 1
	# Round 20
	vmovdqa32	TMP4, [PADDING + 64*20]
	PROCESS_LOOP_P TMP4, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 1
	# Round 21
	vmovdqa32	TMP4, [PADDING + 64*21]
	PROCESS_LOOP_P TMP4, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 1
	# Round 22
	vmovdqa32	TMP4, [PADDING + 64*22]
	PROCESS_LOOP_P TMP4, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 1
	# Round 23
	vmovdqa32	TMP4, [PADDING + 64*23]
	PROCESS_LOOP_P TMP4, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 1
	# Round 24
	vmovdqa32	TMP4, [PADDING + 64*24]
	PROCESS_LOOP_P TMP4, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 1
	# Round 25
	vmovdqa32	TMP4, [PADDING + 64*25]
	PROCESS_LOOP_P TMP4, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 1
	# Round 26
	vmovdqa32	TMP4, [PADDING + 64*26]
	PROCESS_LOOP_P TMP4, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 1
	# Round 27
	vmovdqa32	TMP4, [PADDING + 64*27]
	PROCESS_LOOP_P TMP4, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 1
	# Round 28
	vmovdqa32	TMP4, [PADDING + 64*28]
	PROCESS_LOOP_P TMP4, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 1
	# Round 29
	vmovdqa32	TMP4, [PADDING + 64*29]
	PROCESS_LOOP_P TMP4, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 1
	# Round 30
	vmovdqa32	TMP4, [PADDING + 64*30]
	PROCESS_LOOP_P TMP4, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 1
	# Round 31
	vmovdqa32	TMP4, [PADDING + 64*31]
	PROCESS_LOOP_P TMP4, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 1
	# Round 32
	vmovdqa32	TMP4, [PADDING + 64*32]
	PROCESS_LOOP_P TMP4, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 1
	# Round 33
	vmovdqa32	TMP4, [PADDING + 64*33]
	PROCESS_LOOP_P TMP4, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 1
	# Round 34
	vmovdqa32	TMP4, [PADDING + 64*34]
	PROCESS_LOOP_P TMP4, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 1
	# Round 35
	vmovdqa32	TMP4, [PADDING + 64*35]
	PROCESS_LOOP_P TMP4, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 1
	# Round 36
	vmovdqa32	TMP4, [PADDING + 64*36]
	PROCESS_LOOP_P TMP4, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 1
	# Round 37
	vmovdqa32	TMP4, [PADDING + 64*37]
	PROCESS_LOOP_P TMP4, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 1
	# Round 38
	vmovdqa32	TMP4, [PADDING + 64*38]
	PROCESS_LOOP_P TMP4, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 1
	# Round 39
	vmovdqa32	TMP4, [PADDING + 64*39]
	PROCESS_LOOP_P TMP4, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 1
	# Round 40
	vmovdqa32	TMP4, [PADDING + 64*40]
	PROCESS_LOOP_P TMP4, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 1
	# Round 41
	vmovdqa32	TMP4, [PADDING + 64*41]
	PROCESS_LOOP_P TMP4, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 1
	# Round 42
	vmovdqa32	TMP4, [PADDING + 64*42]
	PROCESS_LOOP_P TMP4, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 1
	# Round 43
	vmovdqa32	TMP4, [PADDING + 64*43]
	PROCESS_LOOP_P TMP4, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 1
	# Round 44
	vmovdqa32	TMP4, [PADDING + 64*44]
	PROCESS_LOOP_P TMP4, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 1
	# Round 45
	vmovdqa32	TMP4, [PADDING + 64*45]
	PROCESS_LOOP_P TMP4, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 1
	# Round 46
	vmovdqa32	TMP4, [PADDING + 64*46]
	PROCESS_LOOP_P TMP4, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 1
	# Round 47
	vmovdqa32	TMP4, [PADDING + 64*47]
	PROCESS_LOOP_P TMP4, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 1
	# Round 48
	vmovdqa32	TMP4, [PADDING + 64*48]
	PROCESS_LOOP_P TMP4, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 1
	# Round 49
	vmovdqa32	TMP4, [PADDING + 64*49]
	PROCESS_LOOP_P TMP4, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 1
	# Round 50
	vmovdqa32	TMP4, [PADDING + 64*50]
	PROCESS_LOOP_P TMP4, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 1
	# Round 51
	vmovdqa32	TMP4, [PADDING + 64*51]
	PROCESS_LOOP_P TMP4, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 1
	# Round 52
	vmovdqa32	TMP4, [PADDING + 64*52]
	PROCESS_LOOP_P TMP4, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 1
	# Round 53
	vmovdqa32	TMP4, [PADDING + 64*53]
	PROCESS_LOOP_P TMP4, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 1
	# Round 54
	vmovdqa32	TMP4, [PADDING + 64*54]
	PROCESS_LOOP_P TMP4, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 1
	# Round 55
	vmovdqa32	TMP4, [PADDING + 64*55]
	PROCESS_LOOP_P TMP4, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 1
	# Round 56
	vmovdqa32	TMP4, [PADDING + 64*56]
	PROCESS_LOOP_P TMP4, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, 1
	# Round 57
	vmovdqa32	TMP4, [PADDING + 64*57]
	PROCESS_LOOP_P TMP4, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, 1
	# Round 58
	vmovdqa32	TMP4, [PADDING + 64*58]
	PROCESS_LOOP_P TMP4, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, INI_F, 1
	# Round 59
	vmovdqa32	TMP4, [PADDING + 64*59]
	PROCESS_LOOP_P TMP4, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, INI_E, 1
	# Round 60
	vmovdqa32	TMP4, [PADDING + 64*60]
	PROCESS_LOOP_P TMP4, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, INI_D, 1
	# Round 61
	vmovdqa32	TMP4, [PADDING + 64*61]
	PROCESS_LOOP_P TMP4, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, INI_C, 1
	# Round 62
	vmovdqa32	TMP4, [PADDING + 64*62]
	PROCESS_LOOP_P TMP4, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, INI_B, 1
	# Round 63
	vmovdqa32	TMP4, [PADDING + 64*63]
	PROCESS_LOOP_P TMP4, INI_B, INI_C, INI_D, INI_E, INI_F, INI_G, INI_H, INI_A, 1
	vmovdqa32	W8, [rip + .LPSHUFFLE_BYTE_FLIP_MASK]

	# Add old digest
	vpaddd		A, A, W0
	vpaddd		B, B, W1
	vpaddd		C, C, W2
	vpaddd		D, D, W3
	vpaddd		E, E, W4
	vpaddd		F, F, W5
	vpaddd		G, G, W6
	vpaddd		H, H, W7

	# Transpose, output and loop
	TRANSPOSE_8x16_U32 A, B, C, D, E, F, G, H,\
		TMP0, TMP1, TMP2, TMP3, TMP5, TMP6

	# Byte swap all 8 registers (unrolled from .rept 8 with ROTATE_ARGS)
	vpshufb	INI_A, INI_A, W8
	vpshufb	INI_H, INI_H, W8
	vpshufb	INI_G, INI_G, W8
	vpshufb	INI_F, INI_F, W8
	vpshufb	INI_E, INI_E, W8
	vpshufb	INI_D, INI_D, W8
	vpshufb	INI_C, INI_C, W8
	vpshufb	INI_B, INI_B, W8

	vmovdqu32 	[OUTPUT_PTR + 0*64], A
	vmovdqu32 	[OUTPUT_PTR + 1*64], B
	vmovdqu32 	[OUTPUT_PTR + 2*64], C
	vmovdqu32 	[OUTPUT_PTR + 3*64], D
	vmovdqu32 	[OUTPUT_PTR + 4*64], E
	vmovdqu32 	[OUTPUT_PTR + 5*64], F
	vmovdqu32 	[OUTPUT_PTR + 6*64], G
	vmovdqu32 	[OUTPUT_PTR + 7*64], H

	add		OUTPUT_PTR, 8*64
	add		DATA_PTR, 16*64
	sub		COUNT, 16
	jmp		.Lsha256_16_avx512loop

#ifdef __linux__ 
.size hashtree_sha256_avx512_x16,.-hashtree_sha256_avx512_x16
.section .note.GNU-stack,"",@progbits
#endif
	
#endif
