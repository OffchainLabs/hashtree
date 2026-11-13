// +build arm64

TEXT ·HashtreeHash(SB), 0, $2048-24
		    MOVD output+0(FP), R0
		    MOVD input+8(FP), R1
		    MOVD count+16(FP), R2


#define check_shani R19
		    MOVBU ·hasShani(SB), check_shani
		    ADD  $2048, RSP, RSP
		    CBNZ  check_shani, shani

		    BL hashtree_sha256_neon_x4(SB)
		    JMP  done

shani:
		    BL hashtree_sha256_sha_x1(SB)

done:
		    SUB  $2048, RSP, RSP
		    RET
