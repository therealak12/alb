.PHONY: tidy vendor generate run setup-dev-env clean-dev-env ns-tcpdump compile-xdp-pass attach-xdp-pass uint-to-ipv4

DEV ?= wlo1
CLANG_VERSION ?= 14
CFLAGS := -O2 -g -Wall -Werror $(CFLAGS)

tidy:
	go mod tidy

vendor: tidy
	go mod vendor

generate: export CLANG_VERSION := $(CLANG_VERSION)
generate: export CFLAGS := $(CFLAGS)
generate:
	go generate ./...

run-in-ns: generate
	sudo ip netns exec $(NS) /usr/local/go/bin/go run main.go

run: generate
	sudo /usr/local/go/bin/go run main.go

setup-dev-env:
	sudo ./develop/setup.sh

clean-dev-env:
	sudo ./develop/clean.sh

ns-tcpdump:
	sudo ip netns exec $(NS) tcpdump -l -nn tcp

compile-xdp-pass:
	clang-$(CLANG_VERSION) -target bpf -O2 -c develop/xdp_pass.c -o develop/xdp_pass.o

attach-xdp-pass: compile-xdp-pass
	sudo bpftool net detach xdpgeneric dev $(DEV)
	sudo rm -f /sys/fs/bpf/$(TARGET)
	sudo bpftool prog load develop/xdp_pass.o /sys/fs/bpf/$(TARGET)
	sudo bpftool net attach xdpgeneric pinned /sys/fs/bpf/$(TARGET) dev $(DEV)

uint-to-ipv4:
	gcc develop/uint_to_ipv4.c -o /tmp/toipv4.o
	/tmp/toipv4.o $(UINTIP)
