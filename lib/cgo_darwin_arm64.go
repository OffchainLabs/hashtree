//go:build darwin && arm64
// +build darwin,arm64

package lib

/*
#cgo LDFLAGS: -L./darwin_arm64 -lhashtree
*/
import "C"
