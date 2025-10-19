//go:build cgo && windows && amd64
// +build cgo,windows,amd64

package hashtree

/*
#cgo CFLAGS: -O3 -I./src
#cgo LDFLAGS: -L./lib/windows_amd64 -lhashtree

#include "src/hashtree.h"

void call_hashtree_hash(unsigned char* output, const unsigned char* input, uint64_t count) {
    hashtree_hash(output, input, count);
}
*/
import "C"
import (
	"unsafe"
	"github.com/klauspost/cpuid/v2"
)

func HashtreeHash(output *byte, input *byte, count uint64) {
	C.call_hashtree_hash((*C.uchar)(unsafe.Pointer(output)), (*C.uchar)(unsafe.Pointer(input)), C.uint64_t(count))
}

var hasAVX512 = cpuid.CPU.Supports(cpuid.AVX512F, cpuid.AVX512VL)
var hasAVX2 = cpuid.CPU.Supports(cpuid.AVX2, cpuid.BMI2)
var hasShani = cpuid.CPU.Supports(cpuid.SHA, cpuid.AVX)
var supportedCPU = hasAVX2 || hasShani || hasAVX512