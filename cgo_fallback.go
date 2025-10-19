//go:build !cgo
// +build !cgo

package hashtree

// HashtreeHash fallback for when CGO is disabled
func HashtreeHash(output *byte, input *byte, count uint64) {
	panic("HashtreeHash called with CGO disabled - this should not happen")
}

// Disable optimized CPU support when CGO is not available
var supportedCPU = false