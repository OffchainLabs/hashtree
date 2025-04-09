# hashtree

Hashtree is a SHA256 library highly optimized for Merkle tree computation. It is
based on [Intel's implementation](https://github.com/intel/intel-ipsec-mb) with
a few modifications like hardcoding the scheduled words of the padding block. 

The library exposes a single header file with the low level sha functions. They
all have the following signature:
```c
void sha256(unsigned char *output, unsigned char *input, uint64_t count)
```
where `input` is the buffer containing `count` chunks of 64 bytes to be hashed,
and `output` is a pre-allocated buffer that will hold the `count` 32-byte digests. 
These are low level functions that do not perform any error check: the caller is
responsible for checking that `input` is at least `64*count` bytes long and that
`output` is writable and at least `32*count` bytes long. The caller is
responsible for memory allocation and de-allocation of these buffers. 

## Dependencies
There are no dependencies besides the standard `C` header `stdint.h`. Benchmarks
have a dependency on `libm`. Tests and benchmarks on x86-64 an extra
dependency on `cpuid.h` is needed. An optional dependency on openssl allows to
test and benchmark against openssl. The only build-time dependency is a GCC and
GNU assembler compatible compiler like `gcc` and `gas`. On Mac OS X with newer Apple Silicon processors the library can be built with the default clang compiler. 

## Compilation
- Start by cloning the repository
```shell
$ git clone https://github.com/potuz/hashtree.git
$ cd hashtree
```
- To build the library
```shell
$ make
```
this produces a statically linked library `libhashtree.a` in the `src`
directory. 
- To build tests or benchmarks or all respectively:
```shell
$ make test
$ make bench
$ make all
```
- To test or benchmark against OPENSSL:
```shell
$ make clean
$ HAVE_OPENSSL=1 make all
```
- To cross compile for ARMv8
```shell
$ CC=aarch64-linux-gnu-gcc make
```
- To cross compile for Windows (benchmarks will not work)
```shell
$ make clean
$ CC=x86_64-w64-mingw32-gcc make test
```
## Running Tests and Benchmarks
```shell
$ make test
$ ./src/test 
Test hash_sse_1...                              [ OK ]
Test hash_sse_1_multiple_blocks...              [ OK ]
Test hash_avx_1...                              [ OK ]
Test hash_avx_1_multiple_blocks...              [ OK ]
Test hash_avx_4...                              [ OK ]
Test hash_avx_4_6blocks...                      [ OK ]
Test hash_avx_8...                              [ OK ]
Test hash_avx_8_13blocks...                     [ OK ]
Test hash_shani...                              [ CPU does not support SHA-ni ]
Test hash_shani_13blocks...                     [ CPU does not support SHA-ni ]
Test hash_avx_16...                             [ OK ]
Test hash_avx_16_30blocks...                    [ OK ]
```
This is running in a CPU that does not support SHA extensions, that is why two tests fail. Your system may output a different combination. 

To run benchmarks:
```shell
$ HAVE_OPENSSL=1 make all
$ ./src/bench 
[==========] Running 9 benchmarks.
[ RUN      ] sse.sse_x1_one_at_time
[       OK ] sse.sse_x1_one_at_time (mean 32.300ms, confidence interval +- 1.725613%)
[ RUN      ] sse.sse_x1
[       OK ] sse.sse_x1 (mean 31.837ms, confidence interval +- 0.327542%)
[ RUN      ] avx.avx_x1_one_at_time
[       OK ] avx.avx_x1_one_at_time (mean 32.299ms, confidence interval +- 0.464452%)
[ RUN      ] avx.avx_x1
[       OK ] avx.avx_x1 (mean 31.855ms, confidence interval +- 0.150833%)
[ RUN      ] avx.avx_x4
[       OK ] avx.avx_x4 (mean 12.368ms, confidence interval +- 1.758262%)
[ RUN      ] avx.avx_x8
[       OK ] avx.avx_x8 (mean 6.519ms, confidence interval +- 2.142718%)
[ RUN      ] shani.shani
[       OK ] shani.shani (mean -20.-559us, confidence interval +- -89188758235664.375000%)
[ RUN      ] shani.shani_one_at_time
[       OK ] shani.shani_one_at_time (mean -3281090326183.-673us, confidence interval +- -9846.737643%)
[ RUN      ] openssl.openssl_one_at_time
[       OK ] openssl.openssl_one_at_time (mean 30.519ms, confidence interval +- 0.330545%)
[==========] 9 benchmarks ran.
[  PASSED  ] 9 benchmarks.
```
The results for the SHA-ni benchmarks are spurious since the CPU does not
support them. Here we see that the benchmark against openssl native
implementation for this CPU runs at the same speed as the single buffer SSE and
AVX implementation, while the AVX2 implementation 8 blocks at a time runs 5
times faster.

A benchmark on a cascade-lake supporting AVX-512:
```shell
./src/bench
[==========] Running 9 benchmarks.
[ RUN      ] sse.sse_x1_one_at_time
[       OK ] sse.sse_x1_one_at_time (mean 29.182ms, confidence interval +- 0.149473%)
[ RUN      ] sse.sse_x1
[       OK ] sse.sse_x1 (mean 28.833ms, confidence interval +- 0.074605%)
[ RUN      ] avx.avx_x1_one_at_time
[       OK ] avx.avx_x1_one_at_time (mean 29.205ms, confidence interval +- 0.138581%)
[ RUN      ] avx.avx_x1
[       OK ] avx.avx_x1 (mean 28.871ms, confidence interval +- 0.200034%)
[ RUN      ] avx.avx_x4
[       OK ] avx.avx_x4 (mean 11.078ms, confidence interval +- 0.140484%)
[ RUN      ] avx.avx_x8
[       OK ] avx.avx_x8 (mean 5.650ms, confidence interval +- 0.118668%)
[ RUN      ] avx.avx_x16
[       OK ] avx.avx_x16 (mean 2.413ms, confidence interval +- 0.223049%)
[ RUN      ] shani.shani
[       OK ] shani.shani (mean -4.-941us, confidence interval +- -1102817647134393.500000%)
[ RUN      ] shani.shani_one_at_time
[       OK ] shani.shani_one_at_time (mean 0.-140us, confidence interval +- -70078699044457400.000000%)
[==========] 9 benchmarks ran.
[  PASSED  ] 9 benchmarks.
```
We see that AVX-512 (x16) runs 12 times faster than a single block
implementation. This is slightly better than a native SHA extension CPU were
gains were about x10. 

A similar benchmark on a Raspberry Pi 4 model B:
```shell
$ ./src/bench 
[==========] Running 3 benchmarks.
[ RUN      ] armv8.neon_x1_one_at_time
[       OK ] armv8.neon_x1_one_at_time (mean 79.853ms, confidence interval +- 0.157599%)
[ RUN      ] armv8.neon_x1
[       OK ] armv8.neon_x1 (mean 79.035ms, confidence interval +- 0.070254%)
[ RUN      ] armv8.neon_x4
[       OK ] armv8.neon_x4 (mean 58.356ms, confidence interval +- 0.076089%)
[==========] 3 benchmarks ran.
[  PASSED  ] 3 benchmarks.
```
We see that a ASIMD version 4 blocks at a time, while not that much of an
improvement as in the x86-64, is still 27% faster. 

## Using the library
The library exposes several architecture dependent SHA implementations. It is the caller responsibility to choose the right one. This can be done at runtime once at application launch. For x86_64 systems for example one can use cpuid.h, see [here](https://github.com/potuz/mammon/blob/main/ssz/hasher.cpp#L43) for an example on how to choose an implementation. 

Most vectorized implementations exploit the fact that independent branches in the Merkle tree can be hashed in "parallel" within one CPU, to take advantage of this, 
Merkleization algorithms that loop over consecutive tree layers hashing two blocks at a time need to be updated to pass the entire layer, or all consecutive blocks. A naive example on how to accomplish this can be found in [this document](https://hackmd.io/80mJ75A5QeeRcrNmqcuU-g?view)

Some examples benchmarks running the algorithms in this library vs prysm's current implementation are
```
goos: linux
goarch: amd64
cpu: AMD Ryzen 5 3600 6-Core Processor
BenchmarkHashBalanceShani-12                  160       7629704 ns/op
BenchmarkHashBalanceShaniPrysm-12              15      74012328 ns/op
PASS

goos: linux
goarch: amd64
cpu: Intel(R) Core(TM) i5-3570 CPU @ 3.40GHz
BenchmarkHashBalanceAVX-4               68      26677965 ns/op
BenchmarkHashBalancePrysm-4              7     165434686 ns/op
PASS

goos: linux
goarch: amd64
cpu: Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz
BenchmarkHashBalanceAVX2-4             121       9711482 ns/op
BenchmarkHashBalancePrysm-4             10     103716714 ns/op
PASS
```

## Nim bindings

The library offers low-level bindings for Nim that can be installed using:

```sh
nimble install https://github.com/OffchainLabs/hashtree/
```

or used in a package with:

```nim
requires "https://github.com/OffchainLabs/hashtree/"
```

## Rust bindings

At the top directory you can run 

```
$ make rust_bindings
```

To run tests:

```
$ make rust_tests
```

See the `examples` directory for examples on how to use the library
