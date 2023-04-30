package bpf

import (
	"github.com/cilium/ebpf/link"
	"log"
	"net"
	"time"
)

type BPF struct{}

func New(ifaceName string) *BPF {
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
	})
	if err != nil {
		log.Fatalf("failed to AttachXDP, %v", err)
	}
	defer l.Close()

	time.Sleep(time.Second * 10)

	return &BPF{}
}
