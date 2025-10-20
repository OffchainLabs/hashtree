//go:build arm64
// +build arm64

package hashtree

import (
	_ "github.com/OffchainLabs/hashtree/lib"
	"github.com/klauspost/cpuid/v2"
)

var hasShani = cpuid.CPU.Supports(cpuid.SHA2)
var supportedCPU = true
