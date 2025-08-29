# VyOS Podman Network (vyos-lan) Client Test

Start two instances of the "client" container and inspect the network.

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
               "481ba49998285d23f083c6c919968acad582946bc6ed7f9d90a57dd4acc261d5": {
                    "name": "test-2",
                    "interfaces": {
                         "eth0": {
                              "mac_address": "8e:e3:b1:65:0a:3d"
                         }
                    }
               },
               "647b5319d26d76918a5c039c95ea01d2e42f01ed7d51410dd6b67b22310af1f5": {
                    "name": "test-1",
                    "interfaces": {
                         "eth0": {
                              "mac_address": "7a:fa:e7:c0:7f:73"
                         }
                    }
               },
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

## Node test-1

```
2: eth0@if13: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 7a:fa:e7:c0:7f:73 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::78fa:e7ff:fec0:7f73/64 scope link 
       valid_lft forever preferred_lft forever
```

## Node test-2

```
2: eth0@if14: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 8e:e3:b1:65:0a:3d brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::8ce3:b1ff:fe65:a3d/64 scope link 
       valid_lft forever preferred_lft forever
```

### Test

OK I had to set the interface address and route manually on both instances.

Node vyos-1

```
# ip addr add 192.168.1.17 dev eth0
# ip route add default dev eth0
```

Node vyos-2

```
# ip addr add 192.168.1.16 dev eth0
# ip route add default dev eth0
```

I stated a tcpdump session on both nodes and pinged from vyos-1 to vyos-2.

There were no ping replies:

```
root@tarmac:/home/stbrown# podman exec -it vyos-1 sh
ping 192.168.1.17
PING 192.168.1.17 (192.168.1.17) 56(84) bytes of data.
^C
--- 192.168.1.17 ping statistics ---
15 packets transmitted, 0 received, 100% packet loss, time 14330ms
```

Monitor vyos-2

```
/ # tcpdump -i eth0
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
17:19:48.578598 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:19:48.594621 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:19:49.586642 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:19:49.650574 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:19:50.610490 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:19:50.674573 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:19:53.584123 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:19:53.600304 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:19:54.642575 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:19:54.642611 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:19:58.605723 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:20:04.626615 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:20:05.650629 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:20:08.608417 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:20:09.618617 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:20:10.642414 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:20:33.753019 ARP, Request who-has 192.168.1.17 tell 192.168.1.2, length 28
17:20:33.753060 ARP, Reply 192.168.1.17 is-at 7a:fa:e7:c0:7f:73 (oui Unknown), length 28
17:20:33.754628 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
```

arp

```
Address                  HWtype  HWaddress           Flags Mask            Iface
192.168.1.16             ether   8e:e3:b1:65:0a:3d   C                     eth0
1.1.1.1                          (incomplete)                              eth0
192.168.1.2              ether   22:be:54:d0:0f:11   C                     eth0
```

Monitor vyos-1

```
/ # tcpdump -i eth0
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
17:19:48.499412 IP6 fe80::8ce3:b1ff:fe65:a3d > ff02::2: ICMP6, router solicitation, length 16
17:19:48.578588 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:19:48.594639 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:19:49.586591 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:19:49.650616 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:19:50.610402 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:19:50.674658 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:19:53.584114 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:19:53.600314 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:19:54.642553 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:19:54.642653 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:19:58.596900 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:19:58.605750 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:20:33.753016 ARP, Request who-has 192.168.1.17 tell 192.168.1.2, length 28
17:20:33.754644 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:20:33.850697 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:20:34.770591 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:20:34.898359 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:20:35.794639 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:20:35.922571 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:23:37.874615 IP6 fe80::c0b3:dfff:feeb:afdb > ff02::2: ICMP6, router solicitation, length 16
17:23:37.931190 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:23:38.962615 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:23:39.986611 ARP, Request who-has 1.1.1.1 tell 192.168.1.16, length 28
17:24:08.280739 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:24:09.298465 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:24:10.322636 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:24:13.286556 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:24:14.290612 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:24:15.314648 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:24:18.290472 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:24:19.346612 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
17:24:20.370699 ARP, Request who-has 1.1.1.1 tell 192.168.1.17, length 28
```

arp
```
Address                  HWtype  HWaddress           Flags Mask            Iface
1.1.1.1                          (incomplete)                              eth0
192.168.1.17             ether   7a:fa:e7:c0:7f:73   C                     eth0
```

