#!/usr/bin/env bash

# NAT to the external world
iptables -t nat -A POSTROUTING -s 192.168.22.0/24 -j SNAT --to-source 10.0.2.15
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1
# This will save the current iptables rules and enable them at startup
apt-get update &&   DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
