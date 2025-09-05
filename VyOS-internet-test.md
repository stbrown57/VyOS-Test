# Test connectivity of the VyOS-internet virtual switch

From the Kea-server container shell in and ping the gateway and an external internet host. This will verify the virtual networks functionality. The default Podman network is a bridge with IPAM similarly to DHCP and a NAT function.

This worked as expected.

```bash
/ # ip addr
2: eth0@if5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 76:23:3a:41:3f:1e brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.89.0.2/24 brd 10.89.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::7423:3aff:fe41:3f1e/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
3: eth1@if7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 5a:5d:7c:42:8d:6a brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.100.1/24 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::585d:7cff:fe42:8d6a/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
/ # ping 10.89.0.1
PING 10.89.0.1 (10.89.0.1): 56 data bytes
64 bytes from 10.89.0.1: seq=0 ttl=64 time=0.203 ms
64 bytes from 10.89.0.1: seq=1 ttl=64 time=0.143 ms
64 bytes from 10.89.0.1: seq=2 ttl=64 time=0.142 ms
^C
--- 10.89.0.1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.142/0.162/0.203 ms
/ # ping 1.1.1.1
PING 1.1.1.1 (1.1.1.1): 56 data bytes
64 bytes from 1.1.1.1: seq=0 ttl=58 time=6.483 ms
64 bytes from 1.1.1.1: seq=1 ttl=58 time=6.704 ms
64 bytes from 1.1.1.1: seq=2 ttl=58 time=6.615 ms
64 bytes from 1.1.1.1: seq=3 ttl=58 time=6.450 ms
^C
--- 1.1.1.1 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 6.450/6.563/6.704 ms
```