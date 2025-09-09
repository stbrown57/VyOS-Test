# VyOS LAN Network

This is a Podman network flagged as "internal" without IPAM. It should funtion as a L2 switch.

Try this [L2 simulation in Podman]



```bash
podman network create --internal --ipam-driver=none vyos-lan
```

```json
[
     {
          "name": "vyos-lan",
          "id": "f04a6e850f8d9df27c4cac73c464635216d2be8a99dc03830ba0144fc7191eef",
          "driver": "bridge",
          "network_interface": "podman4",
          "created": "2025-08-27T20:52:02.99090114-04:00",
          "ipv6_enabled": false,
          "internal": true,
          "dns_enabled": false,
          "ipam_options": {
               "driver": "none"
          },
          "containers": {
               "9b16a6677dda37c780e244130786fc8c463342d92780099cc8a837115bf828ca": {
                    "name": "vyos-2",
                    "interfaces": {
                         "eth1": {
                              "mac_address": "ae:f4:c6:9a:da:4e"
                         }
                    }
               },
               "cf76270c9e8b2a68e1549a0f29f755fcb1ea4c9e93edbad325834ce650fb7b5a": {
                    "name": "vyos-1",
                    "interfaces": {
                         "eth1": {
                              "mac_address": "22:be:54:d0:0f:11"
                         }
                    }
               }
          }
     }
]
```

## Instance vyos-1

Show interface:

```
Interface    IP Address      MAC                VRF        MTU  S/L    Description
-----------  --------------  -----------------  -------  -----  -----  -------------
eth0         -               c2:f2:22:3b:e4:6b  default   1500  u/u    WAN
eth1         192.168.1.2/24  b6:12:18:97:94:4f  default   1500  u/u    LAN
lo           127.0.0.1/8     00:00:00:00:00:00  default  65536  u/u
             ::1/128
```

Set the MAC address to match the network description.

```
Interface    IP Address      MAC                VRF        MTU  S/L    Description
-----------  --------------  -----------------  -------  -----  -----  -------------
eth0         -               c2:f2:22:3b:e4:6b  default   1500  u/u    WAN
eth1         192.168.1.2/24  22:be:54:d0:0f:11  default   1500  u/u    LAN
lo           127.0.0.1/8     00:00:00:00:00:00  default  65536  u/u
             ::1/128
```

## Instance vyos-2

Show interfaces:

```
Interface    IP Address      MAC                VRF        MTU  S/L    Description
-----------  --------------  -----------------  -------  -----  -----  -------------
eth0         -               4a:72:19:0b:d2:4b  default   1500  A/D    WAN
eth1         192.168.1.3/24  ba:52:c6:bb:f1:e1  default   1500  u/u    LAN
lo           127.0.0.1/8     00:00:00:00:00:00  default  65536  u/u
             ::1/128
```

Set the MAC address to match the network description.

```

Interface    IP Address      MAC                VRF        MTU  S/L    Description
-----------  --------------  -----------------  -------  -----  -----  -------------
eth0         -               4a:72:19:0b:d2:4b  default   1500  A/D    WAN
eth1         192.168.1.3/24  ae:f4:c6:9a:da:4e  default   1500  u/u    LAN
lo           127.0.0.1/8     00:00:00:00:00:00  default  65536  u/u
             ::1/128
```

OK,monitoring trafic on both vyos-1 and vyos-2, them ping from vyos-2 to vyos-1.

Monitor on vyos-1

```
vyos@bfnetgw:~$ monitor traffic interface eth1
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
16:34:10.322375 ARP, Request who-has 192.168.1.2 tell 192.168.1.3, length 28
16:34:10.322385 ARP, Reply 192.168.1.2 is-at 22:be:54:d0:0f:11 (oui Unknown), length 28
16:34:43.090678 ARP, Request who-has 192.168.1.2 tell 192.168.1.3, length 28
16:34:43.090700 ARP, Reply 192.168.1.2 is-at 22:be:54:d0:0f:11 (oui Unknown), length 28
16:35:15.858658 ARP, Request who-has 192.168.1.2 tell 192.168.1.3, length 28
16:35:15.858678 ARP, Reply 192.168.1.2 is-at 22:be:54:d0:0f:11 (oui Unknown), length 28
```

arp table on vyos-1

```
vyos@bfnetgw:~$ arp
Address                  HWtype  HWaddress           Flags Mask            Iface
192.168.1.3              ether   ae:f4:c6:9a:da:4e   C                     eth1
vyos@bfnetgw:~$
```

Monitor on vyos-2

```
vyos@gwbackup:~$ monitor traffic interface eth1 
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
16:34:04.850774 IP 192.168.1.3 > 192.168.1.2: ICMP echo request, id 5, seq 1, length 64
16:34:05.906682 IP 192.168.1.3 > 192.168.1.2: ICMP echo request, id 5, seq 2, length 64
16:34:06.930764 IP 192.168.1.3 > 192.168.1.2: ICMP echo request, id 5, seq 3, length 64
16:34:07.954711 IP 192.168.1.3 > 192.168.1.2: ICMP echo request, id 5, seq 4, length 64
16:34:08.978747 IP 192.168.1.3 > 192.168.1.2: ICMP echo request, id 5, seq 5, length 64
16:34:10.003369 IP 192.168.1.3 > 192.168.1.2: ICMP echo request, id 5, seq 6, length 64
16:34:10.322356 ARP, Request who-has 192.168.1.2 tell 192.168.1.3, length 28
16:34:10.322396 ARP, Reply 192.168.1.2 is-at 22:be:54:d0:0f:11 (oui Unknown), length 28
```

arp table on vyos-2

```
vyos@gwbackup:~$ arp 
Address                  HWtype  HWaddress           Flags Mask            Iface
192.168.1.2              ether   22:be:54:d0:0f:11   C                     eth1
```

Ping command:

```
vyos@gwbackup:~$ ping 192.168.1.2
PING 192.168.1.2 (192.168.1.2) 56(84) bytes of data.
^C
--- 192.168.1.2 ping statistics ---
92 packets transmitted, 0 received, 100% packet loss, time 93215ms
```

The ARP table looks correct, but the ICMP packets are not getting a reply. This could be firewall related.

Try to use two [clients](./VyOS-LAN-Clients.md)) without firewalling between.

