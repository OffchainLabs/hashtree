//go:build cgo && darwin && amd64
// +build cgo,darwin,amd64

package hashtree

// HashtreeHash is not available on macOS Intel due to assembly syntax incompatibility.
// This function is never called since supportedCPU is false on this platform.
func HashtreeHash(output *byte, input *byte, count uint64) {
	panic("HashtreeHash should not be called on macOS Intel - uses pure Go fallback")
}

// supportedCPU is false on macOS Intel, forcing pure Go implementation
var supportedCPU = false