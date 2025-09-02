#!/bin/sh

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Manually assign the static IP to the eth1 interface
ip addr add 192.168.100.1/24 dev eth1

# Set the default gateway
ip route add default via 10.89.0.1

# Set NAT
iptables-restore < /etc/iptables/rules.v4

# Start the Kea services
kea-dhcp4 -c /etc/kea/kea-dhcp4.conf &
kea-ctrl-agent -c /etc/kea/kea-ctrl-agent.conf &
wait
