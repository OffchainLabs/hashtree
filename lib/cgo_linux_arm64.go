//go:build linux && arm64
// +build linux,arm64

package lib

/*
#cgo LDFLAGS: -L./linux_amd64 -lhashtree
*/
import "C"
