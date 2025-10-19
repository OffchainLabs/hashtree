//go:build cgo && darwin && arm64
// +build cgo,darwin,arm64

package hashtree

/*
#cgo CFLAGS: -O3 -I./src
#cgo LDFLAGS: -L./lib/darwin_arm64 -lhashtree

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

var hasShani = cpuid.CPU.Supports(cpuid.SHA2)
var supportedCPU = hasShani