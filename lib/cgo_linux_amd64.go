//go:build linux && amd64
// +build linux,amd64

package lib

/*
#cgo LDFLAGS: -L./linux_amd64 -lhashtree
*/
import "C"
