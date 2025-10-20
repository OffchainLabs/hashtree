//go:build windows && amd64
// +build windows,amd64

package lib

/*
#cgo LDFLAGS: -L./windows_amd64 -lhashtree
*/
import "C"
