//go:build amd64 && !darwin
// +build amd64,!darwin

package hashtree

import (
	"github.com/klauspost/cpuid/v2"
)

var hasAVX512 = cpuid.CPU.Supports(cpuid.AVX512F, cpuid.AVX512VL)
var hasAVX2 = cpuid.CPU.Supports(cpuid.AVX2, cpuid.BMI2)
var hasShani = cpuid.CPU.Supports(cpuid.SHA, cpuid.AVX)
var supportedCPU = hasAVX2 || hasShani || hasAVX512
