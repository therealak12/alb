package main

import (
	"flag"
	"log"
	"time"

	"github.com/therealak12/alb/internal/bpf"
)

var (
	cfgPath string
)

func main() {
	// TODO: setup proper logging

	flag.StringVar(&cfgPath, "config-path", "config/config.yaml", "path to config file")
	flag.Parse()

	b, err := bpf.New(cfgPath)
	if err != nil {
		log.Fatalf("failed to initialize bpf module, %v", err)
	}
	defer b.Stop()

	time.Sleep(time.Hour)
}
