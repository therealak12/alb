package bpf

import (
	"log"
	"net"
	"time"

	"github.com/cilium/ebpf/link"
	"github.com/cilium/ebpf/rlimit"
)

type BPF struct{}

func New(ifaceName string) *BPF {
	if err := rlimit.RemoveMemlock(); err != nil {
		log.Fatalf("failed to remove memory lock, %v", err)
	}

	iface, err := net.InterfaceByName(ifaceName)
	if err != nil {
		log.Fatalf("lookup network iface %q: %s", ifaceName, err)
	}

	objs := bpfObjects{}
	if err := loadBpfObjects(&objs, nil); err != nil {
		log.Fatalf("failed to loadBpfObjects, %v", err)
	}
	defer objs.Close()

	l, err := link.AttachXDP(link.XDPOptions{
		Program:   objs.Alb,
		Interface: iface.Index,
		Flags:     link.XDPGenericMode,
	})
	if err != nil {
		log.Fatalf("failed to AttachXDP, %v", err)
	}
	defer l.Close()

	time.Sleep(time.Hour)

	return &BPF{}
}
