/*
MIT License

Copyright (c) 2021-2026 Prysmatic Labs

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
#   void sha256_armv8_neon_x1( unsigned char *output, unsigned char *input, size_t count)
#
#   armv8-a implementation with Neon but no crypto extensions
#   as in the Cortex A-72 of a Raspberry-Pi 4.b
#
#   It reads four blocks at a time, and schedules 4 words at the same time using ASIMD instructions
#   There are no bound checks, caller is responsible to check that memory up to output + 32*count
#   is writable.
#
########################################################################################################

#ifdef __aarch64__
.text
.arch armv8-a

output		    .req x0
input		    .req x1
count		    .req x2
last		    .req x2

digest		    .req x3
k256		    .req x4
padding		    .req x5
digest2             .req x6
post64              .req x7
postminus176        .req x9
post32              .req x10
postminus80         .req x11

A_		    .req v0
B_		    .req v1
C_		    .req v2
D_		    .req v3
E_		    .req v4
F_		    .req v5
G_		    .req v6
H_		    .req v7

M1		    .req v16
M2		    .req v17
M3		    .req v18
M4		    .req v19
MQ1                 .req q16
MQ2                 .req q17
MQ3                 .req q18
MQ4                 .req q19

VR1		    .req v24
VR2		    .req v25
VR3		    .req v26
VR4		    .req v27
QR2		    .req q25
QR4		    .req q27
T1		    .req v28
T2		    .req v29
T3		    .req v30
T4		    .req v31
T5		    .req v20
T6                  .req v21
T7		    .req v22
T8		    .req v23
TQ4		    .req q31
TQ5		    .req q20
TQ6                 .req q21
TQ7		    .req q22


############################################################################
# round computes one round, 4 lanes at a time. Constants are read from k256,
# one message word is consumed from MW and saved to sp transposed this macro
# adds 16 to sp. offset has to be set to 0 on the first round
############################################################################
.macro round                  A, B, C, D, E, F, G, H, MV, MQ
                    ushr                T1.4s, \E\().4s, #6
                    shl                 T2.4s, \E\().4s, #(32-6)
                    ushr                VR2.4s, \E\().4s, #11
                    shl                 VR1.4s, \E\().4s, #(32-11)
                    and                 T3.16b, \E\().16b, \F\().16b
                    bic                 T4.16b, \G\().16b, \E\().16b
                    orr                 T1.16b, T1.16b, T2.16b  // ROTR^6(E)
                    ushr                T2.4s, \E\().4s, #25
                    ldr                 QR4, [k256, #.Loffset]
                    shl                 VR3.4s, \E\().4s, #(32-25)
                    orr                 VR1.16b, VR2.16b, VR1.16b // ROTR^11(E)
                    eor                 T3.16b, T3.16b, T4.16b  // CH(E,F,G)
                    orr                 T2.16b, T2.16b, VR3.16b // ROTR^25(E)
                    eor                 VR3.16b, \A\().16b, \C\().16b
                    eor                 T1.16b, T1.16b, VR1.16b
                    add                 T4.4s, \MV\().4s, VR4.4s // W + K
                    add                 \H\().4s, \H\().4s, T3.4s
                    ushr                T3.4s, \A\().4s, #2
                    and                 VR3.16b, VR3.16b, \B\().16b
                    shl                 VR4.4s, \A\().4s, #(32-2)
                    eor                 T1.16b, T1.16b, T2.16b // Sigma1
                    ushr                T2.4s, \A\().4s, #13
                    shl                 VR1.4s, \A\().4s, #(32-13)
                    add                 \H\().4s, \H\().4s, T4.4s
                    orr                 T3.16b, T3.16b, VR4.16b // ROTR^2(A)
                    and                 VR4.16b, \A\().16b, \C\().16b
                    ushr                T4.4s, \A\().4s, #22
                    shl                 VR2.4s, \A\().4s, #(32 - 22)
                    orr                 T2.16b, T2.16b, VR1.16b     // ROTR^13(A)
                    add                 \H\().4s, \H\().4s, T1.4s
                    eor                 VR3.16b, VR3.16b, VR4.16b   // MAJ(A,B,C)
                    orr                 T4.16b, T4.16b, VR2.16b     // ROTR^22(A)
                    eor                 T2.16b, T2.16b, T3.16b
                    add                 \D\().4s, \D\().4s, \H\().4s
                    add                 \H\().4s, \H\().4s, VR3.4s
                    eor                 T2.16b, T2.16b, T4.16b     // Sigma0
                    str                 \MQ, [sp, #.Loffset]
                    add                 \H\().4s, \H\().4s, T2.4s 
.set                .Loffset, .Loffset + 16
.endm  
.macro four_rounds                      A, B, C, D, E, F, G, H, MV1, MV2, MV3, MV4, MQ1, MQ2, MQ3, MQ4
                    round               \A, \B, \C, \D, \E, \F, \G, \H, \MV1, \MQ1
                    round               \H, \A, \B, \C, \D, \E, \F, \G, \MV2, \MQ2
                    round               \G, \H, \A, \B, \C, \D, \E, \F, \MV3, \MQ3
                    round               \F, \G, \H, \A, \B, \C, \D, \E, \MV4, \MQ4
.endm
                    
##################################################################################
# round_and_sched performs one round and schedules one word, 4 lanes at a time
# reads previous scheduled words from sp,  constants from k256
#
#
##################################################################################
.macro round_and_sched                  A, B, C, D, E, F, G, H
                        ldp             TQ6, TQ5, [sp, #(.Loffset-256)]     // W16, W15
                    ushr                T1.4s, \E\().4s, #6
                    shl                 T2.4s, \E\().4s, #(32-6)
                    ushr                VR2.4s, \E\().4s, #11
                    shl                 VR1.4s, \E\().4s, #(32-11)
                    and                 T3.16b, \E\().16b, \F\().16b
                    bic                 T4.16b, \G\().16b, \E\().16b
                        ushr            M1.4s, T5.4s, #7
                        ldr             TQ7, [sp, #(.Loffset - 32)]         // W2
                        shl             M2.4s, T5.4s, #(32-7)
                    orr                 T1.16b, T1.16b, T2.16b  // ROTR^6(E)
                    ushr                T2.4s, \E\().4s, #25
                    shl                 VR3.4s, \E\().4s, #(32-25)
                    orr                 VR1.16b, VR2.16b, VR1.16b // ROTR^11(E)
                    eor                 T3.16b, T3.16b, T4.16b  // CH(E,F,G)
                    ldr                 QR4, [k256, #.Loffset]

                       orr              M1.16b, M1.16b, M2.16b  // ROTR7(W15)
                       ushr             M3.4s, T7.4s, #17
                       shl              M4.4s, T7.4s, #(32-17)
                       ushr             M2.4s, T5.4s, #18
                       shl              T8.4s, T5.4s, #(32-18)

                    orr                 T2.16b, T2.16b, VR3.16b // ROTR^25(E)
                    eor                 VR3.16b, \A\().16b, \C\().16b
                        orr             M3.16b, M3.16b, M4.16b  // ROTR^17(W2)
                        ldr             TQ4, [sp, #(.Loffset - 112)]        // W7
                        ushr            M4.4s, T7.4s, #19
                        shl             VR2.4s, T7.4s, #(32-19) 
                        orr             M2.16b, M2.16b, T8.16b // ROTR^18(W15)
                        ushr            T8.4s, T5.4s, #3
                        orr             M4.16b, M4.16b, VR2.16b // ROTR^19(W2)
                         
                    eor                 T1.16b, T1.16b, VR1.16b
                        eor             M1.16b, M1.16b, M2.16b
                        ushr            M2.4s, T7.4s, #10
                        eor             M3.16b, M3.16b, M4.16b 
                    add                 \H\().4s, \H\().4s, T3.4s
                        eor             M1.16b, M1.16b, T8.16b // sigma0
                        add             T6.4s, T6.4s, T4.4s    // W7 + W16
                        eor             M3.16b, M3.16b, M2.16b // sigma1
                        

                    ushr                T3.4s, \A\().4s, #2
                    and                 VR3.16b, VR3.16b, \B\().16b
                        add             M1.4s, M1.4s, T6.4s
                    shl                 T6.4s, \A\().4s, #(32-2)
                    eor                 T1.16b, T1.16b, T2.16b // Sigma1
                    ushr                T2.4s, \A\().4s, #13
                        add             M1.4s, M1.4s, M3.4s    // W0
                    add                 \H\().4s, \H\().4s, T1.4s
                    shl                 VR1.4s, \A\().4s, #(32-13)
                    orr                 T3.16b, T3.16b, T6.16b // ROTR^2(A)
                    add                 T5.4s, M1.4s, VR4.4s // W + K
                        str             MQ1, [sp, #.Loffset]
                    and                 VR4.16b, \A\().16b, \C\().16b
                    ushr                T4.4s, \A\().4s, #22
                    shl                 VR2.4s, \A\().4s, #(32 - 22)
                    add                 \H\().4s, \H\().4s, T5.4s
                    orr                 T2.16b, T2.16b, VR1.16b     // ROTR^13(A)
                    eor                 VR3.16b, VR3.16b, VR4.16b   // MAJ(A,B,C)
                    orr                 T4.16b, T4.16b, VR2.16b     // ROTR^22(A)
                    eor                 T2.16b, T2.16b, T3.16b
                    add                 \D\().4s, \D\().4s, \H\().4s
                    add                 \H\().4s, \H\().4s, VR3.4s
                    eor                 T2.16b, T2.16b, T4.16b     // Sigma0
                    add                 \H\().4s, \H\().4s, T2.4s 
.set                .Loffset, .Loffset + 16
.endm  
.macro four_rounds_and_sched             A, B, C, D, E, F, G, H
                    round_and_sched      \A, \B, \C, \D, \E, \F, \G, \H
                    round_and_sched      \H, \A, \B, \C, \D, \E, \F, \G
                    round_and_sched      \G, \H, \A, \B, \C, \D, \E, \F
                    round_and_sched      \F, \G, \H, \A, \B, \C, \D, \E
.endm

##########################################################################
# performs one round reading the precomputed words from padding
##########################################################################
.macro round_padding                    A, B, C, D, E, F, G, H
                    ushr                T1.4s, \E\().4s, #6
                    shl                 T2.4s, \E\().4s, #(32-6)
                    ushr                VR2.4s, \E\().4s, #11
                    shl                 VR1.4s, \E\().4s, #(32-11)
                    and                 T3.16b, \E\().16b, \F\().16b
                    bic                 T4.16b, \G\().16b, \E\().16b
                    orr                 T1.16b, T1.16b, T2.16b  // ROTR^6(E)
                    ushr                T2.4s, \E\().4s, #25
                    shl                 VR3.4s, \E\().4s, #(32-25)
                    orr                 VR1.16b, VR2.16b, VR1.16b // ROTR^11(E)
                    eor                 T3.16b, T3.16b, T4.16b  // CH(E,F,G)
                    orr                 T2.16b, T2.16b, VR3.16b // ROTR^25(E)
                    eor                 VR3.16b, \A\().16b, \C\().16b
                    eor                 T1.16b, T1.16b, VR1.16b
                    add                 \H\().4s, \H\().4s, T3.4s
                    ushr                T3.4s, \A\().4s, #2
                    ldr                 QR2, [padding, #.Loffset]
                    and                 VR3.16b, VR3.16b, \B\().16b
                    shl                 VR4.4s, \A\().4s, #(32-2)
                    eor                 T1.16b, T1.16b, T2.16b // Sigma1
                    ushr                T2.4s, \A\().4s, #13
                    shl                 VR1.4s, \A\().4s, #(32-13)
                    add                 \H\().4s, \H\().4s, VR2.4s
                    orr                 T3.16b, T3.16b, VR4.16b // ROTR^2(A)
                    and                 VR4.16b, \A\().16b, \C\().16b
                    ushr                T4.4s, \A\().4s, #22
                    shl                 VR2.4s, \A\().4s, #(32 - 22)
                    orr                 T2.16b, T2.16b, VR1.16b     // ROTR^13(A)
                    add                 \H\().4s, \H\().4s, T1.4s
                    eor                 VR3.16b, VR3.16b, VR4.16b   // MAJ(A,B,C)
                    orr                 T4.16b, T4.16b, VR2.16b     // ROTR^22(A)
                    eor                 T2.16b, T2.16b, T3.16b
                    add                 \D\().4s, \D\().4s, \H\().4s
                    add                 \H\().4s, \H\().4s, VR3.4s
                    eor                 T2.16b, T2.16b, T4.16b     // Sigma0
                    add                 \H\().4s, \H\().4s, T2.4s 
.set                .Loffset, .Loffset + 16
.endm  
.macro four_rounds_padding          A, B, C, D, E, F, G, H
                    round_padding   \A, \B, \C, \D, \E, \F, \G, \H
                    round_padding   \H, \A, \B, \C, \D, \E, \F, \G
                    round_padding   \G, \H, \A, \B, \C, \D, \E, \F
                    round_padding   \F, \G, \H, \A, \B, \C, \D, \E
.endm
 
#ifdef __APPLE__
.global _hashtree_sha256_neon_x4
#else
.global hashtree_sha256_neon_x4
#endif
#ifdef __APPLE__
//.type   hashtree_sha256_neon_x4,%function
#else
.type   hashtree_sha256_neon_x4,%function
#endif

.align 5
#ifdef __APPLE__
_hashtree_sha256_neon_x4:
#else
hashtree_sha256_neon_x4:
#endif
                    sub                 sp, sp, #1024

#ifdef __APPLE__
		    adrp		k256,.LK256x4@GOTPAGE
		    ldr			k256, [k256, .LK256x4@GOTPAGEOFF]
		    adrp		padding, .LPADDINGx4@GOTPAGE
		    ldr			padding, [padding, .LPADDINGx4@GOTPAGEOFF]
		    adrp		digest, .LDIGESTx4L@GOTPAGE
		    ldr			digest, [digest, .LDIGESTx4L@GOTPAGEOFF]
		    adrp		digest2, .LDIGESTx4H@GOTPAGE
		    ldr			digest2, [digest2, .LDIGESTx4H@GOTPAGEOFF]
#else
		    adrp		k256,.LK256x4
		    add			k256, k256, #:lo12:.LK256x4
		    adrp		padding, .LPADDINGx4
		    add			padding, padding, #:lo12:.LPADDINGx4
		    adrp		digest, .LDIGESTx4L
		    add			digest, digest, #:lo12:.LDIGESTx4L
		    adrp		digest2, .LDIGESTx4H
		    add			digest2, digest2, #:lo12:.LDIGESTx4H
#endif
                    mov                 post64, #64
                    mov                 post32, #32
                    mov                 postminus80, #-80
                    mov                 postminus176, #-176
.Larmv8_neon_x4_loop:
		    cmp			count, 4
		    b.lo		.Lsha256_armv8_x4_epilog
                    ld1                 {A_.4s, B_.4s, C_.4s, D_.4s}, [digest]
                    ld1                 {E_.4s, F_.4s, G_.4s, H_.4s}, [digest2] // stall 8 cycles

.set                .Loffset, 0
.rept 2
		    ld4			{M1.s, M2.s, M3.s, M4.s}[0], [input], post64
		    ld4			{M1.s, M2.s, M3.s, M4.s}[1], [input], post64
		    ld4			{M1.s, M2.s, M3.s, M4.s}[2], [input], post64
		    ld4			{M1.s, M2.s, M3.s, M4.s}[3], [input], postminus176

		    rev32		M1.16b, M1.16b
		    rev32		M2.16b, M2.16b
		    rev32		M3.16b, M3.16b
		    rev32		M4.16b, M4.16b

                    four_rounds         A_, B_, C_, D_, E_, F_, G_, H_, M1, M2, M3, M4, MQ1, MQ2, MQ3, MQ4

       		    ld4			{M1.s, M2.s, M3.s, M4.s}[0], [input], post64
		    ld4			{M1.s, M2.s, M3.s, M4.s}[1], [input], post64
		    ld4			{M1.s, M2.s, M3.s, M4.s}[2], [input], post64
		    ld4			{M1.s, M2.s, M3.s, M4.s}[3], [input], postminus176
     
		    rev32		M1.16b, M1.16b
		    rev32		M2.16b, M2.16b
		    rev32		M3.16b, M3.16b
		    rev32		M4.16b, M4.16b

                    four_rounds         E_, F_, G_, H_, A_, B_, C_, D_, M1, M2, M3, M4, MQ1, MQ2, MQ3, MQ4
.endr
.rept 6
                    four_rounds_and_sched A_, B_, C_, D_, E_, F_, G_, H_ 
                    four_rounds_and_sched E_, F_, G_, H_, A_, B_, C_, D_
.endr

# add previous digest
                    ld1                 {M1.4s, M2.4s, M3.4s, M4.4s}, [digest]
                    ld1                 {T5.4s, T6.4s, T7.4s, T8.4s}, [digest2] // stall 8 cycles
                    add                 A_.4s, A_.4s, M1.4s
                    add                 B_.4s, B_.4s, M2.4s
                    add                 C_.4s, C_.4s, M3.4s
                    add                 D_.4s, D_.4s, M4.4s
                    add                 E_.4s, E_.4s, T5.4s
                    add                 F_.4s, F_.4s, T6.4s
                    add                 G_.4s, G_.4s, T7.4s
                    add                 H_.4s, H_.4s, T8.4s

                    
# save state
                    mov                 M1.16b, A_.16b
                    mov                 M2.16b, B_.16b
                    mov                 M3.16b, C_.16b
                    mov                 M4.16b, D_.16b
                    mov                 T5.16b, E_.16b
                    mov                 T6.16b, F_.16b
                    mov                 T7.16b, G_.16b
                    mov                 T8.16b, H_.16b

# rounds with padding
.set .Loffset, 0
.rept 8
                    four_rounds_padding A_, B_, C_, D_, E_, F_, G_, H_ 
                    four_rounds_padding E_, F_, G_, H_, A_, B_, C_, D_
.endr

#add previous digest
                    add                 A_.4s, A_.4s, M1.4s
                    add                 B_.4s, B_.4s, M2.4s
                    add                 C_.4s, C_.4s, M3.4s
                    add                 D_.4s, D_.4s, M4.4s
                    add                 E_.4s, E_.4s, T5.4s
                    add                 F_.4s, F_.4s, T6.4s
                    add                 G_.4s, G_.4s, T7.4s
                    add                 H_.4s, H_.4s, T8.4s
#change endianness transpose and store
                    rev32               A_.16b, A_.16b
                    rev32               B_.16b, B_.16b
                    rev32               C_.16b, C_.16b
                    rev32               D_.16b, D_.16b
                    rev32               E_.16b, E_.16b
                    rev32               F_.16b, F_.16b
                    rev32               G_.16b, G_.16b
                    rev32               H_.16b, H_.16b
                   
                    st4                 {A_.s, B_.s, C_.s, D_.s}[0], [output], post32
                    st4                 {A_.s, B_.s, C_.s, D_.s}[1], [output], post32
                    st4                 {A_.s, B_.s, C_.s, D_.s}[2], [output], post32
                    st4                 {A_.s, B_.s, C_.s, D_.s}[3], [output], postminus80
                    st4                 {E_.s, F_.s, G_.s, H_.s}[0], [output], post32
                    st4                 {E_.s, F_.s, G_.s, H_.s}[1], [output], post32
                    st4                 {E_.s, F_.s, G_.s, H_.s}[2], [output], post32
                    st4                 {E_.s, F_.s, G_.s, H_.s}[3], [output], #16
                    add                 input, input, #192
                    sub                 count, count, #4 
                    b                   .Larmv8_neon_x4_loop                   
.Lsha256_armv8_x4_epilog:
                    add                 sp, sp, #1024
#ifdef __APPLE__
		    b			_hashtree_sha256_neon_x1
#else
		    b			hashtree_sha256_neon_x1
#endif
#ifdef __APPLE__
.const
#else
.section .rodata,"a"
#endif
.align 4
.LDIGESTx4L:
.word		    0x6a09e667, 0x6a09e667, 0x6a09e667, 0x6a09e667,\
		    0xbb67ae85, 0xbb67ae85, 0xbb67ae85, 0xbb67ae85,\
		    0x3c6ef372, 0x3c6ef372, 0x3c6ef372, 0x3c6ef372,\
		    0xa54ff53a, 0xa54ff53a, 0xa54ff53a, 0xa54ff53a
.LDIGESTx4H:
.word		    0x510e527f, 0x510e527f, 0x510e527f, 0x510e527f,\
		    0x9b05688c, 0x9b05688c, 0x9b05688c, 0x9b05688c,\
		    0x1f83d9ab, 0x1f83d9ab, 0x1f83d9ab, 0x1f83d9ab,\
		    0x5be0cd19, 0x5be0cd19, 0x5be0cd19, 0x5be0cd19
.LK256x4:
.word		    0x428a2f98, 0x428a2f98, 0x428a2f98, 0x428a2f98,\
		    0x71374491, 0x71374491, 0x71374491, 0x71374491,\
		    0xb5c0fbcf, 0xb5c0fbcf, 0xb5c0fbcf, 0xb5c0fbcf,\
		    0xe9b5dba5, 0xe9b5dba5, 0xe9b5dba5, 0xe9b5dba5,\
		    0x3956c25b, 0x3956c25b, 0x3956c25b, 0x3956c25b,\
		    0x59f111f1, 0x59f111f1, 0x59f111f1, 0x59f111f1,\
		    0x923f82a4, 0x923f82a4, 0x923f82a4, 0x923f82a4,\
		    0xab1c5ed5, 0xab1c5ed5, 0xab1c5ed5, 0xab1c5ed5,\
		    0xd807aa98, 0xd807aa98, 0xd807aa98, 0xd807aa98,\
		    0x12835b01, 0x12835b01, 0x12835b01, 0x12835b01,\
		    0x243185be, 0x243185be, 0x243185be, 0x243185be,\
		    0x550c7dc3, 0x550c7dc3, 0x550c7dc3, 0x550c7dc3,\
		    0x72be5d74, 0x72be5d74, 0x72be5d74, 0x72be5d74,\
		    0x80deb1fe, 0x80deb1fe, 0x80deb1fe, 0x80deb1fe,\
		    0x9bdc06a7, 0x9bdc06a7, 0x9bdc06a7, 0x9bdc06a7,\
		    0xc19bf174, 0xc19bf174, 0xc19bf174, 0xc19bf174,\
		    0xe49b69c1, 0xe49b69c1, 0xe49b69c1, 0xe49b69c1,\
		    0xefbe4786, 0xefbe4786, 0xefbe4786, 0xefbe4786,\
		    0x0fc19dc6, 0x0fc19dc6, 0x0fc19dc6, 0x0fc19dc6,\
		    0x240ca1cc, 0x240ca1cc, 0x240ca1cc, 0x240ca1cc,\
		    0x2de92c6f, 0x2de92c6f, 0x2de92c6f, 0x2de92c6f,\
		    0x4a7484aa, 0x4a7484aa, 0x4a7484aa, 0x4a7484aa,\
		    0x5cb0a9dc, 0x5cb0a9dc, 0x5cb0a9dc, 0x5cb0a9dc,\
		    0x76f988da, 0x76f988da, 0x76f988da, 0x76f988da,\
		    0x983e5152, 0x983e5152, 0x983e5152, 0x983e5152,\
		    0xa831c66d, 0xa831c66d, 0xa831c66d, 0xa831c66d,\
		    0xb00327c8, 0xb00327c8, 0xb00327c8, 0xb00327c8,\
		    0xbf597fc7, 0xbf597fc7, 0xbf597fc7, 0xbf597fc7,\
		    0xc6e00bf3, 0xc6e00bf3, 0xc6e00bf3, 0xc6e00bf3,\
		    0xd5a79147, 0xd5a79147, 0xd5a79147, 0xd5a79147,\
		    0x06ca6351, 0x06ca6351, 0x06ca6351, 0x06ca6351,\
		    0x14292967, 0x14292967, 0x14292967, 0x14292967,\
		    0x27b70a85, 0x27b70a85, 0x27b70a85, 0x27b70a85,\
		    0x2e1b2138, 0x2e1b2138, 0x2e1b2138, 0x2e1b2138,\
		    0x4d2c6dfc, 0x4d2c6dfc, 0x4d2c6dfc, 0x4d2c6dfc,\
		    0x53380d13, 0x53380d13, 0x53380d13, 0x53380d13,\
		    0x650a7354, 0x650a7354, 0x650a7354, 0x650a7354,\
		    0x766a0abb, 0x766a0abb, 0x766a0abb, 0x766a0abb,\
		    0x81c2c92e, 0x81c2c92e, 0x81c2c92e, 0x81c2c92e,\
		    0x92722c85, 0x92722c85, 0x92722c85, 0x92722c85,\
		    0xa2bfe8a1, 0xa2bfe8a1, 0xa2bfe8a1, 0xa2bfe8a1,\
		    0xa81a664b, 0xa81a664b, 0xa81a664b, 0xa81a664b,\
		    0xc24b8b70, 0xc24b8b70, 0xc24b8b70, 0xc24b8b70,\
		    0xc76c51a3, 0xc76c51a3, 0xc76c51a3, 0xc76c51a3,\
		    0xd192e819, 0xd192e819, 0xd192e819, 0xd192e819,\
		    0xd6990624, 0xd6990624, 0xd6990624, 0xd6990624,\
		    0xf40e3585, 0xf40e3585, 0xf40e3585, 0xf40e3585,\
		    0x106aa070, 0x106aa070, 0x106aa070, 0x106aa070,\
		    0x19a4c116, 0x19a4c116, 0x19a4c116, 0x19a4c116,\
		    0x1e376c08, 0x1e376c08, 0x1e376c08, 0x1e376c08,\
		    0x2748774c, 0x2748774c, 0x2748774c, 0x2748774c,\
		    0x34b0bcb5, 0x34b0bcb5, 0x34b0bcb5, 0x34b0bcb5,\
		    0x391c0cb3, 0x391c0cb3, 0x391c0cb3, 0x391c0cb3,\
		    0x4ed8aa4a, 0x4ed8aa4a, 0x4ed8aa4a, 0x4ed8aa4a,\
		    0x5b9cca4f, 0x5b9cca4f, 0x5b9cca4f, 0x5b9cca4f,\
		    0x682e6ff3, 0x682e6ff3, 0x682e6ff3, 0x682e6ff3,\
		    0x748f82ee, 0x748f82ee, 0x748f82ee, 0x748f82ee,\
		    0x78a5636f, 0x78a5636f, 0x78a5636f, 0x78a5636f,\
		    0x84c87814, 0x84c87814, 0x84c87814, 0x84c87814,\
		    0x8cc70208, 0x8cc70208, 0x8cc70208, 0x8cc70208,\
		    0x90befffa, 0x90befffa, 0x90befffa, 0x90befffa,\
		    0xa4506ceb, 0xa4506ceb, 0xa4506ceb, 0xa4506ceb,\
		    0xbef9a3f7, 0xbef9a3f7, 0xbef9a3f7, 0xbef9a3f7,\
		    0xc67178f2, 0xc67178f2, 0xc67178f2, 0xc67178f2

.LPADDINGx4:
.word		    0xc28a2f98, 0xc28a2f98, 0xc28a2f98, 0xc28a2f98,\
		    0x71374491, 0x71374491, 0x71374491, 0x71374491,\
		    0xb5c0fbcf, 0xb5c0fbcf, 0xb5c0fbcf, 0xb5c0fbcf,\
		    0xe9b5dba5, 0xe9b5dba5, 0xe9b5dba5, 0xe9b5dba5,\
		    0x3956c25b, 0x3956c25b, 0x3956c25b, 0x3956c25b,\
		    0x59f111f1, 0x59f111f1, 0x59f111f1, 0x59f111f1,\
		    0x923f82a4, 0x923f82a4, 0x923f82a4, 0x923f82a4,\
		    0xab1c5ed5, 0xab1c5ed5, 0xab1c5ed5, 0xab1c5ed5,\
		    0xd807aa98, 0xd807aa98, 0xd807aa98, 0xd807aa98,\
		    0x12835b01, 0x12835b01, 0x12835b01, 0x12835b01,\
		    0x243185be, 0x243185be, 0x243185be, 0x243185be,\
		    0x550c7dc3, 0x550c7dc3, 0x550c7dc3, 0x550c7dc3,\
		    0x72be5d74, 0x72be5d74, 0x72be5d74, 0x72be5d74,\
		    0x80deb1fe, 0x80deb1fe, 0x80deb1fe, 0x80deb1fe,\
		    0x9bdc06a7, 0x9bdc06a7, 0x9bdc06a7, 0x9bdc06a7,\
		    0xc19bf374, 0xc19bf374, 0xc19bf374, 0xc19bf374,\
		    0x649b69c1, 0x649b69c1, 0x649b69c1, 0x649b69c1,\
		    0xf0fe4786, 0xf0fe4786, 0xf0fe4786, 0xf0fe4786,\
		    0x0fe1edc6, 0x0fe1edc6, 0x0fe1edc6, 0x0fe1edc6,\
		    0x240cf254, 0x240cf254, 0x240cf254, 0x240cf254,\
		    0x4fe9346f, 0x4fe9346f, 0x4fe9346f, 0x4fe9346f,\
		    0x6cc984be, 0x6cc984be, 0x6cc984be, 0x6cc984be,\
		    0x61b9411e, 0x61b9411e, 0x61b9411e, 0x61b9411e,\
		    0x16f988fa, 0x16f988fa, 0x16f988fa, 0x16f988fa,\
		    0xf2c65152, 0xf2c65152, 0xf2c65152, 0xf2c65152,\
		    0xa88e5a6d, 0xa88e5a6d, 0xa88e5a6d, 0xa88e5a6d,\
		    0xb019fc65, 0xb019fc65, 0xb019fc65, 0xb019fc65,\
		    0xb9d99ec7, 0xb9d99ec7, 0xb9d99ec7, 0xb9d99ec7,\
		    0x9a1231c3, 0x9a1231c3, 0x9a1231c3, 0x9a1231c3,\
		    0xe70eeaa0, 0xe70eeaa0, 0xe70eeaa0, 0xe70eeaa0,\
		    0xfdb1232b, 0xfdb1232b, 0xfdb1232b, 0xfdb1232b,\
		    0xc7353eb0, 0xc7353eb0, 0xc7353eb0, 0xc7353eb0,\
		    0x3069bad5, 0x3069bad5, 0x3069bad5, 0x3069bad5,\
		    0xcb976d5f, 0xcb976d5f, 0xcb976d5f, 0xcb976d5f,\
		    0x5a0f118f, 0x5a0f118f, 0x5a0f118f, 0x5a0f118f,\
		    0xdc1eeefd, 0xdc1eeefd, 0xdc1eeefd, 0xdc1eeefd,\
		    0x0a35b689, 0x0a35b689, 0x0a35b689, 0x0a35b689,\
		    0xde0b7a04, 0xde0b7a04, 0xde0b7a04, 0xde0b7a04,\
		    0x58f4ca9d, 0x58f4ca9d, 0x58f4ca9d, 0x58f4ca9d,\
		    0xe15d5b16, 0xe15d5b16, 0xe15d5b16, 0xe15d5b16,\
		    0x007f3e86, 0x007f3e86, 0x007f3e86, 0x007f3e86,\
		    0x37088980, 0x37088980, 0x37088980, 0x37088980,\
		    0xa507ea32, 0xa507ea32, 0xa507ea32, 0xa507ea32,\
		    0x6fab9537, 0x6fab9537, 0x6fab9537, 0x6fab9537,\
		    0x17406110, 0x17406110, 0x17406110, 0x17406110,\
		    0x0d8cd6f1, 0x0d8cd6f1, 0x0d8cd6f1, 0x0d8cd6f1,\
		    0xcdaa3b6d, 0xcdaa3b6d, 0xcdaa3b6d, 0xcdaa3b6d,\
		    0xc0bbbe37, 0xc0bbbe37, 0xc0bbbe37, 0xc0bbbe37,\
		    0x83613bda, 0x83613bda, 0x83613bda, 0x83613bda,\
		    0xdb48a363, 0xdb48a363, 0xdb48a363, 0xdb48a363,\
		    0x0b02e931, 0x0b02e931, 0x0b02e931, 0x0b02e931,\
		    0x6fd15ca7, 0x6fd15ca7, 0x6fd15ca7, 0x6fd15ca7,\
		    0x521afaca, 0x521afaca, 0x521afaca, 0x521afaca,\
		    0x31338431, 0x31338431, 0x31338431, 0x31338431,\
		    0x6ed41a95, 0x6ed41a95, 0x6ed41a95, 0x6ed41a95,\
		    0x6d437890, 0x6d437890, 0x6d437890, 0x6d437890,\
		    0xc39c91f2, 0xc39c91f2, 0xc39c91f2, 0xc39c91f2,\
		    0x9eccabbd, 0x9eccabbd, 0x9eccabbd, 0x9eccabbd,\
		    0xb5c9a0e6, 0xb5c9a0e6, 0xb5c9a0e6, 0xb5c9a0e6,\
		    0x532fb63c, 0x532fb63c, 0x532fb63c, 0x532fb63c,\
		    0xd2c741c6, 0xd2c741c6, 0xd2c741c6, 0xd2c741c6,\
		    0x07237ea3, 0x07237ea3, 0x07237ea3, 0x07237ea3,\
		    0xa4954b68, 0xa4954b68, 0xa4954b68, 0xa4954b68,\
		    0x4c191d76, 0x4c191d76, 0x4c191d76, 0x4c191d76

#endif
