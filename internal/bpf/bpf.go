package bpf

import (
	"net"

	"github.com/cilium/ebpf"
	"github.com/cilium/ebpf/link"
	"github.com/cilium/ebpf/rlimit"

	"github.com/therealak12/alb/config"
	"github.com/therealak12/alb/internal/utils"
)

type BPF struct {
	links []link.Link
	objs  []*bpfObjects
}

func New(cfgPath string) (*BPF, error) {
	cfg := config.New(cfgPath)
	bpfCfg, err := getBpfConfig(cfg)
	if err != nil {
		return nil, err
	}

	bpf := &BPF{}

	if err := rlimit.RemoveMemlock(); err != nil {
		return nil, err
	}

	iface, err := net.InterfaceByName(cfg.IfaceName)
	if err != nil {
		return nil, err
	}

	objs := bpfObjects{}
	if err := loadBpfObjects(&objs, nil); err != nil {
		return nil, err
	}
	bpf.objs = append(bpf.objs, &objs)

	l, err := link.AttachXDP(link.XDPOptions{
		Program:   objs.Alb,
		Interface: iface.Index,
		Flags:     link.XDPGenericMode,
	})
	if err != nil {
		return nil, err
	}
	bpf.links = append(bpf.links, l)

	if err := bpf.UpdateSettings(bpfCfg); err != nil {
		return nil, err
	}

	return bpf, nil
}

func getBpfConfig(cfg *config.Config) (bpfConfig, error) {
	lbIP, err := utils.IPv4ToUint32(cfg.LBDev.Addr)
	if err != nil {
		return bpfConfig{}, err
	}
	clientIP, err := utils.IPv4ToUint32(cfg.ClientDev.Addr)
	if err != nil {
		return bpfConfig{}, err
	}

	lbMac, err := utils.MacToUint8Array(cfg.LBDev.Mac)
	if err != nil {
		return bpfConfig{}, err
	}
	clientMac, err := utils.MacToUint8Array(cfg.ClientDev.Mac)
	if err != nil {
		return bpfConfig{}, err
	}

	return bpfConfig{
		ClientMac:    clientMac,
		ClientIp:     clientIP,
		LbMac:        lbMac,
		LbIp:         lbIP,
		BackendCount: uint32(cfg.BackendCount),
	}, nil
}

func (b *BPF) UpdateSettings(settings bpfConfig) error {
	var key uint32 = 0

	for _, obj := range b.objs {
		if err := obj.bpfMaps.Settings.Update(key, settings, ebpf.UpdateAny); err != nil {
			return err
		}
	}

	return nil
}

func (b *BPF) Stop() {
	for _, l := range b.links {
		l.Close()
	}

	for _, o := range b.objs {
		o.Close()
	}
}
