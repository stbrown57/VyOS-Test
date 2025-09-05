# VyOS Zone Based Firewall

VyOS has added a new [Zone based](https://docs.vyos.io/en/latest/configuration/firewall/zone.html) architecture to the system. I've attempted to configure the system , but it is not working as intended.

I've had problems with SSH attempts originating from the internet making there way to the sshd server on the firewall instance. So I will review the configuration of traffic to and from the WAN and LOCAL Zones.

## Zone WAN: 

``` config
show firewall zone WAN 
 default-action drop
 from LOCAL {
     firewall {
         name LOCAL-WAN
     }
 }
 member {
     interface eth0
 }
[edit]
```

## Zone LOCAL

```
show firewall zone LOCAL
 default-action drop
 from WAN {
     firewall {
         name WAN-LOCAL
     }
 }
 member {
     interface lo
 }
[edit]
```

## Zone Policy WAN-LOCAL

```config
show firewall ipv4 name WAN-LOCAL
 default-action drop
 rule 1 {
     action accept
     state established
     state related
 }
 rule 2 {
     action accept
     description "Allow DHCP responses"
     destination {
         port 68
     }
     protocol udp
     source {
         port 67
     }
 }
 rule 3 {
     action drop
     log
     state invalid
 }
[edit]
```

## Zone Policy LOCAL-WAN

```
show firewall ipv4 name LOCAL-WAN
 default-log
 rule 1 {
     action accept
     state established
     state related
     state new
 }
 rule 2 {
     action drop
     log
     state invalid
 }
[edit]
```

