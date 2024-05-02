libhashtree:
	$(MAKE) -C src

clean:
	$(MAKE) -C src clean
	cd rust_bindings && cargo clean

test:
	$(MAKE) -C src test

bench:
	$(MAKE) -C src bench

.PHONY: rust_bindings, rust_tests
rust_bindings:
	cd rust_bindings && cargo build --release
rust_tests:
	cd rust_bindings && cargo test

all:
	$(MAKE) -C src all

install:
	$(MAKE) -C src install

uninstall:
	$(MAKE) -C src uninstall
