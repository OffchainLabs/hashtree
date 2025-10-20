// +build linux,amd64

TEXT ·HashtreeHash(SB), 0, $2048-24
		    MOVQ output+0(FP), DI
		    MOVQ input+8(FP), SI 
		    MOVQ count+16(FP), DX

		    MOVQ SP, BX
		    ADDQ $2048, SP
		    ANDQ $~31, SP

		    CMPB ·hasShani(SB), $1
		    JE shani 
		    CMPB ·hasAVX512(SB), $1
		    JE avx512
		    CMPB ·hasAVX2(SB), $1
		    JE   avx2 
		    CALL hashtree_sha256_avx_x1(SB) 
		    JMP epilog

shani: 
		    CALL hashtree_sha256_shani_x2(SB)
		    JMP epilog

avx512: 
		    CALL hashtree_sha256_avx512_x16(SB) 
		    JMP epilog

avx2:
		    CALL hashtree_sha256_avx2_x8(SB)

epilog:
		    MOVQ BX, SP
		    RET
