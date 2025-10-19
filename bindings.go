package hashtree

import (
	"errors"
	"fmt"
	"unsafe"
)

var (
	// ErrOddChunks is returned when the number of chunks is odd.
	ErrOddChunks = errors.New("odd number of chunks")
	// ErrNotEnoughDigests is returned when the number of digests is not enough.
	ErrNotEnoughDigests = errors.New("not enough digest length")
	// ErrChunksNotMultipleOf64 is returned when the chunks are not multiple of 64 bytes.
	ErrChunksNotMultipleOf64 = errors.New("chunks not multiple of 64 bytes")
	// ErrDigestsNotMultipleOf32 is returned when the digests are not multiple of 32 bytes.
	ErrDigestsNotMultipleOf32 = errors.New("digests not multiple of 32 bytes")
)

// HashtreeHash is defined in assembly for supported platforms

// Hash hashes the chunks two at the time and outputs the digests on the first
// argument. It does check for lengths on the inputs.
func Hash(digests [][32]byte, chunks [][32]byte) error {
	if len(chunks) == 0 {
		return nil
	}

	if len(chunks)%2 == 1 {
		return ErrOddChunks
	}
	if len(digests) < len(chunks)/2 {
		return fmt.Errorf("%w: need at least %v, got %v", ErrNotEnoughDigests, len(chunks)/2, len(digests))
	}
	if supportedCPU {
		HashtreeHash(&digests[0][0], &chunks[0][0], uint64(len(chunks)/2))
	} else {
		sha256_1_generic(digests, chunks)
	}
	return nil
}

// HashByteSlice is the same as hash but it takes byte slices instead of slices of arrays.
func HashByteSlice(digests []byte, chunks []byte) error {
	if len(chunks) == 0 {
		return nil
	}

	if len(chunks)%64 != 0 {
		return ErrChunksNotMultipleOf64
	}

	if len(digests)%32 != 0 {
		return ErrDigestsNotMultipleOf32
	}

	if len(digests) < len(chunks)/2 {
		return fmt.Errorf("%w: need at least %v, got %v", ErrNotEnoughDigests, len(chunks)/2, len(digests))
	}
	// We use an unsafe pointer to cast []byte to [][32]byte. The length and
	// capacity of the slice need to be divided accordingly by 32.
	sizeChunks := (len(chunks) >> 5)
	chunkedChunks := unsafe.Slice((*[32]byte)(unsafe.Pointer(&chunks[0])), sizeChunks)

	sizeDigests := (len(digests) >> 5)
	chunkedDigest := unsafe.Slice((*[32]byte)(unsafe.Pointer(&digests[0])), sizeDigests)
	if supportedCPU {
		Hash(chunkedDigest, chunkedChunks)
	} else {
		sha256_1_generic(chunkedDigest, chunkedChunks)
	}
	return nil
}
