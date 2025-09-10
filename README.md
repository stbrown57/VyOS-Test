# Notes

## Production

### September 10, 2015

The production system is running but the WAN DHCP renewal is working sometimes and failing others. This is the auto renewal which may be using unicast for the renewal. Each time I have access to the network and I run the "renew dhcp interface eth0", the IP is renew immediately. The renew command may be suing broadcast for the renewal. I read some discussion that this may be caused be a split route or an ARP table with multiple MAC addresses for the same IP address, this may happen with a mavvlan configuration.  The vyos-wan network has IPAM disabled, so an IP address is not assigned to the interface from an external source, how every the interface is assigned a MAC address as seen in the inspect output.

```bash
podman network inspect wan

```
```
            "containers": {
               "c3adb9194353c31599ecc673728cd248e2d474187361614bd266ebdeb14e84d1": {
                    "name": "vyos",
                    "interfaces": {
                         "eth0": {
                              "mac_address": "36:b0:fa:a0:99:eb"
                         }
                    }
               }
          }
```

This MAC address may be in the ARP table or logs from with in the VyOS container. Check the martian errors and see if the MAC address is in the log.

If all this pans out, try to specify the MAC address in the vyos-wan configuration to be the cloned MAC, that would match the MAC in the VyOS instance of eth0.

Nothing matches up. Try tcpdump capture:

```bash
vyos@bfnetgw:~$ sudo tcpdump -i eth0 -n -vvv udp port 67 or 68 -s 0 -w /opt/vyatta/etc/config/dhcp-eth0.cap
```


### September 2, 2025

Two VyOS Podman container instances are running on two fan-less devices, (Merckx and BMC). The WAN failover is not working, however the router/firewall will work for a while when the primary WAN port is connected directly to the ISP's ethernet connection. Unfortunately, the renewal fails on some subsequent attempt. So there are two current problems with the configuration.

* Lease renewal [problem](DHCP-WAN-Renewal.md)

* WAN interface failover
  This may have been a problem with a semi-smart switch and two different VLANs. I replaced it with a unmanaged switch, we will see if that works.

## Test Environment

Initial notes

I stared with the drawing to describe the environment. Custom containers where adde to provide functionally and diagnosing the initial setup.

The configurations of both the primary and secondary VyOS instance on the proposed production devices were exported and copied to the repository.

```bash
show configuration command > [filename.conf]
```

### September 7, 2025

The test system is running correctly with the Kea server serving only one address and the manual steps that needed to be applied. 

1. The kea server needs to be re-built with iptables and restoring the masquerading settings.
2. There was a lot of fiddling done to get the primary (vyos-1) to receive the one IP address being served form the kea server, and to be listed in the vrrp settings as the master.

### September 8, 2025

A test DMZ network was added to replicate the production system and more closely emulate the production system. In doing this I removed the instances and recreated the containers with the added network. The two interfaces exhibited some unexpected behavior.  The eth1 LAN networks on both instances were set as the "MASTER", and neither container could ping the other on the non-vif interface. As a result both containers were assigning the vif interface (192.168.1.1) to the LAN interface.  I suspect the interface names are somewhat arbitrary in there assignment and not necessarily assigned in the order in which they appear in the create command. If may be the order is done based on the arbitrary mac address assigned to the interface.

* Inspect Podamn Networks
  Note the mac addresses on the vyos-1 and vyos-2 interfaces listed in the inspection
* Show the interface (eth#)
  Verify the interface name matching the MAC address and match the name (eth#) to the Podman network

  The VyOS instances may be generating there own MAC address independant of the MAC in the inspect.

  Recreate the containers with networks one at a time to ensure the proper interface name.

  

