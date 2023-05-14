package utils

import (
	"encoding/binary"
	"errors"
	"net"
)

func IPv4ToUint32(ipv4 string) (uint32, error) {
	parsedIP := net.ParseIP(ipv4).To4()
	if parsedIP == nil {
		return 0, errors.New("invalid ipv4")
	}
	return binary.LittleEndian.Uint32(parsedIP), nil
}
