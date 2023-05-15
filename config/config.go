package config

import (
	"log"

	"github.com/knadh/koanf/parsers/yaml"
	"github.com/knadh/koanf/providers/file"
	"github.com/knadh/koanf/providers/structs"
	"github.com/knadh/koanf/v2"
)

type Device struct {
	Name string `koanf:"name"`
	Mac  string `koanf:"mac"`
	Addr string `koanf:"addr"`
}

type Config struct {
	IfaceName    string   `koanf:"iface_name"`
	LBDev        Device   `koanf:"lb_dev"`
	ClientDev    Device   `koanf:"client_dev"`
	BackendCount int32    `koanf:"backend_count"`
	BackendDevs  []Device `koanf:"backend_devs"`
}

var (
	defaultConfig = Config{
		IfaceName: "albp",
		LBDev: Device{
			Name: "alb",
			Mac:  "ea:5a:e0:c3:fd:33",
			Addr: "172.16.11.2",
		},
		ClientDev: Device{
			Name: "client",
			Mac:  "ea:5a:e0:c3:fd:33",
			Addr: "172.16.21.2",
		},
		BackendCount: 2,
		BackendDevs: []Device{
			{
				Name: "s1",
				Mac:  "ea:5a:e0:c3:fd:33",
				Addr: "172.16.31.2",
			},
			{
				Name: "s2",
				Mac:  "ea:5a:e0:c3:fd:33",
				Addr: "172.16.41.2",
			},
		},
	}
)

func New(path string) *Config {
	var cfg Config

	k := koanf.New(".")

	if err := k.Load(structs.Provider(defaultConfig, "koanf"), nil); err != nil {
		log.Fatalf("failed to load default config, %v", err)
	}

	if err := k.Load(file.Provider(path), yaml.Parser()); err != nil {
		log.Printf("error loading file config: %s", err)
	}

	if err := k.Unmarshal("", &cfg); err != nil {
		log.Fatalf("error unmarshalling config: %s", err)
	}

	return &cfg
}
