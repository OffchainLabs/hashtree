//go:build linux && arm64
// +build linux,arm64

package cgo

/*
#cgo LDFLAGS: -L../lib/linux_arm64 -lhashtree
*/
import "C"
