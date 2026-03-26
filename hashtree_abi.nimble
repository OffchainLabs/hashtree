# hashtree nim bindings
# Copyright (c) 2024 Status Research & Development GmbH
# Licensed and distributed under
#   * MIT license (license terms in the root directory or at https://opensource.org/licenses/MIT).
# This file may not be copied, modified, or distributed except according to those terms.

mode = ScriptMode.Verbose

packageName   = "hashtree_abi"
version       = "0.2.4"
author        = "Prysmatic labs, Status Research and Development GmbH"
description   = "Low-level ABI package for hashtree, a SHA256 implementation specialized for merkle trees and 64-byte chunks"
license       = "MIT"
installDirs   = @["src"]
installFiles  = @["hashtree_abi.nim"]

requires "nim >= 1.6.0"
