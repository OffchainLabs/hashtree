//go:build darwin && amd64

package hashtree

// supportedCPU is false on darwin/amd64 because there is no native
// assembly implementation. The generic Go implementation will be used.
var supportedCPU = false

