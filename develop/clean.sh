#!/usr/bin/bash

export BR_DEV='albr0'
export BR_ADDR='172.16.10.1'
export ALB_DEV='alb'
export S_DEV='s'
export ALB_NS='alb'

ip netns del $ALB_NS
for i in {1..2}; do
  ip netns del ns$i
done

ip link del $ALB_DEV
for i in {1..2}; do
  ip link del $S_DEV$i
done

ip link del ${BR_DEV}

iptables -t nat -D POSTROUTING -s $BR_ADDR/16 ! -o $BR_DEV -j MASQUERADE
