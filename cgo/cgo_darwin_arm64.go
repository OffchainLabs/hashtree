//go:build darwin && arm64
// +build darwin,arm64

package cgo

/*
#cgo LDFLAGS: -L../lib/darwin_arm64 -lhashtree
*/
import "C"
