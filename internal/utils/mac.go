package utils

import (
	"errors"
	"net"
)

func MacToUint8Array(mac string) ([6]uint8, error) {
	uint8Mac := [6]uint8{}

	parsedMac, err := net.ParseMAC(mac)
	if err != nil {
		return uint8Mac, err
	}

	if len(parsedMac) != 6 {
		return uint8Mac, errors.New("invalid mac")
	}

	for i, b := range parsedMac {
		uint8Mac[i] = b
	}

	return uint8Mac, nil
}
