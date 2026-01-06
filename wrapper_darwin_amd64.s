// +build darwin,amd64

// Stub implementation - should never be called since supportedCPU = false
// on darwin/amd64. The generic Go implementation is used instead.
TEXT ·HashtreeHash(SB), 0, $0-24
	INT	$3  // Trigger breakpoint/crash if ever called
	RET
