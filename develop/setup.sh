#!/usr/bin/bash

# a more detailed explanation about the setup can be found here:
# https://medium.com/techlog/diving-into-linux-networking-and-docker-bridge-veth-and-iptables-a05eb27b1e72

export BR_DEV='albr0'
export BR_ADDR='172.16.10.1'
export ALB_DEV='alb'
export S_DEV='s'
export ALB_NS='alb'
export ALB_PEER=${ALB_DEV}p


# create namespaces
ip netns add $ALB_NS
for i in {1..2}; do
  ip netns add ns$i
done

# create veth pairs
ip link add $ALB_DEV type veth peer name $ALB_PEER netns $ALB_NS
ip link set dev $ALB_DEV up
ip -n $ALB_NS link set dev $ALB_PEER up
for i in {1..2}; do
  SERVER_DEVICE=$S_DEV$i
  PEER_DEVICE=p$i
  NS=ns$i
  ip link add $SERVER_DEVICE type veth peer name $PEER_DEVICE netns $NS
  ip link set dev $SERVER_DEVICE up
  ip -n $NS link set dev $PEER_DEVICE up
done

# up loopback devices
ip -n $ALB_NS link set dev lo up
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
ip -n $ALB_NS addr add 172.16.11.2/16 dev $ALB_PEER
ip -n $ALB_NS route add default via $BR_ADDR dev $ALB_PEER
for i in {1..2}; do
  ip -n "ns$i" addr add "172.16.2${i}.2/16" dev "p$i"
  ip -n "ns$i" route add default via $BR_ADDR dev "p$i"
done

# connect ifaces to bridge
ip link set alb master $BR_DEV
ip link set s1 master $BR_DEV
ip link set s2 master $BR_DEV
