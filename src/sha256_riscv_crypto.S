/*
MIT License

Copyright (c) 2021-2025 Prysmatic Labs

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

#ifdef __riscv
.section .rodata
.align 4
.LK256:
    .long       0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5
    .long       0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5
    .long       0xd807aa98,0x12835b01,0x243185be,0x550c7dc3
    .long       0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174
    .long       0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc
    .long       0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da
    .long       0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7
    .long       0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967
    .long       0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13
    .long       0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85
    .long       0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3
    .long       0xd192e819,0xd6990624,0xf40e3585,0x106aa070
    .long       0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5
    .long       0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3
    .long       0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208
    .long       0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2

.LDIGEST:
    .long   0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
    .long   0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

.LPADDING:
    .long   0xc28a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5
    .long   0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
    .long   0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3
    .long   0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf374
    .long   0x649b69c1, 0xf0fe4786, 0x0fe1edc6, 0x240cf254
    .long   0x4fe9346f, 0x6cc984be, 0x61b9411e, 0x16f988fa
    .long   0xf2c65152, 0xa88e5a6d, 0xb019fc65, 0xb9d99ec7
    .long   0x9a1231c3, 0xe70eeaa0, 0xfdb1232b, 0xc7353eb0
    .long   0x3069bad5, 0xcb976d5f, 0x5a0f118f, 0xdc1eeefd
    .long   0x0a35b689, 0xde0b7a04, 0x58f4ca9d, 0xe15d5b16
    .long   0x007f3e86, 0x37088980, 0xa507ea32, 0x6fab9537
    .long   0x17406110, 0x0d8cd6f1, 0xcdaa3b6d, 0xc0bbbe37
    .long   0x83613bda, 0xdb48a363, 0x0b02e931, 0x6fd15ca7
    .long   0x521afaca, 0x31338431, 0x6ed41a95, 0x6d437890
    .long   0xc39c91f2, 0x9eccabbd, 0xb5c9a0e6, 0x532fb63c
    .long   0xd2c741c6, 0x07237ea3, 0xa4954b68, 0x4c191d76

#define FRAMEZ  80  // Stack size: 16 * 4 + 16 bytes for one clobbered register and alignment
#define DIGEST_OFFSET  256  // Offset for the digest constants
#define PADDING_OFFSET 288  // Offset for padding constants

.macro BSWP rd 
	rev8	\rd, \rd
	srai	\rd, \rd, 32
.endm

// Schedules a word 
// s10 has the scheduled word to consume
.macro SCHED offset
	.set .Lmyoff, (\offset + 56) % 64
        lwu  	a5, (.Lmyoff)(sp)        	// a5 = w[i-2]
	.set .Lmyoff, (\offset + 36) % 64
        lwu   	s10, (.Lmyoff)(sp)        	// s10 = w[i-7]
	sha256sig1	a4,a5			// a4 = \sigma_1(w_{i-2})
	.set .Lmyoff, (\offset + 4) % 64
        lwu     a6, (.Lmyoff)(sp)         	// a6 = w[i-15]
	addw	s10, s10, a4			// s10 = w_{i-7} + \sigma_1 w_{i-2}
	.set .Lmyoff, (\offset + 0) % 64
        lwu      a5, (.Lmyoff)(sp)		// a5 = w[i-16]
	sha256sig0	a4, a6			// a4 = \sigma_0(w_{i-15})
	addw 	s10, s10, a5 			// s10 = w_{i-7} + w_{i-16} + \sigma_1 w_{i-2}
	addw	s10, s10, a4 
        sw      s10, (.Lmyoff)(sp)              // w[i] is stored and kept in s10
.endm

// Performs a full round.
// @w: the scheduled word to use
// @offset: the offset to the K constants to use. 
// @base: the base address of the K constants.
// The word to consume is passed in s10
.macro DO_ROUND base, offset, a, b, c, d, e, f, g, h, USE_SCHED
        xor	a4, \f, \g              // a4 = f ^ g
	or	a5, \a, \c		// a5 = a | c
	sha256sum1	a6, \e		// a6 = \Sigma_1 e
	and	a4, a4, \e		// a4 = (f ^ g) & e
	and	a5, a5, \b		// a5 = (a | c) & b
	xor 	a4, a4, \g		// a4 = ((f ^ g) & e ) ^ g
	addw	\h, \h, a6		// h = h + \Sigma_1 e
	lwu 	a6, (\offset)(\base)	// a6 = K[offset]
.ifnb	\USE_SCHED
	addw	\h, \h, s10		// h = h + \Sigma_1 e + w
.endif
	sha256sum0	s10, \a		// s10 = \Sigma_0 a
	addw 	\h, \h, a6		// h = h + \Sigma_1 e + K[offset] + w
	and	a6, \a, \c		// a6 = a & c
	addw 	\h, \h, a4		// h = h + \Sigma_1 e + ((f ^ g) & e) ^g + K[offset] + w
	or	a5, a5, a6 		// a5 = (a | c) & b | (a & c)
	addw	\d, \d, \h		// d = d + h + \Sigma_1 e + ((f ^ g) & e) ^g + K[offset] + w
	addw 	a5, a5, s10		// a5 = \Sigma_0 a + ((a | c) & b) | (a & c)
	addw	\h, \h, a5
.endm

.macro ROUND_FROM_INPUT offset, a, b, c, d, e, f, g, h
        lwu	s10, \offset(a1)
        BSWP 	s10
        sw 	s10, \offset(sp)
        DO_ROUND a3, \offset, \a, \b, \c, \d, \e, \f, \g, \h, 1
.endm

.macro FIRST_SIXTEEN_ROUNDS a, b, c, d, e, f, g, h
    ROUND_FROM_INPUT 0, \a, \b, \c, \d, \e, \f, \g, \h
    ROUND_FROM_INPUT 4, \h, \a, \b, \c, \d, \e, \f, \g
    ROUND_FROM_INPUT 8, \g, \h, \a, \b, \c, \d, \e, \f
    ROUND_FROM_INPUT 12, \f, \g, \h, \a, \b, \c, \d, \e
    ROUND_FROM_INPUT 16, \e, \f, \g, \h, \a, \b, \c, \d
    ROUND_FROM_INPUT 20, \d, \e, \f, \g, \h, \a, \b, \c
    ROUND_FROM_INPUT 24, \c, \d, \e, \f, \g, \h, \a, \b
    ROUND_FROM_INPUT 28, \b, \c, \d, \e, \f, \g, \h, \a
    ROUND_FROM_INPUT 32, \a, \b, \c, \d, \e, \f, \g, \h
    ROUND_FROM_INPUT 36, \h, \a, \b, \c, \d, \e, \f, \g
    ROUND_FROM_INPUT 40, \g, \h, \a, \b, \c, \d, \e, \f
    ROUND_FROM_INPUT 44, \f, \g, \h, \a, \b, \c, \d, \e
    ROUND_FROM_INPUT 48, \e, \f, \g, \h, \a, \b, \c, \d
    ROUND_FROM_INPUT 52, \d, \e, \f, \g, \h, \a, \b, \c
    ROUND_FROM_INPUT 56, \c, \d, \e, \f, \g, \h, \a, \b
    ROUND_FROM_INPUT 60, \b, \c, \d, \e, \f, \g, \h, \a
.endm

.macro ROUND_AND_SCHEDULE offset, a, b, c, d, e, f, g, h
    SCHED \offset
    DO_ROUND a3, \offset, \a, \b, \c, \d, \e, \f, \g, \h, 1
.endm 

.macro EIGHT_ROUNDS_AND_SCHED offset, a, b, c, d, e, f, g, h
    ROUND_AND_SCHEDULE \offset, \a, \b, \c, \d, \e, \f, \g, \h
    ROUND_AND_SCHEDULE \offset + 4, \h, \a, \b, \c, \d, \e, \f, \g
    ROUND_AND_SCHEDULE \offset + 8, \g, \h, \a, \b, \c, \d, \e, \f
    ROUND_AND_SCHEDULE \offset + 12, \f, \g, \h, \a, \b, \c, \d, \e
    ROUND_AND_SCHEDULE \offset + 16, \e, \f, \g, \h, \a, \b, \c, \d
    ROUND_AND_SCHEDULE \offset + 20, \d, \e, \f, \g, \h, \a, \b, \c
    ROUND_AND_SCHEDULE \offset + 24, \c, \d, \e, \f, \g, \h, \a ,\b
    ROUND_AND_SCHEDULE \offset + 28, \b ,\c ,\d ,\e ,\f ,\g ,\h ,\a
.endm

.macro EIGHT_ROUNDS offset, a, b, c, d, e, f, g, h
    DO_ROUND a3, \offset, \a, \b, \c, \d, \e, \f, \g, \h, 
    DO_ROUND a3, \offset + 4, \h, \a, \b, \c, \d, \e, \f, \g, 
    DO_ROUND a3, \offset + 8, \g, \h, \a, \b, \c, \d, \e, \f, 
    DO_ROUND a3, \offset + 12, \f, \g, \h, \a, \b, \c, \d, \e, 
    DO_ROUND a3, \offset + 16, \e, \f, \g ,\h ,\a ,\b ,\c ,\d, 
    DO_ROUND a3, \offset + 20, \d ,\e ,\f ,\g ,\h ,\a ,\b ,\c, 
    DO_ROUND a3, \offset + 24, \c ,\d ,\e ,\f ,\g ,\h ,\a ,\b, 
    DO_ROUND a3, \offset + 28, \b ,\c ,\d ,\e ,\f ,\g ,\h ,\a, 
.endm

.text
.global hashtree_sha256_riscv_crypto
.type   hashtree_sha256_riscv_crypto,%function
.align 4
hashtree_sha256_riscv_crypto:
    // set the stack (assumed to be aligned)
    addi sp,sp,-FRAMEZ
    sd s10, 64(sp)
    
    //initialize the constants
    la      a3, .LK256
    slli    a2, a2, 5
    add     a2, a2, a0

.Lsha256_riscv_crypto_loop:
    beq     a0, a2, .Lsha256_riscv_crypto_epilogue
    // initialize the digest variables
    lwu t0,DIGEST_OFFSET(a3)
    lwu t1,DIGEST_OFFSET+4(a3)
    lwu t2,DIGEST_OFFSET+8(a3)
    lwu t3,DIGEST_OFFSET+12(a3)
    lwu t4,DIGEST_OFFSET+16(a3)
    lwu t5,DIGEST_OFFSET+20(a3)
    lwu t6,DIGEST_OFFSET+24(a3)
    lwu a7,DIGEST_OFFSET+28(a3)

    // First 16 rounds we consume the incoming words directly
    FIRST_SIXTEEN_ROUNDS t0, t1, t2, t3, t4, t5, t6, a7
    // update the input pointer
    addi    a1, a1, 64

    // The next 48 rounds we consume the scheduled words
    .set .Lround_offset, 64
    .rept 6
        EIGHT_ROUNDS_AND_SCHED .Lround_offset, t0, t1, t2, t3, t4, t5, t6, a7
        .set .Lround_offset, .Lround_offset + 32
    .endr

    // Add the original digest
    lwu      a6, DIGEST_OFFSET(a3)
    lwu      a5, DIGEST_OFFSET+4(a3)
    addw    t0, t0, a6
    lwu      a4, DIGEST_OFFSET+8(a3)
    addw    t1, t1, a5
    lwu      a6, DIGEST_OFFSET+12(a3)
    addw    t2, t2, a4
    lwu      a5, DIGEST_OFFSET+16(a3)
    addw    t3, t3, a6
    lwu      a4, DIGEST_OFFSET+20(a3)
    addw    t4, t4, a5
    lwu      a6, DIGEST_OFFSET+24(a3)
    addw    t5, t5, a4
    lwu      a5, DIGEST_OFFSET+28(a3)
    addw    t6, t6, a6
    addw    a7, a7, a5

    // Save the digest, we can use the scheduled word storage
    sw      t0, 0(sp)
    sw      t1, 4(sp)
    sw      t2, 8(sp)
    sw      t3, 12(sp)
    sw      t4, 16(sp)
    sw      t5, 20(sp)
    sw      t6, 24(sp)
    sw      a7, 28(sp)

    // Rounds with padding
    .set .Lround_offset, PADDING_OFFSET
    .rept 8
        EIGHT_ROUNDS .Lround_offset, t0, t1, t2, t3, t4, t5, t6, a7
        .set .Lround_offset, .Lround_offset + 32
    .endr

    // Add the previous digest
    lwu      a6, 0(sp)
    lwu      a5, 4(sp)
    addw    t0, t0, a6
    lwu      a4, 8(sp)
    addw    t1, t1, a5
    lwu      a6, 12(sp)
    addw    t2, t2, a4
    lwu      a5, 16(sp)
    addw    t3, t3, a6
    lwu      a4, 20(sp)
    addw    t4, t4, a5
    lwu      a6, 24(sp)
    addw    t5, t5, a4
    lwu      a5, 28(sp)
    addw    t6, t6, a6
    addw    a7, a7, a5

    // Byte swap to little-endian and save
    BSWP    t0
    sw      t0, 0(a0)
    BSWP    t1
    sw      t1, 4(a0)
    BSWP    t2
    sw      t2, 8(a0)
    BSWP    t3
    sw      t3, 12(a0)
    BSWP    t4
    sw      t4, 16(a0)
    BSWP    t5
    sw      t5, 20(a0)
    BSWP    t6
    sw      t6, 24(a0)
    BSWP    a7
    sw      a7, 28(a0)
    addi    a0, a0, 32
    j       .Lsha256_riscv_crypto_loop

.Lsha256_riscv_crypto_epilogue:
    // restore the stack
    ld      s10, 64(sp)
    addi    sp,sp,FRAMEZ
    ret

#ifdef __linux__ 
.size hashtree_sha256_riscv_crypto,.-hashtree_sha256_riscv_crypto
.section .note.GNU-stack,"",@progbits
#endif

#endif // riscv
