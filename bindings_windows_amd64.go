//go:build cgo && amd64
// +build cgo,amd64

package hashtree

import (
	"github.com/klauspost/cpuid/v2"

	// link to the static library via cgo
	_ "github.com/OffchainLabs/hashtree/cgo"
)

//go:noescape
func HashtreeHash(output *byte, input *byte, count uint64)

var hasAVX512 = cpuid.CPU.Supports(cpuid.AVX512F, cpuid.AVX512VL)
var hasAVX2 = cpuid.CPU.Supports(cpuid.AVX2, cpuid.BMI2)
var hasShani = cpuid.CPU.Supports(cpuid.SHA, cpuid.AVX)

func init() {
	supportedCPU = hasAVX2 || hasShani || hasAVX512
	hasHashtreeHash = HashtreeHash
}
