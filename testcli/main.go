package main

import (
	"fmt"

	"github.com/OffchainLabs/hashtree"
)

func main() {
	digests := make([][32]byte, 10)
	chunks := make([][32]byte, 10)

	hashtree.Hash(digests, chunks)

	fmt.Printf("Hash: %x\n", digests)
}
