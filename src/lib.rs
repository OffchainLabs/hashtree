//! Hasthree rust bindings
//!
//! hashtree is a SHA256 library highly optimized for Merkle tree computations. It is based on
//! Intel's implementation (intel-ipsec-mb) with a few modifications like hardcoding the scheduled
//! words. This library exposes a single function that takes an input slice of bytes to be
//! considered as chunks of 64 bytes each, and another slice where the digests of each chunk will
//! be written consecutively
//!

/*
MIT License

Copyright (c) 2021-2024 Prysmatic Labs

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

extern crate libc;
use libc::c_int;
use std::ptr;

type HashFunction = extern "C" fn(*mut u8, *const u8, u64);

extern "C" {
    fn hashtree_init(override_: *const HashFunction) -> c_int;
    fn hashtree_hash(output: *mut u8, input: *const u8, count: u64);
}

/// init is used to initialize the hashtree library. It automatically chooses the best
/// implementation.
pub fn init() -> i32 {
    unsafe { hashtree_init(ptr::null()) }
}

/// hash takes a mutable slice where the digests will be stored (overwritten), a slice with the
/// chunks to merkleize and the number of chunks to merkleize
pub fn hash(out: &mut [u8], chunks: &[u8], count: usize) {
    unsafe { hashtree_hash(out.as_mut_ptr(), chunks.as_ptr(), count as u64) }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hash() {
        let chunks: [u8; 64] = [0xAB; 64];
        let mut out = [0u8; 32];

        hash(&mut out, &chunks, 1);

        let expected_hash: [u8; 32] = [
            0xec, 0x65, 0xc8, 0x79, 0x8e, 0xcf, 0x95, 0x90, 0x24, 0x13, 0xc4, 0x0f, 0x7b, 0x9e,
            0x6d, 0x4b, 0x00, 0x68, 0x88, 0x5f, 0x5f, 0x32, 0x4a, 0xba, 0x1f, 0x9b, 0xa1, 0xc8,
            0xe1, 0x4a, 0xea, 0x61,
        ];

        assert_eq!(
            out, expected_hash,
            "The generated hash did not match the expected hash."
        );
    }
}
