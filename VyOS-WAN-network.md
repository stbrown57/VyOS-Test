# VyOS-WAN Network

This network was defined with no IPAM and an internal flag. The idea is to simulate a simple layer 2 switch.

``` bash
podman network create --internal --ipam-driver=none vyos-wan
```

```json
[
     {
          "name": "vyos-wan",
          "id": "09ff694d0d7956840e03eeeb2679331c552cc3fe245a29219304889143548660",
          "driver": "bridge",
          "network_interface": "podman3",
          "created": "2025-08-27T20:51:58.018348223-04:00",
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
                         "eth0": {
                              "mac_address": "42:4b:18:5d:85:c5"
                         }
                    }
               },
               "c01354f8c2abd17cdf88d192c03e8393eb8c52962f349e975b6283df625ab443": {
                    "name": "kea-server",
                    "interfaces": {
                         "eth1": {
                              "mac_address": "5a:5d:7c:42:8d:6a"
                         }
                    }
               },
               "cf76270c9e8b2a68e1549a0f29f755fcb1ea4c9e93edbad325834ce650fb7b5a": {
                    "name": "vyos-1",
                    "interfaces": {
                         "eth0": {
                              "mac_address": "c2:f2:22:3b:e4:6b"
                         }
                    }
               }
          }
     }
]
```

This provides the expected MAC addresses for each of the three interfaces (Kea-server, vyos-1, vyos-2) Verify these and check the arp table.

## Kea-server

```bash
3: eth1@if7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 5a:5d:7c:42:8d:6a brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.100.1/24 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::585d:7cff:fe42:8d6a/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
```

There is no arp entry for this mac address.

## vyos-1

```bash
Interface    IP Address      MAC                VRF        MTU  S/L    Description
-----------  --------------  -----------------  -------  -----  -----  -------------
eth0         -               16:c9:b4:a6:fc:33  default   1500  u/u    WAN
eth1         192.168.1.2/24  b6:12:18:97:94:4f  default   1500  u/u    LAN
lo           127.0.0.1/8     00:00:00:00:00:00  default  65536  u/u
```

The MAC address does not match the vyos-wan inspect outout. I set the MAN to match the vyos-wan network.

```bash
Interface    IP Address      MAC                VRF        MTU  S/L    Description
-----------  --------------  -----------------  -------  -----  -----  -------------
eth0         -               c2:f2:22:3b:e4:6b  default   1500  u/u    WAN
eth1         192.168.1.2/24  b6:12:18:97:94:4f  default   1500  u/u    LAN
lo           127.0.0.1/8     00:00:00:00:00:00  default  65536  u/u
             ::1/128
```

Monitor trafic on vyos-1 interface eth0 shows the DHCPDISCOVER broadcast packet, but no response.

Are there options on the Podnet network regarding broadcasts?

Monitoring on the Kea-server vyos-wan interface may need the server Dockerbuild modified to install tcpdump.