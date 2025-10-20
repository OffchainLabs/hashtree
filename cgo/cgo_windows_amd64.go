//go:build windows && amd64
// +build windows,amd64

package cgo

/*
#cgo LDFLAGS: -L../lib/windows_amd64 -lhashtree
*/
import "C"
