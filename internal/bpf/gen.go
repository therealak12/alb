package bpf

// generate boilerplate code for cilium ebpf library

// CLANG_VERSION and CFLAGS are filled by Makefile
//go:generate bpf2go -cc clang-${CLANG_VERSION} -cflags "${CFLAGS}" -target bpfel,bpfeb bpf ./kern/main.c -- -I /usr/include/bpf
