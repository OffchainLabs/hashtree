# hashtree nim bindings
# Copyright (c) 2024 Status Research & Development GmbH
# Licensed and distributed under
#   * MIT license (license terms in the root directory or at https://opensource.org/licenses/MIT).
# This file may not be copied, modified, or distributed except according to those terms.

{.pragma: hashtreedecl, importc, cdecl, gcsafe, raises: [].}

import std/[os, strutils]

const srcDir = currentSourcePath.parentDir.replace('\\', '/') & "/src/"

{.compile: srcDir & "hashtree.c".}
{.compile: srcDir & "sha256_generic.c".}

# The assember files use gnu/binutils-specific macros and lack mac support in
# general
when
  ((defined(linux) or defined(windows)) and defined(gcc)) or
  (defined(linux) and defined(clang)) or
  (defined(macosx) and defined(clang) and defined(arm64)):

  const cflags =
    when defined(clang) and defined(linux):
      # The integrated `clang` assembler uses a different macro syntax but on
      # linux we can convince it to use the system assembler which _tends_ to be
      # the binutils variant
      "-fno-integrated-as"
    else:
      ""

  when defined(arm64):
    {.compile(srcDir & "sha256_armv8_crypto.S", cflags).}
    {.compile(srcDir & "sha256_armv8_neon_x1.S", cflags).}
    {.compile(srcDir & "sha256_armv8_neon_x4.S", cflags).}

  elif defined(amd64):
    {.compile(srcDir & "sha256_avx_x1.S", cflags).}
    {.compile(srcDir & "sha256_avx_x4.S", cflags).}
    {.compile(srcDir & "sha256_avx_x8.S", cflags).}
    {.compile(srcDir & "sha256_avx_x16.S", cflags).}
    {.compile(srcDir & "sha256_shani.S", cflags).}
    {.compile(srcDir & "sha256_sse_x1.S", cflags).}

type HashFcn* = proc(output: pointer, input: pointer, count: uint64) {.
  cdecl, noSideEffect, gcsafe, raises: [].}

proc hashtree_init*(override: HashFcn) {.hashtreedecl.}
func hashtree_hash*(output: pointer, input: pointer, count: uint64) {.
  hashtreedecl.}
