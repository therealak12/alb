.PHONY: tidy vendor generate

ALB_DEV ?= wlo1
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

run: generate
	sudo ip netns exec alb /usr/local/go/bin/go run main.go --iface $(ALB_DEV)
	#sudo /usr/local/go/bin/go run -exec "sudo ip netns exec alb" main.go --iface $(ALB_DEV)

setup-dev-env:
	sudo ./develop/setup.sh

clean-dev-env:
	sudo ./develop/clean.sh

ns-tcpdump:
	sudo ip netns exec $(NS) tcpdump -l -nn
