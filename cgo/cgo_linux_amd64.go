//go:build linux && amd64
// +build linux,amd64

package cgo

/*
#cgo LDFLAGS: -L../lib/linux_amd64 -lhashtree
*/
import "C"
