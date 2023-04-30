# bfp load balancer

## Install bpf2go

```shell
go install github.com/cilium/ebpf/cmd/bpf2go@latest
```

## Install libbfp

```shell
git clone https://github.com/libbpf/libbpf.git /tmp/libbpf
cd /tmp/libbpf/src
make -j`nproc`
BUILD_STATIC_ONLY=1 NO_PKG_CONFIG=1 PREFIX=/usr/local/bpf make install
```

## Generate bpf2go boilerplate
```shell
make generate
```
