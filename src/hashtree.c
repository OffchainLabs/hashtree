/*
MIT License

Copyright (c) 2021-2026 Prysmatic Labs

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

#include "hashtree.h"

#include <assert.h>
#ifdef __x86_64__
#include <cpuid.h>
#endif
#ifdef __aarch64__
#ifndef __APPLE__
#include <asm/hwcap.h>
#include <sys/auxv.h>
#endif
#endif
#ifdef __riscv
#include <sys/syscall.h>
#include <unistd.h>

/* riscv_hwprobe syscall interface - available in Linux 6.4+ */
#ifndef __NR_riscv_hwprobe
#define __NR_riscv_hwprobe 258
#endif

struct riscv_hwprobe {
    int64_t key;
    uint64_t value;
};

#define RISCV_HWPROBE_KEY_IMA_EXT_0 4
/*
 * Extension bit positions as defined by the Linux riscv_hwprobe ABI
 * (arch/riscv/include/uapi/asm/hwprobe.h). The bits are not contiguous:
 * bits 0-2 are the IMA FD/C/V flags and bit 3 is Zba, so Zbb starts at bit 4.
 */
#define RISCV_HWPROBE_EXT_ZBB       (1ULL << 4)
#define RISCV_HWPROBE_EXT_ZBC       (1ULL << 7)
#define RISCV_HWPROBE_EXT_ZBKB      (1ULL << 8)
#define RISCV_HWPROBE_EXT_ZBKC      (1ULL << 9)
#define RISCV_HWPROBE_EXT_ZBKX      (1ULL << 10)
#define RISCV_HWPROBE_EXT_ZKND      (1ULL << 11)
#define RISCV_HWPROBE_EXT_ZKNE      (1ULL << 12)
#define RISCV_HWPROBE_EXT_ZKNH      (1ULL << 13)
#define RISCV_HWPROBE_EXT_ZKSED     (1ULL << 14)
#define RISCV_HWPROBE_EXT_ZKSH      (1ULL << 15)
#define RISCV_HWPROBE_EXT_ZKT       (1ULL << 16)
#endif

static void init_and_hash(unsigned char *output, const unsigned char *input, uint64_t count);

static hashtree_hash_fcn hash_ptr = init_and_hash;

#ifdef __x86_64__
/* XGETBV is only valid when CPUID.1:ECX.OSXSAVE is set. */
static uint64_t hashtree_xgetbv(uint32_t index) {
    uint32_t eax, edx;
    __asm__ __volatile__("xgetbv" : "=a"(eax), "=d"(edx) : "c"(index));
    return ((uint64_t)edx << 32) | eax;
}
#endif

static hashtree_hash_fcn hashtree_detect() {
#ifdef __x86_64__
    uint32_t a = 0, b = 0, c = 0, d = 0;
    uint32_t c1 = 0;
    uint64_t xcr0 = 0;
    __get_cpuid_count(1, 0, &a, &b, &c1, &d);
    if (c1 & bit_OSXSAVE) {
        xcr0 = hashtree_xgetbv(0);
    }
    /* XCR0: YMM = bits 1-2, ZMM/opmask = bits 5-7. */
    const int ymm_ok = (xcr0 & 0x6) == 0x6;
    const int zmm_ok = ymm_ok && (xcr0 & 0xE0) == 0xE0;

    __get_cpuid_count(7, 0, &a, &b, &c, &d);
    if (b & bit_SHA) {
        /* Although AVX512 may be faster for full 16-block hashes, SHANI
        outperforms it significantly on smaller lists - thus, avoid pathological
        behavior. */
        return &hashtree_sha256_shani_x2;
    }
    /* avx512_x16 needs AVX512BW and tail-jumps to avx2_x8. */
    if ((b & bit_AVX512F) && (b & bit_AVX512VL) && (b & bit_AVX512BW) &&
        (b & bit_AVX2) && zmm_ok) {
        return &hashtree_sha256_avx512_x16;
    }
    if ((b & bit_AVX2) && ymm_ok) {
        return &hashtree_sha256_avx2_x8;
    }
    if ((c1 & bit_AVX) && ymm_ok) {
        return &hashtree_sha256_avx_x4;
    }
    if (c1 & bit_SSSE3) {
        return &hashtree_sha256_sse_x1;
    }
#endif
#ifdef __riscv
    struct riscv_hwprobe pairs[1] = {
        { .key = RISCV_HWPROBE_KEY_IMA_EXT_0 }
    };

    long ret = syscall(__NR_riscv_hwprobe, pairs, 1, 0, NULL, 0);
    if (ret == 0) {
        uint64_t ext = pairs[0].value;

        /* Check for SHA-256 crypto extension (Zknh) + related extensions */
        if ((ext & RISCV_HWPROBE_EXT_ZKNH) && (ext & RISCV_HWPROBE_EXT_ZBKB)) {
            return &hashtree_sha256_riscv_crypto;
        }

        /* Check for Zbb bit manipulation extension */
        if (ext & RISCV_HWPROBE_EXT_ZBB) {
            return &hashtree_sha256_riscv_zbb_x1;
        }
    }

    /* Fall back to basic RISC-V implementation */
    return &hashtree_sha256_riscv_x1;
#endif
#ifdef __aarch64__
#ifdef __APPLE__
    return &hashtree_sha256_sha_x1;
#else
    long hwcaps = getauxval(AT_HWCAP);
    if (hwcaps & HWCAP_SHA2) {
        return &hashtree_sha256_sha_x1;
    }

    if (hwcaps & HWCAP_ASIMD) {
        return &hashtree_sha256_neon_x4;
    }
#endif
#endif
    return &hashtree_sha256_generic;
}

void hashtree_init(hashtree_hash_fcn override) {
    if (override) {
        hash_ptr = override;
    } else {
        hash_ptr = hashtree_detect();
    }
}

void hashtree_hash(unsigned char *output, const unsigned char *input, uint64_t count) {
#ifdef __riscv
    /* riscv kernels use 32-bit loads/stores on caller buffers; misaligned
     * buffers trap in the kernel (SIGBUS with PR_UNALIGN_SIGBUS). */
    if (((uintptr_t)output | (uintptr_t)input) & 3u) {
        hashtree_sha256_generic(output, input, count);
        return;
    }
#endif
    (*hash_ptr)(output, input, count);
}

static void init_and_hash(unsigned char *output, const unsigned char *input, uint64_t count) {
    hash_ptr = hashtree_detect();
    assert(hash_ptr);

    hashtree_hash(output, input, count);
}
