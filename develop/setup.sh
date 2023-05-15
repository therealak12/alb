#!/usr/bin/bash

# The following script setup up and environment similar to running 3 docker containers with default bridge network.
# A more detailed explanation about the setup can be found here:
# https://medium.com/techlog/diving-into-linux-networking-and-docker-bridge-veth-and-iptables-a05eb27b1e72

export BR_ADDR='172.16.10.1'
export ALB_ADDR='172.16.31.2'
export CLIENT_ADDR='172.16.41.2'

export BR_DEV='albr'
export ALB_DEV='alb'
export CLIENT_DEV='client'
export S_DEV='s'

export ALB_NS='alb'
export CLIENT_NS='client'

export ALB_PEER=${ALB_DEV}p
export CLIENT_PEER=${CLIENT_DEV}p

export XDP_MODE="generic" # or native


# create namespaces
ip netns add $ALB_NS
ip netns add $CLIENT_NS
for i in {1..2}; do
  ip netns add ns$i
done

# create veth pairs
ip link add $ALB_DEV type veth peer name $ALB_PEER netns $ALB_NS
ip link set dev $ALB_DEV up
ip -n $ALB_NS link set dev $ALB_PEER up
ip link add $CLIENT_DEV type veth peer name $CLIENT_PEER netns $CLIENT_NS
ip link set dev $CLIENT_DEV up
ip -n $CLIENT_NS link set dev $CLIENT_PEER up
for i in {1..2}; do
  SERVER_DEVICE=$S_DEV$i
  PEER_DEVICE=s${i}p
  NS=ns$i
  ip link add $SERVER_DEVICE type veth peer name $PEER_DEVICE netns $NS
  ip link set dev $SERVER_DEVICE up
  ip -n $NS link set dev $PEER_DEVICE up
done

# up loopback devices
ip -n $ALB_NS link set dev lo up
ip -n $CLIENT_NS link set dev lo up
for i in {1..2}; do
  ip -n ns$i link set dev lo up
done

# create bridge
ip link add $BR_DEV type bridge
ip addr add $BR_ADDR/16 dev $BR_DEV
ip link set dev $BR_DEV up
# masquerade the outgoing traffic (i.e. from namespaces to host)
iptables -t nat -A POSTROUTING -s $BR_ADDR/16 ! -o $BR_DEV -j MASQUERADE

# setup ns ip and routes
ip -n $ALB_NS addr add $ALB_ADDR/16 dev $ALB_PEER
ip -n $ALB_NS route add default via $BR_ADDR dev $ALB_PEER
ip -n $CLIENT_NS addr add $CLIENT_ADDR/16 dev $CLIENT_PEER
ip -n $CLIENT_NS route add default via $BR_ADDR dev $CLIENT_PEER
for i in {1..2}; do
  PEER_DEVICE=s${i}p
  ip -n "ns$i" addr add "172.16.${i}1.2/16" dev $PEER_DEVICE
  ip -n "ns$i" route add default via $BR_ADDR dev $PEER_DEVICE
done

# connect ifaces to bridge
ip link set $ALB_DEV master $BR_DEV
ip link set $CLIENT_DEV master $BR_DEV
for i in {1..2}; do
  ip link set "s$i" master $BR_DEV
done

# create config
cp config/sample-config.yaml config/config.yaml
ALB_MAC=$(ip netns exec alb cat /sys/class/net/albp/address)
CLIENT_MAC=$(ip netns exec client cat /sys/class/net/clientp/address)
S1_MAC=$(ip netns exec ns1 cat /sys/class/net/s1p/address)
S2_MAC=$(ip netns exec ns2 cat /sys/class/net/s2p/address)
sed -i "s/ALB_MAC/$ALB_MAC/" config/config.yaml
sed -i "s/CLIENT_MAC/$CLIENT_MAC/" config/config.yaml
sed -i "s/S1_MAC/$S1_MAC/" config/config.yaml
sed -i "s/S2_MAC/$S2_MAC/" config/config.yaml

exit 0

# run http servers
for i in {1..2}; do
  ip netns exec "ns$i" python3 -m http.server 80 2>&1 > "/tmp/backend${i}_logs" &
done

# attach xdp_pass (not required in xdp generic mode)
if [ "$XDP_MODE" = "native" ]; then
  sudo rm -f /sys/fs/bpf/xdp_pass
  sudo bpftool prog load develop/xdp_pass.o /sys/fs/bpf/xdp_pass
  for i in {1..2}; do
    sudo bpftool net attach xdpgeneric pinned /sys/fs/bpf/xdp_pass dev "s$i"
  done
fi
