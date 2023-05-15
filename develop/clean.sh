#!/usr/bin/bash

export BR_ADDR='172.16.10.1'

export BR_DEV='albr'
export ALB_DEV='alb'
export CLIENT_DEV='client'

export S_DEV='s'
export ALB_NS='alb'
export CLIENT_NS='client'

ip netns del $ALB_NS
ip netns del $CLIENT_NS
for i in {1..2}; do
  ip netns del "ns$i"
done

ip link del ${BR_DEV}

iptables -t nat -D POSTROUTING -s $BR_ADDR/16 ! -o $BR_DEV -j MASQUERADE
