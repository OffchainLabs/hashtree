# MIT License
# 
# Copyright (c) 2021 Prysmatic Labs
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

###############################################################################
# Constants and Configuration Variables
###############################################################################
VERSION := 0.2.0
OUT_DIR ?= $(CURDIR)/../build
BASE_DIR := $(CURDIR)/../
OBJ_DIR := $(OUT_DIR)/obj
LIB_DIR := $(OUT_DIR)/lib

# Ensure these directories exist
$(shell mkdir -p $(OBJ_DIR))
$(shell mkdir -p $(LIB_DIR))

ASFLAGS += -g -fpic
CFLAGS +=  -g -Wall -Werror -O3
LDFLAGS += -L .
testlibs = -lhashtree
benchlibs = -lhashtree -lm

###############################################################################
# Platform Configuration
###############################################################################
# Platform detection.
ifndef OS
    OS := $(shell uname -s)
endif

ifeq ($(OS),Windows_NT)
	PLATFORM = Windows
else
	ifeq ($(OS),Darwin)
		PLATFORM = Darwin
	else
		PLATFORM = Linux
	endif
endif

# architecture detection
ifdef CC
  ARM = $(shell $(CC) -dM -E - < /dev/null | grep "aarch" | awk '{ print $$3 }')
  RISCV = $(shell $(CC) -dM -E - < /dev/null | grep "riscv 1" | awk '{ print $$3 }')
  ifneq ($(findstring mingw, $(CC)),)
	ifneq ($(ARM),1)
		PLATFORM = Windows
  	endif
  endif
else
  ARCH = $(shell uname -m)
  ARM = $(shell echo $(ARCH) | grep -E '^(arm|aarch64)' >/dev/null && echo 1 || echo 0)
  RISCV = $(shell echo $(ARCH) | grep -E '^riscv' >/dev/null && echo 1 || echo 0)
endif

# Cross-platform compiler selection
# check for default, skip setting if user passed in specific cross-compilation lib
ifeq ($(CC), cc)
	ifeq ($(PLATFORM),Darwin)
		CC = clang
	else
		CC = gcc
	endif
endif

ifeq ($(HAVE_OPENSSL),1)
	CFLAGS += -DHAVE_OPENSSL
	benchlibs += -lcrypto
	testlibs += -lcrypto
endif

ifeq ($(PLATFORM),Windows)
	libname = $(LIB_DIR)/libhashtree.lib
else
	libname = $(LIB_DIR)/libhashtree.a
endif

ifeq ($(ARM), 1)
	OBJ_LIST = $(OBJ_DIR)/sha256_armv8_neon_x4.o\
		$(OBJ_DIR)/sha256_armv8_neon_x1.o\
		$(OBJ_DIR)/sha256_armv8_crypto.o\
		$(OBJ_DIR)/sha256_generic.o\
		$(OBJ_DIR)/hashtree.o
else ifeq ($(RISCV), 1)
	CFLAGS += -march=rv64gc_zbb_zk
	ASFLAGS += -march=rv64gc_zbb_zk
	OBJ_LIST = $(OBJ_DIR)/sha256_riscv_x1.o\
		   $(OBJ_DIR)/sha256_riscv_zbb_x1.o\
		   $(OBJ_DIR)/sha256_riscv_crypto.o\
		$(OBJ_DIR)/sha256_generic.o\
		$(OBJ_DIR)/hashtree.o
else
	OBJ_LIST = $(OBJ_DIR)/sha256_shani.o\
		$(OBJ_DIR)/sha256_avx_x16.o\
		$(OBJ_DIR)/sha256_avx_x8.o\
		$(OBJ_DIR)/sha256_avx_x4.o\
		$(OBJ_DIR)/sha256_avx_x1.o\
		$(OBJ_DIR)/sha256_sse_x1.o\
		$(OBJ_DIR)/sha256_generic.o\
		$(OBJ_DIR)/hashtree.o
endif

###############################################################################
# Commands
###############################################################################

.PHONY : clean .FORCE
.FORCE: 

$(OBJ_DIR)/%.o: %.S
	$(CC) $(ASFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(libname): $(OBJ_LIST)
	$(AR) rcs $@ $(OBJ_LIST)

ifeq ($(PLATFORM),Windows)
all: $(libname) test
else
all: $(libname) test bench
endif

go_bindings: $(libname)
	cp $(libname) $(BASE_DIR)/hashtree.syso
	go build $(BASE_DIR)

test: hashtree.h acutest.h test.c $(libname)
	$(CC) $(CFLAGS) $(LDFLAGS) -L$(LIB_DIR) -o $(OUT_DIR)/test test.c $(testlibs)

bench: hashtree.h ubench.h bench.c $(libname)
	$(CC) $(CFLAGS) $(LDFLAGS) -L$(LIB_DIR) -o $(OUT_DIR)/bench bench.c $(benchlibs)

clean:
	-rm -f $(OBJ_LIST) $(LIB_DIR)/libhashtree.a $(LIB_DIR)/libhashtree.lib $(OUT_DIR)/test $(OUT_DIR)/test.exe $(OUT_DIR)/bench hashtree.pc $(BASE_DIR)/hashtree.syso

ifeq ($(PREFIX),)
PREFIX := /usr
endif

hashtree.pc: .FORCE
	@echo 'prefix='$(PREFIX) > hashtree.pc
	@echo 'exec_prefix=$${prefix}' >> hashtree.pc
	@echo 'libdir=$${prefix}/lib' >> hashtree.pc
	@echo 'includedir=$${prefix}/include' >> hashtree.pc
	@echo '' >> hashtree.pc
	@echo 'Name: hashtree' >> hashtree.pc
	@echo 'Description: Fast hashing of Merkle trees' >> hashtree.pc
	@echo 'Version: '$(VERSION) >> hashtree.pc
	@echo 'URL: https://github.com/OffchainLabs/hashtree' >> hashtree.pc
	@echo 'LIBS: -L$${libdir} -lhashtree' >> hashtree.pc
	@echo 'Cflags: -I$${includedir}'>> hashtree.pc

ifneq ($(PLATFORM),Windows)
install: $(libname) hashtree.pc
	install -d $(DESTDIR)$(PREFIX)/lib
	install -m 644 $(libname) $(DESTDIR)$(PREFIX)/lib/ 
	install -d $(DESTDIR)$(PREFIX)/include
	install -m 644 hashtree.h $(DESTDIR)$(PREFIX)/include/
	install -d $(DESTDIR)$(PREFIX)/lib/pkgconfig
	install -m 644 hashtree.pc $(DESTDIR)$(PREFIX)/lib/pkgconfig/hashtree.pc

uninstall: $(libname)
	rm $(DESTDIR)$(PREFIX)/lib/libhashtree.a
	rm $(DESTDIR)$(PREFIX)/include/hashtree.h
endif

