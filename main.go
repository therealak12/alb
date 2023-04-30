package main

import (
	"flag"
	"github.com/therealak12/alb/internal/bpf"
	"log"
)

var (
	ifaceName string
)

func main() {
	// TODO: setup proper logging

	flag.StringVar(&ifaceName, "iface", "", "target interface name")
	flag.Parse()

	if ifaceName == "" {
		log.Fatalf("interface name is required")
	}

	_ = bpf.New(ifaceName)
}
